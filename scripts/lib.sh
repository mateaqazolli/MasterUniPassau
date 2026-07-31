#!/usr/bin/env bash
# Shared helpers for the reproduction scripts (scripts/*.sh). Everything here
# runs inside the app container, with the repository baked at /workspace and
# only /workspace/results shared with the host.

set -euo pipefail

REPO_ROOT="${REPO_ROOT:-/workspace}"
RESULTS_ROOT="$REPO_ROOT/results"

DB_HOST="${POSTGRES_HOST:-postgres}"
DB_PORT="${POSTGRES_PORT:-5432}"
DB_USER="${POSTGRES_USER:-postgres}"
export PGPASSWORD="${POSTGRES_PASSWORD:-postgres}"

# QUICK=1 runs only the headline configuration per experiment (smoke test)
QUICK="${QUICK:-0}"

log() { echo "[$(date '+%H:%M:%S')] $*"; }

psql_admin() {
    psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d postgres -v ON_ERROR_STOP=1 "$@"
}

psql_db() { # $1 = database, rest = psql args
    local db=$1
    shift
    psql -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$db" -v ON_ERROR_STOP=1 "$@"
}

ensure_database() { # $1 = database name
    if [ "$(psql_admin -t -A -c "SELECT 1 FROM pg_database WHERE datname='$1'")" != "1" ]; then
        psql_admin -c "CREATE DATABASE $1"
    fi
}

# Reads the value of the last "NAME=value" line a pipeline wrote to its log.
extract_result_var() { # $1 = variable name, $2 = log file
    { grep "^$1=" "$2" || true; } | tail -1 | cut -d= -f2-
}

import_csv_into_db() { # $1 = db, $2 = table, $3 = csv path relative to bnsl/datasets
    (cd "$REPO_ROOT/bnsl/datasets" &&
        DB_NAME="$1" TABLE_NAME="$2" CSV_FILE="$3" python3 csv_to_db.py)
}

# Builds the deduplicated "TRIALS:READS" list from the sweep variables of a
# sourced config file (the Table 6.2 grid). The N=10,000 grids contain the
# fixed-point pair in both sweeps, so duplicates are skipped. QUICK=1
# reduces the list to the headline configuration.
build_config_pairs() {
    CONFIG_PAIRS=()
    if [ "$QUICK" = "1" ]; then
        CONFIG_PAIRS=("${HEADLINE_TRIALS}:${HEADLINE_READS}")
        return
    fi
    local seen=" " pair r t
    for r in $READ_SWEEP; do
        pair="${READ_SWEEP_TRIALS}:${r}"
        if [[ "$seen" != *" $pair "* ]]; then
            CONFIG_PAIRS+=("$pair")
            seen+="$pair "
        fi
    done
    for t in $TRIAL_SWEEP; do
        pair="${t}:${TRIAL_SWEEP_READS}"
        if [[ "$seen" != *" $pair "* ]]; then
            CONFIG_PAIRS+=("$pair")
            seen+="$pair "
        fi
    done
}

# Full AnnealBN-CE experiment for one dataset configuration:
#   import data -> SA/SQA over the Table 6.2 grid (solve, estimate, q-error)
#   -> Chow-Liu + PostgreSQL baseline -> merged headline bar chart.
# All final artefacts are copied to results/<EXPERIMENT>/ under stable names.
run_ce_experiment() { # $1 = config file relative to repo root
    # shellcheck source=/dev/null
    source "$REPO_ROOT/$1"

    local exp_dir="$RESULTS_ROOT/$EXPERIMENT"
    local log_dir="$exp_dir/logs"
    mkdir -p "$exp_dir/estimates" "$exp_dir/qerrors" "$log_dir"

    local csv_rel="data/${CSV_NAME}.csv"
    local csv_from_qa="../bnsl/datasets/data/${CSV_NAME}.csv"

    if [ ! -f "$REPO_ROOT/bnsl/datasets/$csv_rel" ] || [ ! -f "$REPO_ROOT/bnsl-qa/$SOLVER_TXT" ]; then
        echo "Error: dataset files for $EXPERIMENT missing — run scripts/prepare_datasets.sh first."
        exit 1
    fi

    log "[$EXPERIMENT] importing ${CSV_NAME}.csv into $DB_NAME.$TABLE_NAME"
    ensure_database "$DB_NAME"
    import_csv_into_db "$DB_NAME" "$TABLE_NAME" "$csv_rel"

    build_config_pairs
    log "[$EXPERIMENT] ${#CONFIG_PAIRS[@]} configurations x SA/SQA (QUICK=$QUICK)"

    local headline_sa="" headline_sqa=""
    local solver pair trials reads tag dlog qlog solver_dir final_csv qerr_file

    for solver in SA SQA; do
        for pair in "${CONFIG_PAIRS[@]}"; do
            trials="${pair%%:*}"
            reads="${pair##*:}"
            tag="${solver}_T${trials}_R${reads}"
            dlog="$log_dir/dispatch_${tag}.log"

            log "[$EXPERIMENT] $tag: solver + cardinality estimation"
            (cd "$REPO_ROOT/bnsl-qa" &&
                DATASET_TXT="$SOLVER_TXT" SOLVER="$solver" TRIALS="$trials" READS="$reads" \
                CE_SCRIPT="$CE_SCRIPT_QA" CE_DATASET_CSV="$csv_from_qa" \
                bash dispatch.sh) 2>&1 | tee "$dlog"

            solver_dir=$(extract_result_var DISPATCH_SOLVER_DIR "$dlog")
            final_csv=$(extract_result_var DISPATCH_FINAL_CSV "$dlog")
            if [ -z "$final_csv" ] || [ ! -f "$REPO_ROOT/bnsl-qa/$final_csv" ]; then
                echo "Error: dispatch produced no final CSV for $tag (see $dlog)"
                exit 1
            fi
            cp "$REPO_ROOT/bnsl-qa/$final_csv" "$exp_dir/estimates/estimates_${tag}.csv"

            qlog="$log_dir/qerror_${tag}.log"
            log "[$EXPERIMENT] $tag: q-error calculation"
            (cd "$REPO_ROOT/bnsl-qa" &&
                CARD_SCRIPT="$CE_SCRIPT_QA" DATASET_CSV="$csv_from_qa" \
                MATRIX_DIR="$solver_dir" QERROR_DB="$DB_NAME" \
                CE_DATASET_CSV="$csv_from_qa" \
                bash qerror_calculation.sh) 2>&1 | tee "$qlog"

            qerr_file=$(extract_result_var QERROR_RESULT_FILE "$qlog")
            if [ -z "$qerr_file" ] || [ ! -f "$REPO_ROOT/bnsl-qa/$qerr_file" ]; then
                echo "Error: q-error calculation produced no result for $tag (see $qlog)"
                exit 1
            fi
            cp "$REPO_ROOT/bnsl-qa/$qerr_file" "$exp_dir/qerrors/qerrors_${tag}.csv"

            if [ "$trials" = "$HEADLINE_TRIALS" ] && [ "$reads" = "$HEADLINE_READS" ]; then
                if [ "$solver" = "SA" ]; then
                    headline_sa="$final_csv"
                else
                    headline_sqa="$final_csv"
                fi
            fi
        done
    done

    # Chow-Liu baseline + PostgreSQL planner estimates
    local blog="$log_dir/chowliu.log" bench_final
    log "[$EXPERIMENT] Chow-Liu + PostgreSQL baseline"
    (cd "$REPO_ROOT/bnsl" &&
        CSV_FILE="$CSV_NAME" BENCH_DB="$DB_NAME" BENCH_SCRIPT="$CE_SCRIPT_CL" \
        bash cardinality_benchmarks.sh) 2>&1 | tee "$blog"

    bench_final=$(extract_result_var BENCH_FINAL_CSV "$blog")
    if [ -z "$bench_final" ] || [ ! -f "$REPO_ROOT/bnsl/$bench_final" ]; then
        echo "Error: baseline benchmark produced no final CSV (see $blog)"
        exit 1
    fi
    cp "$REPO_ROOT/bnsl/$bench_final" "$exp_dir/chowliu_pg_final.csv"

    # Merged grouped bar chart for the headline configuration
    if [ -n "$headline_sa" ] && [ -n "$headline_sqa" ]; then
        log "[$EXPERIMENT] merging headline comparison figure"
        (cd "$REPO_ROOT/bnsl" &&
            SA_FILE="../bnsl-qa/$headline_sa" SQA_FILE="../bnsl-qa/$headline_sqa" \
            BN_FILE="$bench_final" MERGE_OUTPUT_DIR="$exp_dir" \
            bash merge_results.sh) 2>&1 | tee "$log_dir/merge.log"

        # Stable file names so the README can reference exact paths
        local newest_csv newest_png
        newest_csv=$(ls -t "$exp_dir"/combined_results_*.csv 2>/dev/null | head -1 || true)
        newest_png=$(ls -t "$exp_dir"/combined_results_*.png 2>/dev/null | head -1 || true)
        [ -n "$newest_csv" ] && cp "$newest_csv" "$exp_dir/combined_results.csv"
        [ -n "$newest_png" ] && cp "$newest_png" "$exp_dir/combined_results.png"
    fi

    log "[$EXPERIMENT] complete — outputs in results/$EXPERIMENT/"
}

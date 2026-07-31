#!/usr/bin/env bash
# One-button reproduction of every experiment reported in the thesis.
#
#   ./reproduce_all.sh              full Table 6.2 grid (all thesis tables)
#   QUICK=1 ./reproduce_all.sh      headline configuration only (smoke test)
#   FRESH=0 ./reproduce_all.sh      keep the existing PostgreSQL volume
#
# Builds the self-contained Docker images, prepares all datasets, runs
# experiments E1-E6 with the thesis configurations, and writes every table
# and figure to ./results/, including results/index.html, which compares the
# reproduced values against the frozen thesis values in original_results/.

set -euo pipefail
cd "$(dirname "$0")"

QUICK="${QUICK:-0}"
FRESH="${FRESH:-1}"

# results/ must exist before compose starts, otherwise the bind mount is
# created by the Docker daemon (as root on Linux)
mkdir -p results

if [ "$FRESH" = "1" ]; then
    echo "=== Removing previous containers and database volume ==="
    docker compose down -v --remove-orphans
fi

echo "=== Building self-contained images and starting services ==="
docker compose up -d --build

run_step() {
    echo ""
    echo "=== $1 ==="
    docker compose exec -T -e QUICK="$QUICK" app bash "$2"
}

run_step "E0: dataset preparation"                 scripts/prepare_datasets.sh
run_step "E1: WetGrass N=100"                      scripts/run_wetgrass_100.sh
run_step "E2: WetGrass N=10,000"                   scripts/run_wetgrass_10000.sh
run_step "E3: NHANES"                              scripts/run_nhanes.sh
run_step "E4: Market Basket N=100"                 scripts/run_market_basket_100.sh
run_step "E5: Market Basket N=10,000"              scripts/run_market_basket_10000.sh
run_step "E6: random-structure robustness check"   scripts/run_random_control.sh
run_step "E7: summary tables and comparison report" scripts/make_report.sh

echo ""
echo "Done. All outputs are in ./results/."
echo "Open ./results/index.html for the side-by-side comparison with the thesis."

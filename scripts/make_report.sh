#!/usr/bin/env bash
# E7: build the reproduced summary tables from the raw run outputs and
# render results/index.html comparing them against the frozen thesis values.
source "$(dirname "$0")/lib.sh"

python3 "$REPO_ROOT/scripts/summarize_results.py"
python3 "$REPO_ROOT/scripts/make_report.py"

log "Report ready — open results/index.html in a browser."

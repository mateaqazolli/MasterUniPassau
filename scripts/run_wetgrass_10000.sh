#!/usr/bin/env bash
# E2: WetGrass N=10,000 — reproduces thesis Tables 6.5-6.6.
source "$(dirname "$0")/lib.sh"
run_ce_experiment config/wetgrass_10000.env

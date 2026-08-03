#!/usr/bin/env bash
# E1: WetGrass N=100 — reproduces thesis Tables 6.3-6.4.
source "$(dirname "$0")/lib.sh"
run_ce_experiment config/wetgrass_100.env

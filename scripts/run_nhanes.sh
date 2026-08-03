#!/usr/bin/env bash
# E3: NHANES — reproduces thesis Tables 6.8-6.9 (attributes in Table 6.7).
source "$(dirname "$0")/lib.sh"
run_ce_experiment config/nhanes.env

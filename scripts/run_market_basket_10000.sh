#!/usr/bin/env bash
# E5: Market Basket N=10,000 — reproduces thesis Tables 6.15-6.18.
source "$(dirname "$0")/lib.sh"
run_ce_experiment config/market_basket_10000.env

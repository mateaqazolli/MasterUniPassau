#!/usr/bin/env bash
# E4: Market Basket N=100 — reproduces thesis Tables 6.10-6.13, Figure 6.1.
source "$(dirname "$0")/lib.sh"
run_ce_experiment config/market_basket_100.env

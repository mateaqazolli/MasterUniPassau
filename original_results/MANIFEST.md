# Original Thesis Results — Frozen Reference Snapshot

This directory contains the exact experimental result values reported in the master thesis
*"Querying with Qubits: A Quantum Annealing Approach to the Cardinality Estimation for Query
Optimisation"* (Matea Qazolli, University of Passau, 2026), transcribed from
`docs/Master Thesis.pdf`. These values are the frozen reference for the reproduction package:
reruns of the experiments should be compared against these numbers. Note that simulated
annealing (SA) and simulated quantum annealing (SQA) are stochastic solvers, so re-runs
produce similar-but-not-identical values; the thesis itself reports "stable" cardinality
vectors/patterns that persist across read-trial configurations, and those are the values
recorded here.

Transcription conventions: column headers are snake_case versions of the printed table
headers; thousands separators were removed from numeric values (e.g. printed "8,055.72" is
written as 8055.72); decimal precision is preserved exactly as printed; the set-membership
symbol in Table 6.2 is written as "in" (e.g. "R in {10, 50, 100, 250, 500}"); cells that
contain ranges or set notation are kept as strings. In the read/trial-variation tables, R =
reads (samples per solver run) and T = trials (independent solver runs).

Appendix Tables B.4–B.19 (detailed per-configuration/per-query distinct cardinality
estimates for the additional read–trial robustness configurations) were **not** transcribed;
they are available in the PDF (printed pages 89–101).

| File | Thesis reference | Caption (abbreviated) | Experiment |
|------|-----------------|-----------------------|------------|
| table_6_1_dataset_overview.csv | Table 6.1, p. 48 | Overview of the datasets used in the experimental evaluation | All |
| table_6_2_run_configurations.csv | Table 6.2, p. 50 | Annealing run configurations used in the experiments | All |
| wetgrass_100/table_6_03_cardinality_estimates.csv | Table 6.3, p. 55 | Cardinality estimates for the WetGrass workload, N = 100 (stable SA/SQA vector, Chow–Liu baseline, PostgreSQL) | WetGrass N=100 |
| wetgrass_100/table_6_04_qerror_summary.csv | Table 6.4, p. 56 | Q-error summary for the WetGrass workload, N = 100 | WetGrass N=100 |
| wetgrass_10000/table_6_05_cardinality_estimates.csv | Table 6.5, p. 59 | Cardinality estimates for the WetGrass workload, N = 10,000 | WetGrass N=10,000 |
| wetgrass_10000/table_6_06_qerror_summary.csv | Table 6.6, p. 59 | Q-error summary for the WetGrass workload, N = 10,000 | WetGrass N=10,000 |
| nhanes/table_6_07_attributes_encodings.csv | Table 6.7, p. 61 | Prepared NHANES attributes and solver encodings | NHANES |
| nhanes/table_6_08_cardinality_estimates.csv | Table 6.8, p. 62 | True cardinalities and estimator outputs for the NHANES workload | NHANES |
| nhanes/table_6_09_qerror_summary.csv | Table 6.9, p. 63 | Q-error summary for the NHANES workload | NHANES |
| market_basket_100/table_6_10_cardinality_estimates.csv | Table 6.10, p. 66 | Cardinality estimates for the Market Basket workload, N = 100 (stable SA/SQA pattern) | Market Basket N=100 |
| market_basket_100/table_6_11_qerror_summary.csv | Table 6.11, p. 66 | Q-error summary for the Market Basket workload, N = 100 | Market Basket N=100 |
| market_basket_100/table_6_12_read_variation_summary.csv | Table 6.12, p. 68 | Read-variation results, N = 100, fixed T = 30 | Market Basket N=100 |
| market_basket_100/table_6_13_trial_variation_summary.csv | Table 6.13, p. 69 | Trial-variation results, N = 100, fixed R = 100 | Market Basket N=100 |
| market_basket_100/table_6_14_random_structure_check.csv | Table 6.14, p. 70 | Random-structure robustness check, N = 100 (selected stable SA/SQA configurations vs. 960 unique random structures) | Market Basket N=100 |
| market_basket_100/figure_6_1_page.png | Figure 6.1, p. 67 | Sorted q-error profiles for the Market Basket workload, N = 100 (SA/SQA from the stable pattern in Eq. (6.9); classical baseline and PostgreSQL for comparison) — full page render at 200 dpi | Market Basket N=100 |
| market_basket_10000/table_6_15_cardinality_estimates.csv | Table 6.15, p. 73 | Cardinality estimates for the Market Basket workload, N = 10,000 (stable SA/SQA pattern) | Market Basket N=10,000 |
| market_basket_10000/table_6_16_qerror_summary.csv | Table 6.16, p. 73 | Q-error summary for the Market Basket workload, N = 10,000 | Market Basket N=10,000 |
| market_basket_10000/table_6_17_read_variation_summary.csv | Table 6.17, p. 74 | Read-variation results, N = 10,000, fixed T = 20 | Market Basket N=10,000 |
| market_basket_10000/table_6_18_trial_variation_summary.csv | Table 6.18, p. 75 | Trial-variation results, N = 10,000, fixed R = 1000 | Market Basket N=10,000 |
| workloads/table_b_1_wetgrass_workload.csv | Table B.1, p. 88 | WetGrass query workload (SQL-style selection predicates Q1–Q6) | WetGrass |
| workloads/table_b_2_nhanes_workload.csv | Table B.2, p. 88 | NHANES query workload (SQL-style selection predicates Q1–Q6) | NHANES |
| workloads/table_b_3_market_basket_workload.csv | Table B.3, p. 89 | Market Basket query workload (SQL-style selection predicates Q1–Q6) | Market Basket |

Page numbers are the printed page numbers; in the PDF file the corresponding page index is
printed page + 10.

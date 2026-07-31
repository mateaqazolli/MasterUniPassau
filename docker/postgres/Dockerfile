FROM postgres:16

# Initialisation SQL and the NHANES CSV are baked into the image so the
# database bootstrap does not depend on host bind mounts. The init scripts
# only run on a fresh data volume; scripts/prepare_datasets.sh re-imports
# unconditionally for reused volumes.
COPY docker/postgres/init/ /docker-entrypoint-initdb.d/
COPY bnsl/datasets/data/NHANES_age_prediction.csv /datasets/NHANES_age_prediction.csv

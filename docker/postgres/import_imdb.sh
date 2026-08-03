#!/usr/bin/env bash
set -euo pipefail

# Optional IMDB import — movie_link only.
#
# The AnnealBN-CE Movie Link workload uses exactly one IMDB table
# (movie_link), so this script extracts and imports only that table. The
# full JOB schema remains available for reference at
# docker/postgres/imdb/schema.sql.
#
# Run inside the app container:
#
#   docker compose exec app bash docker/postgres/import_imdb.sh
#
# The original dataset file (imdb.tgz, ~1.2 GB) is downloaded AT MOST ONCE:
# /workspace/imdb_data is a host mount (./imdb_data), so the archive
# survives docker compose down / rebuilds, and every run checks for it
# before downloading. An interrupted download is kept as imdb.tgz.part —
# it can never be mistaken for the complete archive — and is resumed on
# the next run. Only the (fast) database import repeats after a wipe such
# as reproduce_all.sh's `docker compose down -v`.

IMDB_URL="https://bonsai.cedardb.com/job/imdb.tgz"

APP_IMDB_DIR="/workspace/imdb_data"
APP_ARCHIVE="$APP_IMDB_DIR/imdb.tgz"
APP_EXTRACT_DIR="$APP_IMDB_DIR/extracted"
APP_CSV="$APP_EXTRACT_DIR/movie_link.csv"

# PostgreSQL reads the CSV server-side through its own ./imdb_data mount
DB_CSV="/imdb_data/extracted/movie_link.csv"

DB_HOST="${POSTGRES_HOST:-postgres}"
DB_PORT="${POSTGRES_PORT:-5432}"
DB_USER="${POSTGRES_USER:-postgres}"
DB_PASSWORD="${POSTGRES_PASSWORD:-postgres}"
DB_NAME="imdb"

export PGPASSWORD="$DB_PASSWORD"

psql_db() { # $1 = database, rest = psql args
    local db=$1
    shift
    psql -v ON_ERROR_STOP=1 -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$db" "$@"
}

echo "==========================================="
echo "   Optional IMDB Import (movie_link only)  "
echo "==========================================="
echo "Target database: $DB_NAME"
echo "Download URL:    $IMDB_URL"
echo "Local data dir:  $APP_IMDB_DIR (host: ./imdb_data)"
echo ""

mkdir -p "$APP_IMDB_DIR" "$APP_EXTRACT_DIR"

# --- 1. Download the original dataset file at most once ---
if [ -f "$APP_ARCHIVE" ]; then
    echo "--- Archive already exists, skipping download ---"
    echo "$APP_ARCHIVE"
else
    echo "--- Downloading IMDB archive (~1.2 GB, one-time) ---"
    wget "$IMDB_URL" --no-check-certificate -c -O "$APP_ARCHIVE.part"
    mv "$APP_ARCHIVE.part" "$APP_ARCHIVE"
fi

# --- 2. Extract only movie_link.csv ---
if [ -f "$APP_CSV" ]; then
    echo "--- movie_link.csv already extracted, skipping extraction ---"
else
    echo "--- Extracting movie_link.csv from the archive ---"
    tar -xzf "$APP_ARCHIVE" -C "$APP_EXTRACT_DIR" movie_link.csv 2>/dev/null \
        || tar -xzf "$APP_ARCHIVE" -C "$APP_EXTRACT_DIR" ./movie_link.csv
    if [ ! -f "$APP_CSV" ]; then
        echo "Error: extraction did not produce $APP_CSV"
        exit 1
    fi
fi

# --- 3. Import into PostgreSQL ---
echo "--- Checking PostgreSQL connection ---"
psql_db postgres -c "SELECT 1;" > /dev/null

if [ "$(psql_db postgres -t -A -c "SELECT 1 FROM pg_database WHERE datname='$DB_NAME'")" != "1" ]; then
    psql_db postgres -c "CREATE DATABASE $DB_NAME;"
fi

# Table definition matches docker/postgres/imdb/schema.sql (constraints on
# other, unimported tables are irrelevant here)
echo "--- (Re)creating table movie_link ---"
psql_db "$DB_NAME" -c "DROP TABLE IF EXISTS movie_link;
CREATE TABLE movie_link (
    id integer NOT NULL,
    movie_id integer NOT NULL,
    linked_movie_id integer NOT NULL,
    link_type_id integer NOT NULL,
    CONSTRAINT movie_link_pkey PRIMARY KEY (id)
);"

# Header detection: import with HEADER true only if the CSV has one
first_line=$(head -n 1 "$APP_CSV")
if [[ "$first_line" == id,* ]]; then
    CSV_HEADER=true
else
    CSV_HEADER=false
fi

echo "--- Importing table: movie_link ---"
psql_db "$DB_NAME" -c "COPY movie_link FROM '$DB_CSV' WITH (FORMAT csv, HEADER $CSV_HEADER, NULL '', QUOTE '\"', ESCAPE E'\\\\');"

echo "--- Running ANALYZE ---"
psql_db "$DB_NAME" -c "ANALYZE movie_link;"

echo "--- Import complete ---"
psql_db "$DB_NAME" -c "SELECT COUNT(*) AS movie_link_rows FROM movie_link;"

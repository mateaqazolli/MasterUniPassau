import os

import psycopg2
import pandas as pd

# ---------- CONFIG (overridable via environment for scripted runs) ----------
DB_NAME = os.environ.get("DB_NAME", "wetgrass")
DB_USER = os.environ.get("POSTGRES_USER", "postgres")
DB_PASSWORD = os.environ.get("POSTGRES_PASSWORD", "postgres")

DB_HOST = os.environ.get("POSTGRES_HOST", "postgres")
DB_PORT = os.environ.get("POSTGRES_PORT", "5432")

CSV_FILE = os.environ.get("CSV_FILE", "data/WetGrass_variance_zero.csv")
TABLE_NAME = os.environ.get("TABLE_NAME", "wetgrass_data")
# ----------------------------

conn = psycopg2.connect(
    dbname=DB_NAME,
    user=DB_USER,
    password=DB_PASSWORD,
    host=DB_HOST,
    port=DB_PORT
)

cur = conn.cursor()

# Read CSV
df = pd.read_csv(CSV_FILE)

# The table is emptied first so repeated imports stay idempotent, and the
# insert columns are taken from the CSV header (lowercased to match the
# PostgreSQL schemas), so the same script works for every dataset.
cur.execute(f"TRUNCATE TABLE {TABLE_NAME}")

columns = [c.lower() for c in df.columns]
placeholders = ", ".join(["%s"] * len(columns))
insert_query = f"INSERT INTO {TABLE_NAME} ({', '.join(columns)}) VALUES ({placeholders})"

# Insert rows (numpy scalars converted to native Python types for psycopg2)
for _, row in df.iterrows():
    cur.execute(insert_query, tuple(
        v.item() if hasattr(v, "item") else v for v in row
    ))

conn.commit()

cur.execute(f"ANALYZE {TABLE_NAME}")
conn.commit()

cur.close()
conn.close()

print(f"Imported {len(df)} rows from {CSV_FILE} into {DB_NAME}.{TABLE_NAME}")

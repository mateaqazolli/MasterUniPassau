import os

import psycopg2
import pandas as pd

DB_NAME = os.environ.get("DB_NAME", "nhanes")
DB_USER = os.environ.get("POSTGRES_USER", "postgres")
DB_PASSWORD = os.environ.get("POSTGRES_PASSWORD", "postgres")

DB_HOST = os.environ.get("POSTGRES_HOST", "postgres")
DB_PORT = os.environ.get("POSTGRES_PORT", "5432")

CSV_FILE = os.environ.get("CSV_FILE", "data/NHANES_age_prediction.csv")
TABLE_NAME = os.environ.get("TABLE_NAME", "nhanes_data")
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

# Empty the table first so repeated imports stay idempotent
cur.execute(f"TRUNCATE TABLE {TABLE_NAME}")

# Insert query
insert_query = f"""
INSERT INTO {TABLE_NAME} (
    seqn, age_group, ridageyr, riagendr, paq605,
    bmxbmi, lbxglu, diq010, lbxglt, lbxin
)
VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
"""

# Insert rows
for _, row in df.iterrows():
    cur.execute(insert_query, tuple(row))

# Commit and close
conn.commit()
cur.close()
conn.close()

print("CSV data inserted successfully!")

"""
Builds economic_indicators.db from the CSV files in data/.
Source data: FRED (Federal Reserve Economic Data), via govspending.org public export.
"""
import sqlite3
import csv
import os

DB_PATH = "economic_indicators.db"

def main():
    if os.path.exists(DB_PATH):
        os.remove(DB_PATH)

    conn = sqlite3.connect(DB_PATH)
    cur = conn.cursor()

    cur.execute("""
        CREATE TABLE unemployment (
            obs_date TEXT PRIMARY KEY,
            unemployment_rate REAL
        )
    """)
    cur.execute("""
        CREATE TABLE cpi (
            obs_date TEXT PRIMARY KEY,
            cpi_index REAL
        )
    """)
    cur.execute("""
        CREATE TABLE fed_funds_rate (
            obs_date TEXT PRIMARY KEY,
            fed_funds_rate REAL
        )
    """)

    with open("data/unrate.csv") as f:
        reader = csv.DictReader(f)
        rows = [(r["date"], float(r["unrate"])) for r in reader]
        cur.executemany("INSERT INTO unemployment VALUES (?, ?)", rows)

    with open("data/cpi.csv") as f:
        reader = csv.DictReader(f)
        rows = [(r["date"], float(r["cpi"])) for r in reader]
        cur.executemany("INSERT INTO cpi VALUES (?, ?)", rows)

    with open("data/fedfunds.csv") as f:
        reader = csv.DictReader(f)
        rows = [(r["date"], float(r["fedfunds"])) for r in reader]
        cur.executemany("INSERT INTO fed_funds_rate VALUES (?, ?)", rows)

    conn.commit()

    for table in ["unemployment", "cpi", "fed_funds_rate"]:
        cur.execute(f"SELECT COUNT(*) FROM {table}")
        print(f"{table}: {cur.fetchone()[0]} rows loaded")

    conn.close()
    print(f"\n{DB_PATH} built successfully.")

if __name__ == "__main__":
    main()

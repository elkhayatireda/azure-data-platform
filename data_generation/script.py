"""
script_faker_data.py

Generates mock HR data for the three pipeline sources:
  1. employees           -> loaded into PostgreSQL (Docker container)
  2. performance_reviews -> written to an Excel file
  3. attendance          -> written to a CSV file

Intentionally injects realistic data quality issues (inconsistent types,
formats, missing values, duplicates) so the bronze -> silver cleaning
step in Databricks has real work to do. Use --messy-rate 0 for a clean
baseline run.

Usage:
    pip install faker psycopg2-binary pandas openpyxl sqlalchemy python-dotenv
    cp .env.example .env    # first time only, adjust values if needed
    python script_faker_data.py --num-employees 20
    python script_faker_data.py --num-employees 20 --messy-rate 0    # clean data
"""

import argparse
import os
import random
from datetime import date

import pandas as pd
from dotenv import load_dotenv
from faker import Faker
from sqlalchemy import create_engine

load_dotenv()  # reads .env in the current directory, if present

fake = Faker()

DEPARTMENTS = {
    "HR": ["HR Specialist", "HR Manager", "Recruiter"],
    "IT": ["Data Engineer", "Software Developer", "IT Support", "DevOps Engineer"],
    "Finance": ["Accountant", "Financial Analyst", "Auditor"],
    "Sales": ["Sales Representative", "Account Manager", "Sales Manager"],
}

MONTHS = ["January", "February", "March", "April", "May", "June"]
MONTH_VARIANTS = {
    "January": ["January", "Jan", "01"],
    "February": ["February", "Feb", "02"],
    "March": ["March", "Mar", "03"],
    "April": ["April", "Apr", "04"],
    "May": ["May", "May", "05"],
    "June": ["June", "Jun", "06"],
}

# --- Postgres connection, read from .env (see .env.example) ---
DB_USER = os.getenv("POSTGRES_USER")
DB_PASSWORD = os.getenv("POSTGRES_PASSWORD")
DB_HOST = os.getenv("POSTGRES_HOST", "localhost")
DB_PORT = os.getenv("POSTGRES_PORT", "5432")
DB_NAME = os.getenv("POSTGRES_DB")

REQUIRED_VARS = ["POSTGRES_USER", "POSTGRES_PASSWORD", "POSTGRES_DB"]


# ---------------------------------------------------------------------------
# Generators (clean data first, messiness injected afterwards)
# ---------------------------------------------------------------------------

def generate_employees(n: int) -> pd.DataFrame:
    rows = []
    for i in range(1, n + 1):
        dept = random.choice(list(DEPARTMENTS.keys()))
        rows.append(
            {
                "EmployeeID": 1000 + i,
                "Name": fake.name(),
                "Department": dept,
                "Position": random.choice(DEPARTMENTS[dept]),
                "HireDate": fake.date_between(start_date="-6y", end_date="-30d"),
                "Salary": round(random.uniform(8000, 25000), 2),
            }
        )
    return pd.DataFrame(rows)


def generate_performance_reviews(employee_ids: list) -> pd.DataFrame:
    comments = ["Excellent", "Good", "Satisfactory", "Needs Improvement", "Outstanding"]
    rows = []
    for emp_id in employee_ids:
        rows.append(
            {
                "EmployeeID": emp_id,
                "ReviewDate": date(2026, 3, 31),
                "PerformanceScore": round(random.uniform(1.0, 5.0), 1),
                "ManagerComment": random.choice(comments),
            }
        )
    return pd.DataFrame(rows)


def generate_attendance(employee_ids: list) -> pd.DataFrame:
    rows = []
    for emp_id in employee_ids:
        for month in MONTHS:
            present = random.randint(15, 22)
            rows.append(
                {
                    "EmployeeID": emp_id,
                    "Month": month,
                    "DaysPresent": present,
                    "DaysAbsent": random.randint(0, 22 - present) if present < 22 else 0,
                    "LateArrivals": random.randint(0, 5),
                }
            )
    return pd.DataFrame(rows)


# ---------------------------------------------------------------------------
# Messiness injection - each function mutates a fraction of rows, controlled
# by `rate` (0.0 = clean, 1.0 = every row affected)
# ---------------------------------------------------------------------------

def _sample_indices(df: pd.DataFrame, rate: float) -> list:
    k = int(len(df) * rate)
    return random.sample(list(df.index), k) if k > 0 else []


def mess_up_employees(df: pd.DataFrame, rate: float) -> pd.DataFrame:
    df = df.copy()
    df["Salary"] = df["Salary"].astype(object)

    # Salary as inconsistent text formats
    for idx in _sample_indices(df, rate):
        val = df.at[idx, "Salary"]
        style = random.choice(["currency", "comma", "plain_float", "int_str"])
        if style == "currency":
            df.at[idx, "Salary"] = f"${val:,.0f}"
        elif style == "comma":
            df.at[idx, "Salary"] = f"{val:,.2f}"
        elif style == "plain_float":
            df.at[idx, "Salary"] = str(val)
        elif style == "int_str":
            df.at[idx, "Salary"] = str(int(val))

    # HireDate as inconsistent formats (string, not date, once touched)
    df["HireDate"] = df["HireDate"].astype(object)
    for idx in _sample_indices(df, rate):
        d = df.at[idx, "HireDate"]
        style = random.choice(["slash_us", "dash_eu"])
        if style == "slash_us":
            df.at[idx, "HireDate"] = d.strftime("%m/%d/%Y")
        elif style == "dash_eu":
            df.at[idx, "HireDate"] = d.strftime("%d-%m-%Y")

    # Department casing / whitespace inconsistency
    for idx in _sample_indices(df, rate):
        dept = df.at[idx, "Department"]
        style = random.choice(["lower", "upper", "padded"])
        if style == "lower":
            df.at[idx, "Department"] = dept.lower()
        elif style == "upper":
            df.at[idx, "Department"] = dept.upper()
        elif style == "padded":
            df.at[idx, "Department"] = f"  {dept}  "

    # A few missing departments
    for idx in _sample_indices(df, rate / 2):
        df.at[idx, "Department"] = None

    # Duplicate a few employees (simulates repeated sync from source)
    n_dupes = max(0, int(len(df) * rate / 3))
    if n_dupes > 0:
        dupes = df.sample(n_dupes)
        df = pd.concat([df, dupes], ignore_index=True)

    return df


def mess_up_performance(df: pd.DataFrame, rate: float) -> pd.DataFrame:
    df = df.copy()
    df["PerformanceScore"] = df["PerformanceScore"].astype(object)
    df["ReviewDate"] = df["ReviewDate"].astype(object)
    df["ManagerComment"] = df["ManagerComment"].astype(object)

    for idx in _sample_indices(df, rate):
        df.at[idx, "PerformanceScore"] = random.choice(["N/A", "high", "pending", ""])

    for idx in _sample_indices(df, rate / 2):
        df.at[idx, "ReviewDate"] = None

    for idx in _sample_indices(df, rate):
        comment = df.at[idx, "ManagerComment"]
        style = random.choice(["blank", "lower", "extra_space"])
        if style == "blank":
            df.at[idx, "ManagerComment"] = None
        elif style == "lower":
            df.at[idx, "ManagerComment"] = comment.lower()
        elif style == "extra_space":
            df.at[idx, "ManagerComment"] = f"  {comment}  "

    return df


def mess_up_attendance(df: pd.DataFrame, rate: float) -> pd.DataFrame:
    df = df.copy()
    df["EmployeeID"] = df["EmployeeID"].astype(object)
    df["Month"] = df["Month"].astype(object)
    df["DaysAbsent"] = df["DaysAbsent"].astype(object)
    df["LateArrivals"] = df["LateArrivals"].astype(object)

    # EmployeeID sometimes formatted as "EMP1001" instead of 1001
    for idx in _sample_indices(df, rate):
        df.at[idx, "EmployeeID"] = f"EMP{df.at[idx, 'EmployeeID']}"

    # Month name variants
    for idx in _sample_indices(df, rate):
        month = df.at[idx, "Month"]
        df.at[idx, "Month"] = random.choice(MONTH_VARIANTS[month])

    # Impossible / missing values
    for idx in _sample_indices(df, rate / 2):
        df.at[idx, "DaysAbsent"] = -1

    for idx in _sample_indices(df, rate / 2):
        df.at[idx, "LateArrivals"] = None

    return df


def load_employees_to_postgres(df: pd.DataFrame):
    missing = [v for v in REQUIRED_VARS if not os.getenv(v)]
    if missing:
        raise EnvironmentError(
            f"Missing required environment variables: {', '.join(missing)}. "
            "Copy .env.example to .env and fill in your values."
        )
    engine = create_engine(
        f"postgresql+psycopg2://{DB_USER}:{DB_PASSWORD}@{DB_HOST}:{DB_PORT}/{DB_NAME}"
    )
    df.to_sql("employees", engine, if_exists="replace", index=False)
    print(f"Loaded {len(df)} rows into PostgreSQL table 'employees'.")


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--num-employees", type=int, default=20)
    parser.add_argument(
        "--messy-rate",
        type=float,
        default=0.25,
        help="Fraction (0.0-1.0) of rows affected by data quality issues. 0 = clean data.",
    )
    parser.add_argument("--skip-postgres", action="store_true", help="Skip DB load, just write files")
    args = parser.parse_args()

    employees_df = generate_employees(args.num_employees)
    employee_ids = employees_df["EmployeeID"].tolist()

    performance_df = generate_performance_reviews(employee_ids)
    attendance_df = generate_attendance(employee_ids)

    if args.messy_rate > 0:
        employees_df = mess_up_employees(employees_df, args.messy_rate)
        performance_df = mess_up_performance(performance_df, args.messy_rate)
        attendance_df = mess_up_attendance(attendance_df, args.messy_rate)
        print(f"Injected data quality issues at rate={args.messy_rate}")

    # Excel output (performance reviews)
    performance_df.to_excel("output/performance_reviews.xlsx", index=False)
    print(f"Wrote {len(performance_df)} rows to output/performance_reviews.xlsx")

    # CSV output (attendance)
    attendance_df.to_csv("output/attendance.csv", index=False)
    print(f"Wrote {len(attendance_df)} rows to output/attendance.csv")

    # Also keep a CSV copy of employees for reference / manual import if needed
    employees_df.to_csv("output/employees_reference.csv", index=False)

    if not args.skip_postgres:
        load_employees_to_postgres(employees_df)
    else:
        print("Skipped PostgreSQL load (--skip-postgres set). Employees data is in output/employees_reference.csv")


if __name__ == "__main__":
    main()
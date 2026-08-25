# Mock Data Generation

## 1. Start PostgreSQL

```bash
docker-compose up -d
```

This starts a Postgres container with:
- host: `localhost`
- port: `5432`
- database: `hr_analytics`
- user: `hr_admin`
- password: `hr_password123`

These are the exact values you'll enter in the ADF PostgreSQL linked service (via your Self-hosted Integration Runtime).

## 2. Install Python dependencies

```bash
pip install faker psycopg2-binary pandas openpyxl sqlalchemy
```

## 3. Generate the mock data

```bash
python script_faker_data.py --num-employees 20
```

This will:
- Insert `employees` rows directly into the Postgres container
- Write `output/performance_reviews.xlsx`
- Write `output/attendance.csv`

## 4. Scaling up for the performance benchmark

Later, rerun with a larger number to test pipeline performance:

```bash
python script_faker_data.py --num-employees 100000
```

## 5. Stopping / resetting

```bash
docker-compose down        # stop the container, keep data
docker-compose down -v     # stop and wipe the data volume (fresh start)
```
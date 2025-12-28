# TechHealth SQL Lab

TechHealth SQL Lab is a structured SQL analytics environment built around a realistic enterprise database and a controlled session-based challenge system.
It simulates corporate reporting, operational analytics, and technical SQL interview scenarios over a single, consistent dataset deployed on multiple SQL engines.

---

## Repository Structure

```
techhealth-sql-lab/
│
├── README.md
├── LICENSE
│
├── schema/
│   ├── techhealth_sqlserver.sql
│   └── techhealth_postgres.sql
│
├── prompt/
│   └── hybrid_sql_master_prompt.md
│
├── sessions/
│   └── *.sql
│
└── progress.csv
```

---

## Repository Components

### schema/

Contains the complete database definitions for the TechHealth environment.

Two equivalent schemas are provided:

- **techhealth_sqlserver.sql** — SQL Server (T‑SQL)
- **techhealth_postgres.sql** — PostgreSQL

Both files define the same tables and constraints .
Only syntax and data types differ between engines to preserve compatibility.

These files represent the authoritative source of truth for the TechHealth data layer.

---

### prompt/hybrid_sql_master_prompt.md

Defines the Hybrid SQL Master control system.
This specification governs how business requests are generated, how SQL responses are evaluated, how difficulty progresses, and how performance is scored.

It allows analytical sessions to be executed using either T‑SQL or PostgreSQL syntax while operating on the same underlying data model.

---

### sessions/

Each file in this directory represents a complete analytics session.

A session contains:

- Business and interview-style data requests
- The SQL queries produced in response
- Corrections and refinements applied by the control system

These files form a historical audit log of analytical work, mirroring how queries are produced, reviewed, and improved inside a professional data team.

They follow a sequential naming convention (e.g., session_001.sql, session_002.sql, …) and collectively represent the full record of analytical activity within the TechHealth SQL Lab.

---

### progress.csv

Tracks performance metrics for every session using three outcome categories:

- **correct**
- **partial**
- **wrong**

Each row represents one completed session, providing a quantitative record of accuracy and consistency over time.

---

## Project Overview

TechHealth SQL Lab combines three elements into a single analytical system:

- A realistic enterprise health‑technology database
- A rules‑driven query generation and evaluation engine
- A session‑based record of analytical output and quality metrics

Together, these components create a controlled environment for producing, validating, and tracking SQL analytics across multiple database engines.

---

## Author

Daniel Jane Garcia (danij4ne)

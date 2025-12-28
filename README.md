# TechHealth SQL Lab

![SQL Server](https://img.shields.io/badge/SQL%20Server-T--SQL-B3261E?style=for-the-badge&logo=microsoftsqlserver&logoColor=white)
![PostgreSQL](https://img.shields.io/badge/PostgreSQL-3366CC?style=for-the-badge&logo=postgresql&logoColor=white)
![Relational Data](https://img.shields.io/badge/Relational%20Data-Enterprise%20Model-1E293B?style=for-the-badge)
![Architecture](https://img.shields.io/badge/Architecture-Session%20Driven-6D28D9?style=for-the-badge)
![Query Engine](https://img.shields.io/badge/Query%20Engine-Hybrid%20SQL-7C3AED?style=for-the-badge)
![Performance](https://img.shields.io/badge/Performance-Tracking-4F46E5?style=for-the-badge)
![Analytics](https://img.shields.io/badge/Focus-SQL%20Analytics-14B8A6?style=for-the-badge)
![Data Grade](https://img.shields.io/badge/Data-Enterprise%20Grade-0F766E?style=for-the-badge)
![Daily Practice](https://img.shields.io/badge/Practice-Daily%20Challenges-1D4ED8?style=for-the-badge)
![Commit Activity](https://img.shields.io/github/commit-activity/m/danij4ne/techhealth-sql-lab?style=for-the-badge)
![Last Commit](https://img.shields.io/github/last-commit/danij4ne/techhealth-sql-lab?style=for-the-badge)
![License](https://img.shields.io/badge/License-MIT-334155?style=for-the-badge)


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

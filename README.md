# Retail Sales Analytics Dashboard

An end-to-end data analytics project built to demonstrate a full DA workflow — from raw data ingestion to an interactive Power BI dashboard — using the Kaggle Superstore dataset.

---

## Project Overview

This project simulates a real-world data analyst role where raw transactional data is ingested, cleaned, analysed via SQL, and visualised in Power BI for business stakeholders.

|             |                                                                       |
| ----------- | --------------------------------------------------------------------- |
| **Dataset** | Kaggle Superstore (9,994 transactions)                                |
| **Domain**  | Retail Sales Analytics                                                |
| **Tools**   | Python · PostgreSQL · Power BI                                        |
| **Skills**  | Data Ingestion · SQL · DAX · Dashboard Design · Stakeholder Reporting |

---

## Repository Structure

```
retail-sales-analytics/
│
├── main.py                      # Python data ingestion script
├── retail_sales_sql.sql         # SQL schema, views, and 12 KPI queries
├── stakeholder_report.docx      # WIP
├── superstore.pbix              # Power BI dashboard file
├── superstore.pdf               # Power BI PDF file
└── README.md
```

---

## Tech Stack

| Layer          | Tool                        | Purpose                            |
| -------------- | --------------------------- | ---------------------------------- |
| Data Ingestion | Python (pandas, SQLAlchemy) | Load and clean CSV into PostgreSQL |
| Database       | PostgreSQL (pgAdmin)        | Store data and run KPI queries     |
| Analysis       | SQL                         | 12 analytical KPI queries          |
| Visualisation  | Power BI Desktop            | Interactive 3-page dashboard       |
| Reporting      | Word (.docx)                | Stakeholder-facing insight report  |

---

## Pipeline Architecture

```
Raw CSV (Kaggle)
      │
      ▼
Python (pandas)
  - Standardise column names
  - Parse date fields (DD/MM/YYYY → datetime)
  - Load into PostgreSQL via SQLAlchemy
      │
      ▼
PostgreSQL Database
  - superstore table (9,994 rows)
  - vw_superstore view (with engineered features)
  - 12 KPI queries
      │
      ▼
Power BI Dashboard
  - 3 report pages
  - DAX measures
  - Dynamic slicers (date, category, region)
  - Published to Power BI Service
```

---

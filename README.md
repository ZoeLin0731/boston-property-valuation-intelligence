# Boston Property Valuation Intelligence  
**Peer-Based Market Analysis & Mispricing Detection (FY2024)**

## Overview
This project analyzes **Boston FY2024 property assessment data** to identify **market concentration patterns, valuation volatility, and property-level mispricing opportunities** using a peer-based comparison framework.

The workflow mirrors a real-world analytics setup:
- **PostgreSQL** for data modeling and analytics views
- **SQL-first transformations** (cleaning, aggregation, audit logic)
- **Tableau (live connection)** for interactive dashboards
- Focus on **decision-ready outputs** for finance, risk, and analytics stakeholders

The final outcome is a **review queue** highlighting properties that are significantly overvalued or undervalued relative to their local peer group.

---

## Business Questions
1. Which ZIP codes concentrate the most assessed property value?
2. Which ZIPs show **stable vs volatile** valuation patterns?
3. Which **specific properties** should be reviewed for potential mispricing?
4. Where do **peer-based valuation gaps** create risk or opportunity?

---

## Data Source
**Boston Property Assessment Data (FY2024)**  
Boston Open Data Portal

🔗 https://data.boston.gov/dataset/property-assessment/resource/a9eb19ad-da79-4f7b-9e3b-6b13e66f8285

- ~180K property records
- Assessment values, land use, address, and structural attributes
- Publicly available, updated annually

---

## Methodology

### 1. Data Ingestion & Cleaning (PostgreSQL)
- Raw CSV ingested into `raw.property_assessment_fy2024`
- Numeric fields cleaned and cast safely
- Created a typed clean table:
  - `clean.property_fy2024`
- Derived metrics:
  - `value_per_sqft`
  - property-level normalization for comparison

### 2. Analytics Views (SQL)
Built reusable **analytics-layer views** to support Tableau dashboards:

- ZIP × Land Use summaries
- ZIP-level VPSF (Value per Sqft) distributions
- Peer benchmarks (p25 / median / p75)
- Property-level mispricing flags

### 3. Peer-Based Mispricing Logic
For each property:
- Compared `value_per_sqft` to **peer median VPSF**
- Calculated % deviation from peer median
- Labeled properties as:
  - **Overvalued**
  - **Undervalued**
- Applied confidence filters (peer count thresholds)

### 4. Visualization (Tableau)
- **Live connection** to PostgreSQL
- No extracts; dashboards update with database
- Designed for analyst and finance workflows

---

## Dashboards

### Dashboard 1 — Market Concentration Overview
**Audience:** Strategy / Leadership  
- Map: Total assessed value by ZIP
- Bar chart: Top ZIPs by total assessed value
- Table: ZIP × Land Use property mix

**Insight:** Identifies where valuation is concentrated and how land use composition varies by ZIP.

---

### Dashboard 2 — Market Volatility & Pricing Spread
**Audience:** Finance / Risk / Investment  
- VPSF spread by ZIP (p75 − p25)
- Median value vs volatility scatter
- Stable vs volatile ZIP identification

**Insight:** Distinguishes pricing stability from dispersion-driven risk.

---

### Dashboard 3 — Peer-Based Audit & Opportunity List
**Audience:** Finance Office / Analysts  
- Property-level review queue
- Sorted by **absolute % deviation from peer median**
- Filters:
  - ZIP
  - Land Use
  - Overvalued / Undervalued

**Insight:** Converts analytics into an actionable review list for valuation audits.

---

## Repository Structure

```
boston-property-valuation-intelligence/
├── README.md
├── sql/
│   ├── 00_schema_setup.sql
│   ├── 01_clean_property_table.sql
│   └── 02_analytics_views.sql
│
├── notebooks/
│   └── exploration_validation.ipynb
├── tableau/
│   └── screenshots/
└── docs/
├── data_dictionary.md
└── metric_definitions.md
```
---

## Tools & Technologies
- **PostgreSQL** — data modeling & analytics views
- **SQL (CTEs, window functions, percentiles)**
- **Tableau** — live dashboards
- **Python (Jupyter Notebook)** — validation & exploration

---

## Key Takeaway
This project demonstrates how **public data + SQL analytics + Tableau** can be combined to:
- Identify valuation risk
- Detect pricing inefficiencies
- Translate analysis into a **review workflow**, not just charts

It reflects a **real analyst workflow**, not a toy dataset or academic exercise.

---

## Notes
- Tableau dashboards are connected **live** to PostgreSQL
- Screenshots are included for portfolio review
- SQL scripts reflect executed production logic

---

## Author
Zoe Lin  
Master’s in Analytics — Northeastern University  


# RetailPulse Analytics — SQL Portfolio Project

A realistic multi-store retail/e-commerce database + a set of
production-style analytical queries. Built to demonstrate the
SQL skills clients actually pay for on Fiverr / Upwork: schema
design, indexing, CTEs, window functions, views, and triggers.

## Why this project works as a portfolio piece

Most beginner SQL portfolios show `SELECT * FROM table`. This one
mirrors what a real BI/data analyst deliverable looks like:

- **Schema design** — 8 normalized tables (customers, orders,
  order_items, products, categories, stores, employees, reviews)
  with foreign keys and indexes.
- **RFM customer segmentation** — Recency/Frequency/Monetary scoring
  with `NTILE()`, used by real marketing teams to target campaigns.
- **Cohort retention analysis** — the exact report SaaS/e-commerce
  founders ask analysts for.
- **Window functions** — running totals, 7-day moving averages,
  `RANK()` per category, year-over-year growth with `LAG()`.
- **Views & triggers** — `customer_ltv` and `product_performance`
  views ready to plug into Metabase/PowerBI/Tableau, plus triggers
  that auto-update stock and order totals.

## Project structure

```
retail-analytics-sql/
├── schema.sql                 # table definitions + indexes
├── seed_data.py                # generates realistic synthetic data (no external deps)
├── views_and_triggers.sql      # reusable views + automation triggers
├── queries/
│   ├── 01_business_kpis.sql        # revenue, AOV, margin, store leaderboard
│   ├── 02_customer_segmentation.sql# RFM segmentation
│   ├── 03_cohort_retention.sql     # monthly cohort retention
│   └── 04_sales_trends.sql         # running totals, moving avg, rankings, YoY
└── retail.db                   # ready-to-use SQLite database (pre-generated)
```

## Running it on your phone (Termux + Acode + Pydroid)

**Option A — Termux (recommended, fastest):**
```bash
pkg install sqlite python -y
cd retail-analytics-sql
python seed_data.py               # (re)generates retail.db, ~3000 orders
sqlite3 retail.db < views_and_triggers.sql
sqlite3 retail.db < queries/02_customer_segmentation.sql
```
Or open it interactively:
```bash
sqlite3 retail.db
sqlite> .headers on
sqlite> .mode column
sqlite> .read queries/01_business_kpis.sql
```

**Option B — Pydroid 3:**
Open `seed_data.py` and run it — it uses only the standard
library (`sqlite3`, `random`, `datetime`), so no pip installs
needed. Then query `retail.db` from a short script:
```python
import sqlite3
conn = sqlite3.connect("retail.db")
for row in conn.execute(open("queries/01_business_kpis.sql").read().split(";")[0]):
    print(row)
```

**Option C — Acode:**
Use Acode purely as the editor to browse/tweak the `.sql` files
and `seed_data.py`; run everything through the Termux terminal
(Acode has a built-in Termux plugin for exactly this workflow).

## Using this for Fiverr / Upwork

1. Push the folder to a public GitHub repo — clients and buyers
   trust a linked repo far more than pasted code.
2. Take 2–3 screenshots of query results (e.g. the RFM segment
   summary, the cohort retention table) — visuals sell gigs.
3. Suggested gig title: *"I will design a SQL database and write
   advanced analytical queries (CTEs, window functions, RFM)"*.
4. In your gig description, name the concrete deliverables clients
   recognize: schema design, indexing, RFM segmentation, cohort
   retention, running totals/moving averages, views & triggers.
5. Offer this as a demo, then scope real client work as: "same
   analysis, applied to your own database/CSV export."

## Extending it further (good upsell ideas for a gig)

- Add a `discounts`/`promotions` table and a query measuring
  promo lift.
- Port `schema.sql` to PostgreSQL and add `EXPLAIN ANALYZE`
  query-optimization notes — great for a "SQL performance tuning"
  gig variant.
- Wire `customer_ltv` / `product_performance` views into a free
  BI tool (Metabase) for a live dashboard demo.

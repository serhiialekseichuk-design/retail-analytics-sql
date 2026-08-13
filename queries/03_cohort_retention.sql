-- =========================================================
-- 03. MONTHLY COHORT RETENTION ANALYSIS
-- Demonstrates: CTEs, self-joins, date math, pivot-style
-- aggregation — a staple deliverable for SaaS/e-commerce
-- retention reporting.
-- =========================================================

WITH first_purchase AS (
    SELECT
        customer_id,
        strftime('%Y-%m', MIN(order_date)) AS cohort_month
    FROM orders
    WHERE status = 'completed'
    GROUP BY customer_id
),
orders_with_cohort AS (
    SELECT
        o.customer_id,
        fp.cohort_month,
        strftime('%Y-%m', o.order_date) AS order_month,
        (CAST(strftime('%Y', o.order_date) AS INTEGER) - CAST(substr(fp.cohort_month,1,4) AS INTEGER)) * 12
          + (CAST(strftime('%m', o.order_date) AS INTEGER) - CAST(substr(fp.cohort_month,6,2) AS INTEGER))
          AS month_number
    FROM orders o
    JOIN first_purchase fp ON fp.customer_id = o.customer_id
    WHERE o.status = 'completed'
)
SELECT
    cohort_month,
    month_number,
    COUNT(DISTINCT customer_id) AS active_customers
FROM orders_with_cohort
GROUP BY cohort_month, month_number
ORDER BY cohort_month, month_number;

-- Retention rate relative to cohort size (month 0 = 100%)
WITH first_purchase AS (
    SELECT customer_id, strftime('%Y-%m', MIN(order_date)) AS cohort_month
    FROM orders WHERE status = 'completed'
    GROUP BY customer_id
),
cohort_size AS (
    SELECT cohort_month, COUNT(*) AS customers
    FROM first_purchase GROUP BY cohort_month
),
activity AS (
    SELECT
        fp.cohort_month,
        (CAST(strftime('%Y', o.order_date) AS INTEGER) - CAST(substr(fp.cohort_month,1,4) AS INTEGER)) * 12
          + (CAST(strftime('%m', o.order_date) AS INTEGER) - CAST(substr(fp.cohort_month,6,2) AS INTEGER))
          AS month_number,
        o.customer_id
    FROM orders o
    JOIN first_purchase fp ON fp.customer_id = o.customer_id
    WHERE o.status = 'completed'
)
SELECT
    a.cohort_month,
    a.month_number,
    COUNT(DISTINCT a.customer_id)                                   AS active_customers,
    cs.customers                                                    AS cohort_size,
    ROUND(100.0 * COUNT(DISTINCT a.customer_id) / cs.customers, 1)  AS retention_pct
FROM activity a
JOIN cohort_size cs ON cs.cohort_month = a.cohort_month
GROUP BY a.cohort_month, a.month_number
ORDER BY a.cohort_month, a.month_number;

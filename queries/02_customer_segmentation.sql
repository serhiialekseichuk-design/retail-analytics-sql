-- =========================================================
-- 02. RFM CUSTOMER SEGMENTATION
-- Demonstrates: CTEs, NTILE() window function, CASE logic
-- Classic technique used by real e-commerce/marketing teams
-- to prioritize retention and upsell campaigns.
-- =========================================================

WITH customer_orders AS (
    SELECT
        customer_id,
        MAX(order_date)              AS last_order_date,
        COUNT(*)                     AS frequency,
        SUM(total_amount)            AS monetary
    FROM orders
    WHERE status = 'completed'
    GROUP BY customer_id
),
scored AS (
    SELECT
        customer_id,
        last_order_date,
        frequency,
        monetary,
        CAST(julianday('2026-08-01') - julianday(last_order_date) AS INTEGER) AS recency_days,
        NTILE(5) OVER (ORDER BY julianday(last_order_date) DESC) AS recency_score,
        NTILE(5) OVER (ORDER BY frequency ASC)                   AS frequency_score,
        NTILE(5) OVER (ORDER BY monetary ASC)                    AS monetary_score
    FROM customer_orders
)
SELECT
    customer_id,
    recency_days,
    frequency,
    ROUND(monetary, 2)                                    AS monetary,
    recency_score, frequency_score, monetary_score,
    (recency_score + frequency_score + monetary_score)    AS rfm_total,
    CASE
        WHEN recency_score >= 4 AND frequency_score >= 4 AND monetary_score >= 4 THEN 'Champions'
        WHEN recency_score >= 4 AND frequency_score >= 3                       THEN 'Loyal Customers'
        WHEN recency_score >= 4 AND frequency_score <= 2                       THEN 'New / Promising'
        WHEN recency_score <= 2 AND frequency_score >= 4                       THEN 'At Risk (High Value)'
        WHEN recency_score <= 2 AND frequency_score <= 2                       THEN 'Lost / Churned'
        ELSE 'Needs Attention'
    END AS segment
FROM scored
ORDER BY rfm_total DESC
LIMIT 50;

-- Segment summary (business-ready pivot)
WITH customer_orders AS (
    SELECT customer_id, MAX(order_date) AS last_order_date,
           COUNT(*) AS frequency, SUM(total_amount) AS monetary
    FROM orders WHERE status = 'completed'
    GROUP BY customer_id
),
scored AS (
    SELECT customer_id,
        NTILE(5) OVER (ORDER BY julianday(last_order_date) DESC) AS r,
        NTILE(5) OVER (ORDER BY frequency ASC) AS f,
        NTILE(5) OVER (ORDER BY monetary ASC) AS m,
        monetary
    FROM customer_orders
),
segmented AS (
    SELECT *,
        CASE
            WHEN r >= 4 AND f >= 4 AND m >= 4 THEN 'Champions'
            WHEN r >= 4 AND f >= 3            THEN 'Loyal Customers'
            WHEN r >= 4 AND f <= 2            THEN 'New / Promising'
            WHEN r <= 2 AND f >= 4            THEN 'At Risk (High Value)'
            WHEN r <= 2 AND f <= 2            THEN 'Lost / Churned'
            ELSE 'Needs Attention'
        END AS segment
    FROM scored
)
SELECT segment, COUNT(*) AS customers, ROUND(SUM(monetary), 2) AS segment_revenue
FROM segmented
GROUP BY segment
ORDER BY segment_revenue DESC;

-- =========================================================
-- 04. SALES TRENDS & RANKINGS
-- Demonstrates: RANK/ROW_NUMBER, running totals, moving
-- averages, year-over-year growth — the window-function
-- toolkit clients most often ask for in analytics gigs.
-- =========================================================

-- Running total of revenue over time
WITH daily AS (
    SELECT order_date, SUM(total_amount) AS revenue
    FROM orders
    WHERE status = 'completed'
    GROUP BY order_date
)
SELECT
    order_date,
    revenue,
    ROUND(SUM(revenue) OVER (ORDER BY order_date), 2) AS running_total
FROM daily
ORDER BY order_date;

-- 7-day moving average of daily revenue
WITH daily AS (
    SELECT order_date, SUM(total_amount) AS revenue
    FROM orders
    WHERE status = 'completed'
    GROUP BY order_date
)
SELECT
    order_date,
    revenue,
    ROUND(AVG(revenue) OVER (
        ORDER BY order_date
        ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
    ), 2) AS moving_avg_7d
FROM daily
ORDER BY order_date;

-- Top 5 best-selling products per category (RANK)
WITH product_sales AS (
    SELECT
        p.product_id,
        p.product_name,
        c.category_name,
        SUM(oi.quantity)                    AS units_sold,
        ROUND(SUM(oi.quantity * oi.unit_price), 2) AS revenue
    FROM order_items oi
    JOIN products p   ON p.product_id = oi.product_id
    JOIN categories c ON c.category_id = p.category_id
    JOIN orders o     ON o.order_id = oi.order_id
    WHERE o.status = 'completed'
    GROUP BY p.product_id
),
ranked AS (
    SELECT *,
        RANK() OVER (PARTITION BY category_name ORDER BY revenue DESC) AS rank_in_category
    FROM product_sales
)
SELECT category_name, product_name, units_sold, revenue, rank_in_category
FROM ranked
WHERE rank_in_category <= 5
ORDER BY category_name, rank_in_category;

-- Year-over-year monthly revenue growth
WITH monthly AS (
    SELECT
        strftime('%Y', order_date) AS yr,
        strftime('%m', order_date) AS mo,
        SUM(total_amount)          AS revenue
    FROM orders
    WHERE status = 'completed'
    GROUP BY yr, mo
)
SELECT
    yr, mo, revenue,
    LAG(revenue) OVER (PARTITION BY mo ORDER BY yr)              AS revenue_prev_year,
    ROUND(100.0 * (revenue - LAG(revenue) OVER (PARTITION BY mo ORDER BY yr))
          / NULLIF(LAG(revenue) OVER (PARTITION BY mo ORDER BY yr), 0), 1) AS yoy_growth_pct
FROM monthly
ORDER BY mo, yr;

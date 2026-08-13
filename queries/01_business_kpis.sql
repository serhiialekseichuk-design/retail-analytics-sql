-- =========================================================
-- 01. CORE BUSINESS KPIs
-- Demonstrates: joins, aggregation, date functions, filtering
-- =========================================================

-- Overall revenue, order count, average order value (completed orders only)
SELECT
    COUNT(*)                                   AS total_orders,
    ROUND(SUM(total_amount), 2)                AS total_revenue,
    ROUND(AVG(total_amount), 2)                AS avg_order_value
FROM orders
WHERE status = 'completed';

-- Monthly revenue trend
SELECT
    strftime('%Y-%m', order_date)              AS month,
    ROUND(SUM(total_amount), 2)                AS revenue,
    COUNT(*)                                   AS orders
FROM orders
WHERE status = 'completed'
GROUP BY month
ORDER BY month;

-- Revenue and margin by category
SELECT
    c.category_name,
    ROUND(SUM(oi.quantity * oi.unit_price), 2)         AS revenue,
    ROUND(SUM(oi.quantity * (oi.unit_price - p.cost)), 2) AS gross_profit,
    ROUND(100.0 * SUM(oi.quantity * (oi.unit_price - p.cost))
          / NULLIF(SUM(oi.quantity * oi.unit_price), 0), 1) AS margin_pct
FROM order_items oi
JOIN products p   ON p.product_id = oi.product_id
JOIN categories c ON c.category_id = p.category_id
JOIN orders o     ON o.order_id = oi.order_id
WHERE o.status = 'completed'
GROUP BY c.category_name
ORDER BY revenue DESC;

-- Store performance leaderboard
SELECT
    s.store_name,
    s.city,
    COUNT(DISTINCT o.order_id)          AS orders,
    ROUND(SUM(o.total_amount), 2)       AS revenue,
    ROUND(AVG(o.total_amount), 2)       AS avg_order_value
FROM orders o
JOIN stores s ON s.store_id = o.store_id
WHERE o.status = 'completed'
GROUP BY s.store_id
ORDER BY revenue DESC;

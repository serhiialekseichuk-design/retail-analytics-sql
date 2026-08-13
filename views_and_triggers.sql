-- =========================================================
-- VIEWS & TRIGGERS
-- Demonstrates: reusable views for BI tools, and triggers
-- that enforce business logic automatically at the DB layer.
-- =========================================================

-- View: customer lifetime value, ready to plug into any BI tool
DROP VIEW IF EXISTS customer_ltv;
CREATE VIEW customer_ltv AS
SELECT
    c.customer_id,
    c.first_name || ' ' || c.last_name AS customer_name,
    c.country,
    COUNT(o.order_id)                  AS total_orders,
    ROUND(COALESCE(SUM(o.total_amount), 0), 2) AS lifetime_value,
    MIN(o.order_date)                  AS first_order_date,
    MAX(o.order_date)                  AS last_order_date
FROM customers c
LEFT JOIN orders o ON o.customer_id = c.customer_id AND o.status = 'completed'
GROUP BY c.customer_id;

-- View: product performance (sales + review rating combined)
DROP VIEW IF EXISTS product_performance;
CREATE VIEW product_performance AS
SELECT
    p.product_id,
    p.product_name,
    c.category_name,
    p.stock_qty,
    COALESCE(SUM(oi.quantity), 0)                         AS units_sold,
    ROUND(COALESCE(SUM(oi.quantity * oi.unit_price), 0), 2) AS revenue,
    ROUND((SELECT AVG(rating) FROM reviews r WHERE r.product_id = p.product_id), 2) AS avg_rating,
    (SELECT COUNT(*) FROM reviews r WHERE r.product_id = p.product_id) AS review_count
FROM products p
JOIN categories c ON c.category_id = p.category_id
LEFT JOIN order_items oi ON oi.product_id = p.product_id
LEFT JOIN orders o ON o.order_id = oi.order_id AND o.status = 'completed'
GROUP BY p.product_id;

-- Trigger: automatically decrement stock when an order item is inserted
DROP TRIGGER IF EXISTS trg_decrement_stock;
CREATE TRIGGER trg_decrement_stock
AFTER INSERT ON order_items
BEGIN
    UPDATE products
    SET stock_qty = stock_qty - NEW.quantity
    WHERE product_id = NEW.product_id;
END;

-- Trigger: keep orders.total_amount in sync if order_items change
DROP TRIGGER IF EXISTS trg_recalc_order_total;
CREATE TRIGGER trg_recalc_order_total
AFTER INSERT ON order_items
BEGIN
    UPDATE orders
    SET total_amount = (
        SELECT ROUND(SUM(quantity * unit_price), 2)
        FROM order_items
        WHERE order_id = NEW.order_id
    )
    WHERE order_id = NEW.order_id;
END;

-- =========================================================
-- RetailPulse Analytics — Database Schema (SQLite dialect)
-- A realistic mid-size e-commerce/retail data model used
-- to showcase advanced SQL skills: joins, window functions,
-- CTEs, views, triggers, and query optimization.
-- =========================================================

PRAGMA foreign_keys = ON;

DROP TABLE IF EXISTS reviews;
DROP TABLE IF EXISTS order_items;
DROP TABLE IF EXISTS orders;
DROP TABLE IF EXISTS employees;
DROP TABLE IF EXISTS stores;
DROP TABLE IF EXISTS products;
DROP TABLE IF EXISTS categories;
DROP TABLE IF EXISTS customers;

CREATE TABLE customers (
    customer_id     INTEGER PRIMARY KEY,
    first_name      TEXT NOT NULL,
    last_name       TEXT NOT NULL,
    email           TEXT UNIQUE NOT NULL,
    country         TEXT NOT NULL,
    signup_date     DATE NOT NULL
);

CREATE TABLE categories (
    category_id     INTEGER PRIMARY KEY,
    category_name   TEXT NOT NULL
);

CREATE TABLE products (
    product_id      INTEGER PRIMARY KEY,
    product_name    TEXT NOT NULL,
    category_id     INTEGER NOT NULL REFERENCES categories(category_id),
    price           NUMERIC(10,2) NOT NULL,
    cost            NUMERIC(10,2) NOT NULL,
    stock_qty       INTEGER NOT NULL DEFAULT 0
);

CREATE TABLE stores (
    store_id        INTEGER PRIMARY KEY,
    store_name      TEXT NOT NULL,
    city            TEXT NOT NULL,
    country         TEXT NOT NULL
);

CREATE TABLE employees (
    employee_id     INTEGER PRIMARY KEY,
    full_name       TEXT NOT NULL,
    role            TEXT NOT NULL,
    hire_date       DATE NOT NULL,
    store_id        INTEGER NOT NULL REFERENCES stores(store_id)
);

CREATE TABLE orders (
    order_id        INTEGER PRIMARY KEY,
    customer_id     INTEGER NOT NULL REFERENCES customers(customer_id),
    store_id        INTEGER NOT NULL REFERENCES stores(store_id),
    employee_id     INTEGER REFERENCES employees(employee_id),
    order_date      DATE NOT NULL,
    status          TEXT NOT NULL CHECK (status IN ('completed','cancelled','returned')),
    total_amount    NUMERIC(10,2) NOT NULL DEFAULT 0
);

CREATE TABLE order_items (
    order_item_id   INTEGER PRIMARY KEY,
    order_id        INTEGER NOT NULL REFERENCES orders(order_id),
    product_id      INTEGER NOT NULL REFERENCES products(product_id),
    quantity        INTEGER NOT NULL CHECK (quantity > 0),
    unit_price      NUMERIC(10,2) NOT NULL
);

CREATE TABLE reviews (
    review_id       INTEGER PRIMARY KEY,
    product_id      INTEGER NOT NULL REFERENCES products(product_id),
    customer_id     INTEGER NOT NULL REFERENCES customers(customer_id),
    rating          INTEGER NOT NULL CHECK (rating BETWEEN 1 AND 5),
    review_date     DATE NOT NULL
);

-- Helpful indexes for analytical queries
CREATE INDEX idx_orders_customer ON orders(customer_id);
CREATE INDEX idx_orders_date ON orders(order_date);
CREATE INDEX idx_order_items_order ON order_items(order_id);
CREATE INDEX idx_order_items_product ON order_items(product_id);
CREATE INDEX idx_products_category ON products(category_id);
CREATE INDEX idx_reviews_product ON reviews(product_id);

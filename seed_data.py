#!/usr/bin/env python3
"""
RetailPulse Analytics — Synthetic Data Generator
Pure standard library (no pip installs needed) so it runs
out-of-the-box in Termux / Pydroid.

Usage:
    python seed_data.py
Creates retail.db in the current folder, applies schema.sql,
then fills it with realistic, internally-consistent data:
customers, categories, products, stores, employees, orders,
order_items, reviews.
"""

import sqlite3
import random
import os
from datetime import date, timedelta

random.seed(42)  # reproducible dataset

DB_PATH = "retail.db"
SCHEMA_PATH = "schema.sql"

FIRST_NAMES = ["James","Mary","Robert","Patricia","John","Jennifer","Michael","Linda",
               "David","Elizabeth","William","Barbara","Richard","Susan","Joseph","Jessica",
               "Thomas","Sarah","Charles","Karen","Daniel","Nancy","Matthew","Lisa","Anthony",
               "Betty","Mark","Margaret","Paul","Sandra"]
LAST_NAMES = ["Smith","Johnson","Williams","Brown","Jones","Garcia","Miller","Davis","Rodriguez",
              "Martinez","Hernandez","Lopez","Gonzalez","Wilson","Anderson","Thomas","Taylor",
              "Moore","Jackson","Martin","Lee","Perez","Thompson","White","Harris","Sanchez",
              "Clark","Ramirez","Lewis","Robinson"]
COUNTRIES = ["United States","United Kingdom","Canada","Germany","Australia","France",
             "Netherlands","Spain","Sweden","Ireland"]

CATEGORIES = ["Electronics","Home & Kitchen","Sports & Outdoors","Beauty & Personal Care",
              "Books","Toys & Games","Fashion","Office Supplies","Pet Supplies","Garden"]

PRODUCT_ADJ = ["Premium","Compact","Wireless","Eco","Portable","Deluxe","Classic","Smart",
               "Pro","Essential"]
PRODUCT_NOUN = {
    "Electronics": ["Headphones","Bluetooth Speaker","Charging Cable","Smart Watch","Webcam"],
    "Home & Kitchen": ["Blender","Cookware Set","Coffee Maker","Vacuum Cleaner","Air Fryer"],
    "Sports & Outdoors": ["Yoga Mat","Water Bottle","Camping Tent","Running Shoes","Dumbbell Set"],
    "Beauty & Personal Care": ["Face Serum","Hair Dryer","Electric Toothbrush","Shampoo Set","Trimmer"],
    "Books": ["Novel","Cookbook","Planner","Notebook Set","Journal"],
    "Toys & Games": ["Board Game","Puzzle Set","RC Car","Building Blocks","Action Figure"],
    "Fashion": ["T-Shirt","Backpack","Sunglasses","Wallet","Sneakers"],
    "Office Supplies": ["Desk Organizer","Standing Desk","Monitor Stand","Notebook","Pen Set"],
    "Pet Supplies": ["Dog Leash","Cat Tree","Pet Bed","Food Bowl","Grooming Kit"],
    "Garden": ["Plant Pot","Garden Hose","Pruning Shears","Solar Light","Watering Can"],
}

STORES = [("Downtown Flagship","New York","United States"),
          ("Westside Outlet","Los Angeles","United States"),
          ("Central Store","London","United Kingdom"),
          ("Harbor Branch","Toronto","Canada"),
          ("Online Warehouse","Berlin","Germany")]

EMP_ROLES = ["Sales Associate","Store Manager","Support Specialist","Cashier"]

N_CUSTOMERS = 500
N_PRODUCTS_PER_CAT = 5
N_ORDERS = 3000
START_DATE = date(2023, 1, 1)
END_DATE = date(2026, 8, 1)


def random_date(start, end):
    delta = (end - start).days
    return start + timedelta(days=random.randint(0, delta))


def build():
    if os.path.exists(DB_PATH):
        os.remove(DB_PATH)

    conn = sqlite3.connect(DB_PATH)
    cur = conn.cursor()

    with open(SCHEMA_PATH, "r") as f:
        cur.executescript(f.read())

    # --- categories ---
    for i, name in enumerate(CATEGORIES, start=1):
        cur.execute("INSERT INTO categories VALUES (?,?)", (i, name))

    # --- products ---
    product_id = 1
    products = []  # (id, category_id, price, cost)
    for cat_id, cat_name in enumerate(CATEGORIES, start=1):
        for noun in PRODUCT_NOUN[cat_name]:
            for _ in range(N_PRODUCTS_PER_CAT // len(PRODUCT_NOUN[cat_name]) + 1):
                if len([p for p in products if p[1] == cat_id]) >= N_PRODUCTS_PER_CAT:
                    break
                name = f"{random.choice(PRODUCT_ADJ)} {noun}"
                cost = round(random.uniform(5, 150), 2)
                price = round(cost * random.uniform(1.3, 2.5), 2)
                stock = random.randint(0, 500)
                cur.execute("INSERT INTO products VALUES (?,?,?,?,?,?)",
                            (product_id, name, cat_id, price, cost, stock))
                products.append((product_id, cat_id, price, cost))
                product_id += 1

    # --- stores ---
    for i, (name, city, country) in enumerate(STORES, start=1):
        cur.execute("INSERT INTO stores VALUES (?,?,?,?)", (i, name, city, country))

    # --- employees ---
    employees = []
    emp_id = 1
    for store_id in range(1, len(STORES) + 1):
        for _ in range(random.randint(3, 6)):
            name = f"{random.choice(FIRST_NAMES)} {random.choice(LAST_NAMES)}"
            role = random.choice(EMP_ROLES)
            hire = random_date(date(2020, 1, 1), END_DATE)
            cur.execute("INSERT INTO employees VALUES (?,?,?,?,?)",
                        (emp_id, name, role, hire, store_id))
            employees.append((emp_id, store_id))
            emp_id += 1

    # --- customers ---
    customers = []
    for cid in range(1, N_CUSTOMERS + 1):
        fn, ln = random.choice(FIRST_NAMES), random.choice(LAST_NAMES)
        email = f"{fn.lower()}.{ln.lower()}{cid}@example.com"
        country = random.choice(COUNTRIES)
        signup = random_date(START_DATE, END_DATE)
        cur.execute("INSERT INTO customers VALUES (?,?,?,?,?,?)",
                    (cid, fn, ln, email, country, signup))
        customers.append((cid, signup))

    # --- orders + order_items (weighted so some customers buy a lot -> good for RFM/cohorts) ---
    weights = [random.random() ** 2 for _ in customers]  # skewed distribution
    order_id = 1
    item_id = 1
    for _ in range(N_ORDERS):
        cust_id, signup = random.choices(customers, weights=weights, k=1)[0]
        order_date = random_date(max(signup, START_DATE), END_DATE)
        store_id = random.randint(1, len(STORES))
        emp_candidates = [e for e in employees if e[1] == store_id]
        emp_id = random.choice(emp_candidates)[0] if emp_candidates else None
        status = random.choices(["completed", "cancelled", "returned"], weights=[88, 7, 5])[0]

        n_items = random.randint(1, 5)
        chosen_products = random.sample(products, n_items)
        order_total = 0
        item_rows = []
        for p in chosen_products:
            pid, _, price, _ = p
            qty = random.randint(1, 4)
            item_rows.append((item_id, order_id, pid, qty, price))
            order_total += qty * price
            item_id += 1

        cur.execute("INSERT INTO orders VALUES (?,?,?,?,?,?,?)",
                    (order_id, cust_id, store_id, emp_id, order_date, status, round(order_total, 2)))
        cur.executemany("INSERT INTO order_items VALUES (?,?,?,?,?)", item_rows)
        order_id += 1

    # --- reviews ---
    review_id = 1
    for _ in range(1800):
        cust_id, _ = random.choice(customers)
        pid = random.choice(products)[0]
        rating = random.choices([5, 4, 3, 2, 1], weights=[40, 30, 15, 10, 5])[0]
        rdate = random_date(START_DATE, END_DATE)
        cur.execute("INSERT INTO reviews VALUES (?,?,?,?,?)",
                    (review_id, pid, cust_id, rating, rdate))
        review_id += 1

    conn.commit()
    conn.close()
    print(f"Done. Created {DB_PATH} with {N_CUSTOMERS} customers, "
          f"{len(products)} products, {N_ORDERS} orders, 1800 reviews.")


if __name__ == "__main__":
    build()

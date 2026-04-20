-- ============================================================
-- SUPERSTORE SALES ANALYTICS PROJECT
-- Data Analyst Portfolio Project
-- ============================================================
-- DATASET OVERVIEW:
--   superstore : single flat table matching the Superstore CSV
-- ============================================================


-- ============================================================
-- SECTION 1: SCHEMA
-- ============================================================

CREATE TABLE superstore (
    row_id          SERIAL PRIMARY KEY,
    order_id        VARCHAR(50),
    order_date      DATE,
    ship_date       DATE,
    ship_mode       VARCHAR(50),
    customer_id     VARCHAR(50),
    customer_name   VARCHAR(100),
    segment         VARCHAR(50),
    country         VARCHAR(100),
    city            VARCHAR(100),
    state           VARCHAR(100),
    postal_code     VARCHAR(20),
    region          VARCHAR(50),
    product_id      VARCHAR(50),
    category        VARCHAR(50),
    sub_category    VARCHAR(50),
    product_name    VARCHAR(255),
    sales           NUMERIC(10,2)
);


-- ============================================================
-- SECTION 2: DATA CLEANING & VALIDATION
-- ============================================================

-- 2a. Check for nulls in critical columns
SELECT
    COUNT(*) FILTER (WHERE order_id     IS NULL) AS null_order_id,
    COUNT(*) FILTER (WHERE order_date   IS NULL) AS null_order_date,
    COUNT(*) FILTER (WHERE customer_id  IS NULL) AS null_customer_id,
    COUNT(*) FILTER (WHERE sales        IS NULL) AS null_sales,
    COUNT(*) FILTER (WHERE product_id   IS NULL) AS null_product_id
FROM superstore;

-- 2b. Check for zero or negative sales
SELECT *
FROM superstore
WHERE sales <= 0;

-- 2c. Check for duplicate row IDs
SELECT row_id, COUNT(*) AS occurrences
FROM superstore
GROUP BY row_id
HAVING COUNT(*) > 1;

-- 2d. Check ship date is never before order date
SELECT order_id, order_date, ship_date
FROM superstore
WHERE ship_date < order_date;

-- 2e. Distinct values check for categorical columns
SELECT DISTINCT segment     FROM superstore;
SELECT DISTINCT region      FROM superstore;
SELECT DISTINCT category    FROM superstore;
SELECT DISTINCT sub_category FROM superstore;
SELECT DISTINCT ship_mode   FROM superstore;


-- ============================================================
-- SECTION 3: FEATURE ENGINEERING — BASE VIEW
-- ============================================================

CREATE VIEW vw_superstore AS
SELECT
    row_id,
    order_id,
    order_date,
    ship_date,
    DATE_TRUNC('month', order_date)         AS order_month,
    TO_CHAR(order_date, 'YYYY-Q')           AS order_quarter,
    EXTRACT(YEAR FROM order_date)           AS order_year,
    ship_mode,
    -- Days to ship
    (ship_date - order_date) AS days_to_ship,
    customer_id,
    customer_name,
    segment,
    country,
    city,
    state,
    postal_code,
    region,
    product_id,
    category,
    sub_category,
    product_name,
    sales
FROM superstore;


-- ============================================================
-- SECTION 4: KPI QUERIES
-- ============================================================

-- ------------------------------------------------
-- KPI 1: Monthly Revenue Trend
-- ------------------------------------------------
SELECT
    order_month,
    COUNT(DISTINCT order_id)        AS total_orders,
    COUNT(DISTINCT customer_id)     AS unique_customers,
    ROUND(SUM(sales)::NUMERIC, 2)   AS total_sales
FROM vw_superstore
GROUP BY order_month
ORDER BY order_month;


-- ------------------------------------------------
-- KPI 2: Sales by Category (ranked)
-- ------------------------------------------------
SELECT
    category,
    ROUND(SUM(sales)::NUMERIC, 2)               AS total_sales,
    ROUND(SUM(sales)::NUMERIC / SUM(SUM(sales)::NUMERIC) OVER () * 100, 1) AS sales_share_pct,
    RANK() OVER (ORDER BY SUM(sales) DESC)      AS sales_rank
FROM vw_superstore
GROUP BY category
ORDER BY sales_rank;


-- ------------------------------------------------
-- KPI 3: Sales by Sub-Category (Top 10)
-- ------------------------------------------------
SELECT
    category,
    sub_category,
    ROUND(SUM(sales)::NUMERIC, 2)   AS total_sales,
    COUNT(DISTINCT order_id)        AS total_orders
FROM vw_superstore
GROUP BY category, sub_category
ORDER BY total_sales DESC
LIMIT 10;


-- ------------------------------------------------
-- KPI 4: Sales by Region
-- ------------------------------------------------
SELECT
    region,
    COUNT(DISTINCT order_id)        AS total_orders,
    COUNT(DISTINCT customer_id)     AS unique_customers,
    ROUND(SUM(sales)::NUMERIC, 2)   AS total_sales,
    ROUND(SUM(sales)::NUMERIC / SUM(SUM(sales)::NUMERIC) OVER () * 100, 1) AS sales_share_pct
FROM vw_superstore
GROUP BY region
ORDER BY total_sales DESC;


-- ------------------------------------------------
-- KPI 5: Sales by Customer Segment
-- ------------------------------------------------
SELECT
    segment,
    COUNT(DISTINCT customer_id)     AS num_customers,
    COUNT(DISTINCT order_id)        AS total_orders,
    ROUND(SUM(sales)::NUMERIC, 2)   AS total_sales,
    ROUND(AVG(sales)::NUMERIC, 2)   AS avg_sale_per_row
FROM vw_superstore
GROUP BY segment
ORDER BY total_sales DESC;


-- ------------------------------------------------
-- KPI 6: Top 10 Customers by Sales
-- ------------------------------------------------
SELECT
    customer_id,
    customer_name,
    segment,
    COUNT(DISTINCT order_id)        AS total_orders,
    ROUND(SUM(sales)::NUMERIC, 2)   AS total_sales,
    ROUND(AVG(sales)::NUMERIC, 2)   AS avg_order_value,
    MIN(order_date)                 AS first_purchase,
    MAX(order_date)                 AS last_purchase
FROM vw_superstore
GROUP BY customer_id, customer_name, segment
ORDER BY total_sales DESC
LIMIT 10;


-- ------------------------------------------------
-- KPI 7: Repeat Purchase Rate
-- ------------------------------------------------
WITH order_counts AS (
    SELECT customer_id, COUNT(DISTINCT order_id) AS num_orders
    FROM superstore
    GROUP BY customer_id
)
SELECT
    COUNT(*) FILTER (WHERE num_orders > 1)      AS repeat_customers,
    COUNT(*)                                    AS total_customers,
    ROUND(
        (COUNT(*) FILTER (WHERE num_orders > 1))::NUMERIC 
        / NULLIF(COUNT(*), 0) * 100, 1
    )                                           AS repeat_rate_pct
FROM order_counts;


-- ------------------------------------------------
-- KPI 8: Month-over-Month Sales Growth
-- ------------------------------------------------
WITH monthly AS (
    SELECT
        order_month,
        SUM(sales) AS monthly_sales
    FROM vw_superstore
    GROUP BY order_month
)
SELECT
    order_month,
    ROUND(monthly_sales::NUMERIC, 2)            AS monthly_sales,
    ROUND(LAG(monthly_sales) OVER (ORDER BY order_month)::NUMERIC, 2) AS prev_month_sales,
    ROUND(
        (monthly_sales - LAG(monthly_sales) OVER (ORDER BY order_month))
        / NULLIF(LAG(monthly_sales) OVER (ORDER BY order_month), 0) * 100, 1
    )                                           AS mom_growth_pct
FROM monthly
ORDER BY order_month;


-- ------------------------------------------------
-- KPI 9: Sales by Ship Mode
-- ------------------------------------------------
SELECT
    ship_mode,
    COUNT(DISTINCT order_id)            AS total_orders,
    ROUND(AVG(days_to_ship)::NUMERIC, 1) AS avg_days_to_ship,
    ROUND(SUM(sales)::NUMERIC, 2)       AS total_sales,
    ROUND(SUM(sales)::NUMERIC / SUM(SUM(sales)::NUMERIC) OVER () * 100, 1) AS sales_share_pct
FROM vw_superstore
GROUP BY ship_mode
ORDER BY total_sales DESC;


-- ------------------------------------------------
-- KPI 10: Customer Lifetime Value (CLV) Proxy
-- ------------------------------------------------
SELECT
    customer_id,
    customer_name,
    segment,
    COUNT(DISTINCT order_id)                        AS total_orders,
    ROUND(SUM(sales)::NUMERIC, 2)                   AS total_spend,
    ROUND(SUM(sales)::NUMERIC / NULLIF(COUNT(DISTINCT order_id), 0), 2) AS avg_order_value,
    MIN(order_date)                                 AS first_purchase,
    MAX(order_date)                                 AS last_purchase,
    (MAX(order_date) - MIN(order_date))             AS customer_tenure_days
FROM vw_superstore
GROUP BY customer_id, customer_name, segment
ORDER BY total_spend DESC;


-- ------------------------------------------------
-- KPI 11: Top 5 States by Sales
-- ------------------------------------------------
SELECT
    state,
    region,
    COUNT(DISTINCT order_id)        AS total_orders,
    ROUND(SUM(sales)::NUMERIC, 2)   AS total_sales
FROM vw_superstore
GROUP BY state, region
ORDER BY total_sales DESC
LIMIT 5;


-- ------------------------------------------------
-- KPI 12: Yearly Sales Summary
-- ------------------------------------------------
SELECT
    order_year,
    COUNT(DISTINCT order_id)        AS total_orders,
    COUNT(DISTINCT customer_id)     AS unique_customers,
    ROUND(SUM(sales)::NUMERIC, 2)   AS total_sales
FROM vw_superstore
GROUP BY order_year
ORDER BY order_year;
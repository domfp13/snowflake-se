-- =============================================================================
-- Snowflake Pipeline: RAW -> TRANSFORM -> ANALYTICS
-- Creates schemas, Iceberg tables from Postgres catalog, dynamic tables, and
-- the final analytics view.
-- =============================================================================
-- Prerequisites:
--   - PG_SNOWFLAKE_PROD instance running with pg_lake enabled
--   - pg_lake Iceberg tables created (see pipeline_postgres.sql)
--   - Catalog integration created (see setup.sql)
-- =============================================================================

-- ============================================================
-- STEP 1: Database & Schemas
-- ============================================================
USE ROLE SYSADMIN;
USE WAREHOUSE GENERIC;

CREATE DATABASE IF NOT EXISTS HRZN_DB;
CREATE SCHEMA IF NOT EXISTS HRZN_DB.RAW;
CREATE SCHEMA IF NOT EXISTS HRZN_DB.TRANSFORM;
CREATE SCHEMA IF NOT EXISTS HRZN_DB.ANALYTICS;

-- ============================================================
-- STEP 2: RAW Layer - Iceberg tables from Postgres catalog
-- ============================================================
USE SCHEMA HRZN_DB.RAW;

CREATE OR REPLACE ICEBERG TABLE ORDERS_ICEBERG
    CATALOG = 'pg_snowflake_catalog'
    CATALOG_TABLE_NAME = 'orders_iceberg';

CREATE OR REPLACE ICEBERG TABLE CUSTOMERS_ICEBERG
    CATALOG = 'pg_snowflake_catalog'
    CATALOG_TABLE_NAME = 'customers_iceberg';

CREATE OR REPLACE ICEBERG TABLE PRODUCTS_ICEBERG
    CATALOG = 'pg_snowflake_catalog'
    CATALOG_TABLE_NAME = 'products_iceberg';

CREATE OR REPLACE ICEBERG TABLE ORDER_ITEMS_ICEBERG
    CATALOG = 'pg_snowflake_catalog'
    CATALOG_TABLE_NAME = 'order_items_iceberg';

-- ============================================================
-- STEP 3: TRANSFORM Layer - Dynamic Tables
-- ============================================================
USE SCHEMA HRZN_DB.TRANSFORM;

CREATE OR REPLACE DYNAMIC TABLE DT_ORDER_DETAILS
    TARGET_LAG = '1 hour'
    WAREHOUSE = GENERIC
AS
SELECT
    o.ORDER_ID,
    o.ORDER_DATE,
    o.ORDER_STATUS,
    o.QUANTITY,
    o.UNIT_PRICE,
    o.TOTAL_PRICE,
    o.MFG_PLANT_ID,
    o.CUSTOMER_ID,
    c.CUSTOMER_NAME,
    c.CUSTOMER_REGION,
    c.CUSTOMER_SEGMENT,
    o.PRODUCT_ID,
    p.PRODUCT_NAME,
    p.PRODUCT_CATEGORY,
    p.PRODUCT_BRAND,
    p.UNIT_COST,
    (o.UNIT_PRICE - p.UNIT_COST) AS MARGIN_PER_UNIT,
    (o.UNIT_PRICE - p.UNIT_COST) * o.QUANTITY AS TOTAL_MARGIN
FROM HRZN_DB.RAW.ORDERS_ICEBERG o
LEFT JOIN HRZN_DB.RAW.CUSTOMERS_ICEBERG c ON o.CUSTOMER_ID = c.CUSTOMER_ID
LEFT JOIN HRZN_DB.RAW.PRODUCTS_ICEBERG p ON o.PRODUCT_ID = p.PRODUCT_ID;

CREATE OR REPLACE DYNAMIC TABLE DT_CUSTOMER_SUMMARY
    TARGET_LAG = '1 hour'
    WAREHOUSE = GENERIC
AS
SELECT
    c.CUSTOMER_ID,
    c.CUSTOMER_NAME,
    c.CUSTOMER_REGION,
    c.CUSTOMER_SEGMENT,
    COUNT(o.ORDER_ID) AS TOTAL_ORDERS,
    SUM(o.TOTAL_PRICE) AS TOTAL_SPEND,
    AVG(o.TOTAL_PRICE) AS AVG_ORDER_VALUE,
    MIN(o.ORDER_DATE) AS FIRST_ORDER_DATE,
    MAX(o.ORDER_DATE) AS LAST_ORDER_DATE,
    COUNT(DISTINCT o.PRODUCT_ID) AS UNIQUE_PRODUCTS_ORDERED
FROM HRZN_DB.RAW.CUSTOMERS_ICEBERG c
LEFT JOIN HRZN_DB.RAW.ORDERS_ICEBERG o ON c.CUSTOMER_ID = o.CUSTOMER_ID
GROUP BY c.CUSTOMER_ID, c.CUSTOMER_NAME, c.CUSTOMER_REGION, c.CUSTOMER_SEGMENT;

-- ============================================================
-- STEP 4: ANALYTICS Layer - Final View
-- ============================================================
USE SCHEMA HRZN_DB.ANALYTICS;

CREATE OR REPLACE VIEW V_ORDER_ANALYTICS AS
SELECT
    d.ORDER_ID,
    d.ORDER_DATE,
    d.ORDER_STATUS,
    d.QUANTITY,
    d.UNIT_PRICE,
    d.TOTAL_PRICE,
    d.MFG_PLANT_ID,
    d.CUSTOMER_ID,
    d.CUSTOMER_NAME,
    d.CUSTOMER_REGION,
    d.CUSTOMER_SEGMENT,
    d.PRODUCT_ID,
    d.PRODUCT_NAME,
    d.PRODUCT_CATEGORY,
    d.PRODUCT_BRAND,
    d.UNIT_COST,
    d.MARGIN_PER_UNIT,
    d.TOTAL_MARGIN,
    cs.TOTAL_ORDERS AS CUSTOMER_LIFETIME_ORDERS,
    cs.TOTAL_SPEND AS CUSTOMER_LIFETIME_SPEND,
    cs.AVG_ORDER_VALUE AS CUSTOMER_AVG_ORDER_VALUE,
    cs.FIRST_ORDER_DATE AS CUSTOMER_FIRST_ORDER,
    cs.LAST_ORDER_DATE AS CUSTOMER_LAST_ORDER,
    cs.UNIQUE_PRODUCTS_ORDERED AS CUSTOMER_UNIQUE_PRODUCTS
FROM HRZN_DB.TRANSFORM.DT_ORDER_DETAILS d
LEFT JOIN HRZN_DB.TRANSFORM.DT_CUSTOMER_SUMMARY cs ON d.CUSTOMER_ID = cs.CUSTOMER_ID;

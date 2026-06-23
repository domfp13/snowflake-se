USE ROLE ACCOUNTADMIN;

-- Run this in Snowflake (not in your Postgres session via DataGrip)
SHOW POSTGRES INSTANCES;

ALTER POSTGRES INSTANCE PG_SNOWFLAKE_PROD SUSPEND;
ALTER POSTGRES INSTANCE PG_SNOWFLAKE_PROD RESUME;

-- NOTE: The instance compute size must be changed (e.g. upgraded or downgraded) in order for Snowflake
-- to apply the latest platform features and updates to the Postgres instance. Snowflake rolls out
-- new features tied to compute family changes, so resizing the instance triggers the upgrade process.

ALTER POSTGRES INSTANCE PG_SNOWFLAKE_PROD 
  SET COMPUTE_FAMILY = 'STANDARD_L' 
  APPLY IMMEDIATELY;

ALTER POSTGRES INSTANCE PG_SNOWFLAKE_PROD 
  SET COMPUTE_FAMILY = 'STANDARD_M' 
  APPLY IMMEDIATELY;

-- ********** In Postgres (DataGrip): create an Iceberg table
DESCRIBE POSTGRES INSTANCE PG_SNOWFLAKE_PROD;

-- Create the Iceberg table with the same structure as orders
CREATE TABLE orders_iceberg (LIKE orders) USING iceberg;

-- Copy all data from the regular table to the Iceberg table
INSERT INTO orders_iceberg SELECT * FROM orders;

SELECT * FROM orders_iceberg;

-- ********** In Postgres (DataGrip): create an Iceberg table

-- Use ACCOUNTADMIN (required for CREATE INTEGRATION)
USE ROLE ACCOUNTADMIN;

-- Step 1: Create catalog integration (account-level object)
-- This tells Snowflake how to connect to your Postgres instance's Iceberg catalog
CREATE OR REPLACE CATALOG INTEGRATION pg_snowflake_catalog
  CATALOG_SOURCE = SNOWFLAKE_POSTGRES
  TABLE_FORMAT = ICEBERG
  CATALOG_NAMESPACE = 'public'          -- The Postgres schema where orders_iceberg lives
  REST_CONFIG = (
    POSTGRES_INSTANCE = 'PG_SNOWFLAKE_PROD'  -- Your instance name
    CATALOG_NAME = 'postgres'                 -- The Postgres database name
    ACCESS_DELEGATION_MODE = VENDED_CREDENTIALS
  )
  ENABLED = TRUE;

GRANT USAGE ON INTEGRATION pg_snowflake_catalog TO ROLE SYSADMIN;

-- Step 2: Create the Iceberg table (lives in a Snowflake database.schema)
-- You need to choose where to put it. For example:
USE ROLE SYSADMIN;
USE DATABASE HRZN_DB;
USE SCHEMA PUBLIC;
USE WAREHOUSE GENERIC;

CREATE OR REPLACE ICEBERG TABLE orders_iceberg
    CATALOG = 'pg_snowflake_catalog'
    CATALOG_TABLE_NAME = 'orders_iceberg';

-- Step 3: Query it
SELECT * FROM orders_iceberg;

-- ============================================================
-- Service Account for BI tools (Sigma, Power BI, etc.)
-- ============================================================
USE ROLE ACCOUNTADMIN;

CREATE USER IF NOT EXISTS FINANCE_DASHBOARD_SVC
  PASSWORD = '<CHANGEME>'
  DEFAULT_ROLE = SYSADMIN
  DEFAULT_WAREHOUSE = GENERIC
  DEFAULT_NAMESPACE = HRZN_DB.ANALYTICS
  TYPE = SERVICE
  MUST_CHANGE_PASSWORD = FALSE
  COMMENT = 'Service account for BI tool connections (Sigma, Power BI)';

GRANT ROLE SYSADMIN TO USER FINANCE_DASHBOARD_SVC;

-- Exempt service account from MFA (required for driver-based BI connections)
CREATE OR REPLACE AUTHENTICATION POLICY HRZN_DB.PUBLIC.NO_MFA_SERVICE_POLICY
  MFA_ENROLLMENT = 'OPTIONAL'
  CLIENT_TYPES = ('SNOWFLAKE_UI', 'DRIVERS')
  COMMENT = 'Auth policy for service accounts - MFA not required';

ALTER USER FINANCE_DASHBOARD_SVC SET AUTHENTICATION POLICY HRZN_DB.PUBLIC.NO_MFA_SERVICE_POLICY;
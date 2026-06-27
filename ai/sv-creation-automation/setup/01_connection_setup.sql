/* ============================================================================
   Snowflake CoWork + dbt Cloud demo
   Script 01 - Connection setup (run this FIRST)
   ----------------------------------------------------------------------------
   Purpose: stand up the minimum Snowflake objects dbt Cloud needs to create a
   connection and run jobs:
     - Database  : COWORK_DBT
     - Warehouse : COWORK_DBT_WH
     - Role      : COWORK_DBT_ROLE   (the role dbt deploys with)
     - User      : COWORK_DBT_DEPLOY (key-pair auth, used by dbt Cloud jobs)

   Why a dedicated key-pair user? dbt Cloud scheduled JOBS run unattended and
   cannot use Snowflake SSO/OAuth (there is no human to complete the browser
   login). Key-pair auth is the recommended service credential. You keep using
   SSO for your own interactive (IDE) login; the jobs run as COWORK_DBT_DEPLOY.

   Execute the SQL yourself (this file is not auto-run). Run as a role that can
   create users/roles/warehouses (ACCOUNTADMIN is fine for a demo).
   ============================================================================ */


/* ----------------------------------------------------------------------------
   STEP 0 (LOCAL SHELL, not SQL): generate the RSA key pair
   ----------------------------------------------------------------------------
   Run these in your terminal in a safe directory. They create:
     - rsa_key.p8  -> PRIVATE key, paste into dbt Cloud credentials
     - rsa_key.pub -> PUBLIC key, register on the Snowflake user below

     openssl genrsa 2048 | openssl pkcs8 -topk8 -inform PEM -out rsa_key.p8 -nocrypt
     openssl rsa -in rsa_key.p8 -pubout -out rsa_key.pub

   Then print the public key body (everything BETWEEN the BEGIN/END lines, as a
   single line with no header/footer and no line breaks):

     cat rsa_key.pub

   Copy the base64 body (the MIIB...) and paste it into the ALTER USER statement
   in STEP 4 below.

   Keep rsa_key.p8 secret. Do NOT commit either key file to git.
   ---------------------------------------------------------------------------- */


/* ----------------------------------------------------------------------------
   STEP 1 - Database + warehouse  (run as SYSADMIN or ACCOUNTADMIN)
   ---------------------------------------------------------------------------- */
USE ROLE SYSADMIN;

CREATE DATABASE IF NOT EXISTS COWORK_DBT
  COMMENT = 'Snowflake CoWork + dbt Cloud partner demo';

-- CREATE WAREHOUSE IF NOT EXISTS COWORK_DBT_WH
--   WAREHOUSE_SIZE = 'XSMALL'
--   AUTO_SUSPEND   = 60
--   AUTO_RESUME    = TRUE
--   INITIALLY_SUSPENDED = TRUE
--   COMMENT = 'Warehouse for dbt Cloud jobs and demo queries';

CREATE WAREHOUSE IF NOT EXISTS GENERIC
  WAREHOUSE_TYPE  = 'ADAPTIVE'
  WAREHOUSE_SIZE  = 'XSMALL'
  AUTO_SUSPEND    = 60
  AUTO_RESUME     = TRUE
  INITIALLY_SUSPENDED = TRUE
  COMMENT = 'Adaptive warehouse for general-purpose workloads';

/* ----------------------------------------------------------------------------
   STEP 2 - Deployment role  (run as SECURITYADMIN or ACCOUNTADMIN)
   ---------------------------------------------------------------------------- */
-- USE ROLE SECURITYADMIN;

-- CREATE ROLE IF NOT EXISTS COWORK_DBT_ROLE
--   COMMENT = 'Role dbt Cloud uses to build models in COWORK_DBT';

-- -- Let this role use the warehouse
-- GRANT USAGE, OPERATE ON WAREHOUSE GENERIC TO ROLE COWORK_DBT_ROLE;

-- -- Give the role full control of the demo database so dbt can create schemas/objects
-- GRANT USAGE ON DATABASE COWORK_DBT TO ROLE COWORK_DBT_ROLE;
-- GRANT CREATE SCHEMA ON DATABASE COWORK_DBT TO ROLE COWORK_DBT_ROLE;

-- -- Apply to current and future schemas in the database
-- GRANT ALL PRIVILEGES ON ALL SCHEMAS IN DATABASE COWORK_DBT TO ROLE COWORK_DBT_ROLE;
-- GRANT ALL PRIVILEGES ON FUTURE SCHEMAS IN DATABASE COWORK_DBT TO ROLE COWORK_DBT_ROLE;

-- -- Apply to current and future tables/views so dbt can rebuild freely
-- GRANT ALL PRIVILEGES ON ALL TABLES IN DATABASE COWORK_DBT TO ROLE COWORK_DBT_ROLE;
-- GRANT ALL PRIVILEGES ON FUTURE TABLES IN DATABASE COWORK_DBT TO ROLE COWORK_DBT_ROLE;
-- GRANT ALL PRIVILEGES ON ALL VIEWS IN DATABASE COWORK_DBT TO ROLE COWORK_DBT_ROLE;
-- GRANT ALL PRIVILEGES ON FUTURE VIEWS IN DATABASE COWORK_DBT TO ROLE COWORK_DBT_ROLE;

-- -- So you can see/manage everything the deploy user creates, give the role to your admin
-- GRANT ROLE COWORK_DBT_ROLE TO ROLE SYSADMIN;

/* ----------------------------------------------------------------------------
   STEP 3 - Deployment user  (run as USERADMIN or ACCOUNTADMIN)
   ---------------------------------------------------------------------------- */
-- USE ROLE USERADMIN;

-- CREATE USER IF NOT EXISTS COWORK_DBT_DEPLOY
--   DEFAULT_ROLE      = COWORK_DBT_ROLE
--   DEFAULT_WAREHOUSE = GENERIC
--   DEFAULT_NAMESPACE = COWORK_DBT
--   TYPE              = SERVICE          -- service account: no password, key-pair only
--   COMMENT           = 'dbt Cloud deployment user (key-pair auth)';

-- USE ROLE SECURITYADMIN;
-- GRANT ROLE COWORK_DBT_ROLE TO USER COWORK_DBT_DEPLOY;

/* ----------------------------------------------------------------------------
   STEP 4 - Attach the PUBLIC key to the user
   ----------------------------------------------------------------------------
   Generate the key pair on Unix/Linux/macOS (run in your terminal):

     # 1) Private key (PKCS#8, unencrypted) -> rsa_key.p8  (paste into dbt Cloud)
     openssl genrsa 2048 | openssl pkcs8 -topk8 -inform PEM -out rsa_key.p8 -nocrypt

     # 2) Public key -> rsa_key.pub  (register on the Snowflake user, below)
     openssl rsa -in rsa_key.p8 -pubout -out rsa_key.pub

     # 3) Print the public key body as ONE line, header/footer and newlines stripped,
     #    ready to paste into the ALTER USER statement below:
     grep -v 'PUBLIC KEY' rsa_key.pub | tr -d '\n'; echo

   (Optional) encrypted private key instead of step 1 - dbt Cloud will then ask
   for the passphrase:
     openssl genrsa 2048 | openssl pkcs8 -topk8 -inform PEM -out rsa_key.p8 -v2 aes-256-cbc

   Replace the placeholder below with the base64 body from rsa_key.pub:
   everything between -----BEGIN PUBLIC KEY----- and -----END PUBLIC KEY-----,
   as ONE line with no spaces or newlines.
   ---------------------------------------------------------------------------- */
-- USE ROLE USERADMIN;

-- ALTER USER COWORK_DBT_DEPLOY SET RSA_PUBLIC_KEY = '<USE ROLE COWORK_DBT_ROLE;>';

/* ----------------------------------------------------------------------------
   STEP 5 - Verify
   ---------------------------------------------------------------------------- */
-- Confirms the public key fingerprint is registered (RSA_PUBLIC_KEY_FP is populated)
-- DESCRIBE USER COWORK_DBT_DEPLOY;

-- -- Sanity check the role can be assumed and the warehouse/db resolve
-- USE ROLE COWORK_DBT_ROLE;
-- USE WAREHOUSE COWORK_DBT_WH;
-- USE DATABASE COWORK_DBT;
-- SELECT CURRENT_USER(), CURRENT_ROLE(), CURRENT_WAREHOUSE(), CURRENT_DATABASE();


/* ============================================================================
   dbt Cloud connection values (enter these in the connection screen):
     Authentication : Key Pair
     Account        : <YOUR_SNOWFLAKE_ACCOUNT>
     Database       : COWORK_DBT
     Warehouse      : COWORK_DBT_WH
     Role           : COWORK_DBT_ROLE
     Username       : COWORK_DBT_DEPLOY
     Private key    : contents of rsa_key.p8  (paste full PEM, including the
                      -----BEGIN PRIVATE KEY----- / -----END PRIVATE KEY----- lines)
     Passphrase     : (leave blank - key generated with -nocrypt)
   ============================================================================ */

# Snowflake Postgres + pg_lake Pipeline Demo

End-to-end data pipeline demonstrating Snowflake Postgres with managed Iceberg tables,
external lineage, dynamic tables, semantic views, and a Cortex Agent.

## Architecture

```
PostgreSQL (pg_lake)          Snowflake
┌──────────────────┐    ┌─────────────────────────────────────────────────┐
│ orders_iceberg   │    │  RAW (Iceberg)     TRANSFORM (DT)   ANALYTICS  │
│ customers_iceberg│───>│  ORDERS_ICEBERG    DT_ORDER_DETAILS  V_ORDER   │
│ products_iceberg │    │  CUSTOMERS_ICEBERG DT_CUSTOMER_SUM   _ANALYTICS│
│ order_items_ice  │    │  PRODUCTS_ICEBERG                              │
└──────────────────┘    │  ORDER_ITEMS_ICE                               │
                        └─────────────────────────────────────────────────┘
                                                       │
                                              ┌────────┴────────┐
                                              │                 │
                                    Semantic View        Cortex Agent
                                    (Cortex Analyst)     (Snowflake Intelligence)
                                              │
                                     ┌────────┴────────┐
                                     │                 │
                                Power BI Report   Streamlit Dashboard
                                (ext. lineage)    (Streamlit-in-Snowflake)
```

## Prerequisites

- Snowflake account (Enterprise Edition or higher for external lineage)
- Snowflake Postgres instance (`STANDARD_M` or larger)
- A SQL client for Postgres (DataGrip, psql, etc.)
- `curl` for registering external lineage
- A Personal Access Token (PAT) with `INGEST LINEAGE` privilege

## Execution Order

### Step 1: Postgres Instance Setup

**File:** `01_test_presetup.sql`
**Run in:** Snowflake (Snowsight / SnowSQL)
**Role:** ACCOUNTADMIN

Creates the Postgres instance, enables pg_lake (via compute resize), and sets up
the catalog integration.

```sql
-- Key operations:
-- 1. Resize instance to trigger pg_lake enablement
-- 2. Create catalog integration (CATALOG_SOURCE = SNOWFLAKE_POSTGRES)
-- 3. Grant USAGE to SYSADMIN
```

### Step 2: Postgres Iceberg Tables

**File:** `02_pipeline_postgres.sql`
**Run in:** PostgreSQL (DataGrip connected to PG_SNOWFLAKE_PROD)
**Database:** `postgres`

Creates the Iceberg tables with synthetic data:
- `customers_iceberg` (40 rows) - automotive, aerospace, industrial customers
- `products_iceberg` (40 rows) - manufactured parts and components
- `orders_iceberg` (pre-existing) - order transactions
- `order_items_iceberg` (49 rows) - line-level order details

### Step 3: Snowflake Pipeline (RAW -> TRANSFORM -> ANALYTICS)

**File:** `03_pipeline_snowflake.sql`
**Run in:** Snowflake (Snowsight / SnowSQL)
**Role:** SYSADMIN

Creates the multi-layer pipeline:
1. **RAW schema** - Iceberg tables linked to Postgres via catalog integration
2. **TRANSFORM schema** - Dynamic tables (`DT_ORDER_DETAILS`, `DT_CUSTOMER_SUMMARY`) with 1-hour lag
3. **ANALYTICS schema** - Final denormalized view (`V_ORDER_ANALYTICS`)

### Step 4: Semantic View + Cortex Agent

**File:** `04_semantic_view_and_agent.sql`
**Run in:** Snowflake (Snowsight / SnowSQL)
**Role:** SYSADMIN (semantic view), ACCOUNTADMIN (grants)

Creates:
- Semantic view with facts, dimensions, metrics, AI instructions
- Cortex Agent with `cortex_analyst_text_to_sql` + `data_to_chart` tools

### Step 5: External Lineage Registration

**File:** `05_register_lineage.sh`
**Run in:** Terminal (bash/zsh)
**Prerequisite:** PAT token with INGEST LINEAGE privilege

Registers OpenLineage events for:
- **Upstream:** PostgreSQL tables -> Snowflake RAW tables (shows Postgres icon)
- **Downstream:** Analytics view -> Power BI Report (shows Power BI icon)

```bash
export SNOWFLAKE_PAT="<your-pat-token>"
export SNOWFLAKE_ACCOUNT="<your-account-identifier>"
./05_register_lineage.sh
```

### Step 6: Streamlit Dashboard

**File:** `06_streamlit_app.py`
**Deployed as:** `HRZN_DB.ANALYTICS.ORDER_ANALYTICS_DASHBOARD`

Upload and create the Streamlit-in-Snowflake app:

```sql
USE ROLE SYSADMIN;
CREATE STAGE IF NOT EXISTS HRZN_DB.ANALYTICS.STREAMLIT_STAGE;

PUT file:///path/to/06_streamlit_app.py @HRZN_DB.ANALYTICS.STREAMLIT_STAGE/
    AUTO_COMPRESS=FALSE OVERWRITE=TRUE;

CREATE OR REPLACE STREAMLIT HRZN_DB.ANALYTICS.ORDER_ANALYTICS_DASHBOARD
  ROOT_LOCATION = '@HRZN_DB.ANALYTICS.STREAMLIT_STAGE'
  MAIN_FILE = '06_streamlit_app.py'
  QUERY_WAREHOUSE = GENERIC;
```

## Files

| # | File | Purpose | Runs In |
|---|------|---------|---------|
| 1 | `01_test_presetup.sql` | Instance setup, pg_lake enablement, catalog integration | Snowflake |
| 2 | `02_pipeline_postgres.sql` | Create Iceberg tables with synthetic data | PostgreSQL |
| 3 | `03_pipeline_snowflake.sql` | RAW/TRANSFORM/ANALYTICS schemas + objects | Snowflake |
| 4 | `04_semantic_view_and_agent.sql` | Semantic view + Cortex Agent | Snowflake |
| 5 | `05_register_lineage.sh` | External lineage (upstream + downstream) | Terminal |
| 6 | `06_streamlit_app.py` | Dashboard app (Streamlit-in-Snowflake) | Snowflake |

## Key Learnings

- **pg_lake enablement:** New instances may need a compute resize (e.g. M->L->M) to pick up `shared_preload_libraries` updates.
- **Iceberg constraints:** `CREATE TABLE ... USING iceberg` does not support PRIMARY KEY, NOT NULL, DEFAULT, or SERIAL.
- **Lineage namespaces:** Use `postgresql://` (not `postgres://`) to get the Postgres icon in Snowsight lineage.
- **Lineage facets:** Use `"datasetType"` for output nodes (e.g. `"REPORT"`) and `"sourceType"` for input nodes (e.g. `"POSTGRESQL"`).
- **Streamlit-in-Snowflake:** Use `get_active_session()` from `snowflake.snowpark.context`, not `st.connection()`.
- **Auth for lineage API:** Use `Authorization: Bearer <PAT>`, not `Snowflake Token="..."`.

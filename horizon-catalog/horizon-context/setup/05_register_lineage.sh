#!/bin/bash
# =============================================================================
# External Lineage Registration
# Registers upstream (PostgreSQL -> RAW) and downstream (ANALYTICS -> Power BI, Sigma)
# lineage events for the pg_lake Iceberg pipeline.
# =============================================================================
#
# Usage:
#   export SNOWFLAKE_PAT="<your-personal-access-token>"
#   export SNOWFLAKE_ACCOUNT="<your-account-identifier>"  # e.g. MYORG-MYACCOUNT
#   ./register_lineage.sh
#
# Prerequisites:
#   - INGEST LINEAGE privilege granted to the user owning the PAT
#   - curl installed
# =============================================================================

set -euo pipefail

# --- Configuration (from environment) ---
if [ -z "${SNOWFLAKE_PAT:-}" ]; then
  echo "ERROR: SNOWFLAKE_PAT environment variable is not set."
  echo "  export SNOWFLAKE_PAT=\"<your-personal-access-token>\""
  exit 1
fi

if [ -z "${SNOWFLAKE_ACCOUNT:-}" ]; then
  echo "ERROR: SNOWFLAKE_ACCOUNT environment variable is not set."
  echo "  export SNOWFLAKE_ACCOUNT=\"<your-account-identifier>\""
  exit 1
fi

TOKEN="$SNOWFLAKE_PAT"
ACCOUNT="$SNOWFLAKE_ACCOUNT"
ENDPOINT="https://${ACCOUNT}.snowflakecomputing.com/api/v2/lineage/external-lineage"

# Common headers
HEADERS=(
  -H "Content-Type: application/json"
  -H "Authorization: Bearer $TOKEN"
  -H "Accept: application/json"
  -H "User-Agent: pg_lake_lineage/1.0"
)

# Helper function to send a lineage event
send_lineage() {
  local description="$1"
  local payload="$2"

  echo -n "  $description... "
  local status
  status=$(curl -s -o /dev/null -w "%{http_code}" -X POST "${HEADERS[@]}" -d "$payload" "$ENDPOINT")
  if [ "$status" = "200" ]; then
    echo "OK ($status)"
  else
    echo "FAILED ($status)"
  fi
}

# =============================================================================
# UPSTREAM: PostgreSQL -> HRZN_DB.RAW (Iceberg tables)
# Uses postgresql:// namespace to show Postgres icon in Snowsight lineage
# =============================================================================
echo "=== Registering UPSTREAM lineage (PostgreSQL -> RAW) ==="

send_lineage "customers_iceberg -> RAW.CUSTOMERS_ICEBERG" '{
  "eventType": "COMPLETE",
  "eventTime": "2026-06-22T12:00:00.000Z",
  "job": {"namespace": "snowflake_postgres", "name": "pg_lake_sync_customers"},
  "run": {"runId": "c1000001-0000-0000-0000-000000000001"},
  "producer": "https://github.com/OpenLineage/OpenLineage/blob/v1-0-0/client",
  "schemaURL": "https://openlineage.io/spec/0-0-1/OpenLineage.json",
  "inputs": [{
    "namespace": "postgresql://PG_SNOWFLAKE_PROD",
    "name": "postgres.public.CUSTOMERS_ICEBERG",
    "facets": {"datasetType": {"datasetType": "TABLE"}, "sourceType": {"sourceType": "POSTGRESQL"}}
  }],
  "outputs": [{"namespace": "snowflake://'"$ACCOUNT"'", "name": "HRZN_DB.RAW.CUSTOMERS_ICEBERG"}]
}'

send_lineage "products_iceberg -> RAW.PRODUCTS_ICEBERG" '{
  "eventType": "COMPLETE",
  "eventTime": "2026-06-22T12:00:00.000Z",
  "job": {"namespace": "snowflake_postgres", "name": "pg_lake_sync_products"},
  "run": {"runId": "c1000001-0000-0000-0000-000000000002"},
  "producer": "https://github.com/OpenLineage/OpenLineage/blob/v1-0-0/client",
  "schemaURL": "https://openlineage.io/spec/0-0-1/OpenLineage.json",
  "inputs": [{
    "namespace": "postgresql://PG_SNOWFLAKE_PROD",
    "name": "postgres.public.PRODUCTS_ICEBERG",
    "facets": {"datasetType": {"datasetType": "TABLE"}, "sourceType": {"sourceType": "POSTGRESQL"}}
  }],
  "outputs": [{"namespace": "snowflake://'"$ACCOUNT"'", "name": "HRZN_DB.RAW.PRODUCTS_ICEBERG"}]
}'

send_lineage "order_items_iceberg -> RAW.ORDER_ITEMS_ICEBERG" '{
  "eventType": "COMPLETE",
  "eventTime": "2026-06-22T12:00:00.000Z",
  "job": {"namespace": "snowflake_postgres", "name": "pg_lake_sync_order_items"},
  "run": {"runId": "c1000001-0000-0000-0000-000000000003"},
  "producer": "https://github.com/OpenLineage/OpenLineage/blob/v1-0-0/client",
  "schemaURL": "https://openlineage.io/spec/0-0-1/OpenLineage.json",
  "inputs": [{
    "namespace": "postgresql://PG_SNOWFLAKE_PROD",
    "name": "postgres.public.ORDER_ITEMS_ICEBERG",
    "facets": {"datasetType": {"datasetType": "TABLE"}, "sourceType": {"sourceType": "POSTGRESQL"}}
  }],
  "outputs": [{"namespace": "snowflake://'"$ACCOUNT"'", "name": "HRZN_DB.RAW.ORDER_ITEMS_ICEBERG"}]
}'

send_lineage "orders_iceberg -> RAW.ORDERS_ICEBERG" '{
  "eventType": "COMPLETE",
  "eventTime": "2026-06-22T12:00:00.000Z",
  "job": {"namespace": "snowflake_postgres", "name": "pg_lake_sync_orders"},
  "run": {"runId": "c1000001-0000-0000-0000-000000000004"},
  "producer": "https://github.com/OpenLineage/OpenLineage/blob/v1-0-0/client",
  "schemaURL": "https://openlineage.io/spec/0-0-1/OpenLineage.json",
  "inputs": [{
    "namespace": "postgresql://PG_SNOWFLAKE_PROD",
    "name": "postgres.public.ORDERS_ICEBERG",
    "facets": {"datasetType": {"datasetType": "TABLE"}, "sourceType": {"sourceType": "POSTGRESQL"}}
  }],
  "outputs": [{"namespace": "snowflake://'"$ACCOUNT"'", "name": "HRZN_DB.RAW.ORDERS_ICEBERG"}]
}'

echo ""

# =============================================================================
# DOWNSTREAM: HRZN_DB.ANALYTICS.V_ORDER_ANALYTICS -> Power BI Report
# Uses powerbi:// namespace to show Power BI icon in Snowsight lineage
# =============================================================================
echo "=== Registering DOWNSTREAM lineage (ANALYTICS -> Power BI) ==="

send_lineage "V_ORDER_ANALYTICS -> Power BI Report" '{
  "eventType": "COMPLETE",
  "eventTime": "2026-06-22T13:00:00.000Z",
  "job": {"namespace": "powerbi://app.powerbi.com", "name": "Order_Analytics_Report_Refresh"},
  "run": {"runId": "c2d3e4f5-a6b7-8901-cdef-234567890abc"},
  "producer": "https://github.com/OpenLineage/OpenLineage/blob/v1-0-0/client",
  "schemaURL": "https://openlineage.io/spec/0-0-1/OpenLineage.json",
  "inputs": [{"namespace": "snowflake://'"$ACCOUNT"'", "name": "HRZN_DB.ANALYTICS.V_ORDER_ANALYTICS"}],
  "outputs": [{"namespace": "powerbi://app.powerbi.com", "name": "Order Analytics Report", "facets": {"datasetType": {"datasetType": "REPORT"}}}]
}'

# =============================================================================
# DOWNSTREAM: HRZN_DB.ANALYTICS.ORDER_ANALYTICS_SEMANTIC_VIEW -> Sigma Workbook
# Uses sigma:// namespace to show Sigma icon in Snowsight lineage
# =============================================================================
echo "=== Registering DOWNSTREAM lineage (Semantic View -> Sigma Computing) ==="

send_lineage "ORDER_ANALYTICS_SEMANTIC_VIEW -> Sigma Computing Workbook" '{
  "eventType": "COMPLETE",
  "eventTime": "2026-06-23T10:00:00.000Z",
  "job": {"namespace": "sigma://app.sigmacomputing.com", "name": "Order_Analytics_Sigma_Workbook_Refresh"},
  "run": {"runId": "d3e4f5a6-b7c8-9012-def0-345678901bce"},
  "producer": "https://github.com/OpenLineage/OpenLineage/blob/v1-0-0/client",
  "schemaURL": "https://openlineage.io/spec/0-0-1/OpenLineage.json",
  "inputs": [{"namespace": "snowflake://'"$ACCOUNT"'", "name": "HRZN_DB.ANALYTICS.ORDER_ANALYTICS_SEMANTIC_VIEW"}],
  "outputs": [{"namespace": "sigma://app.sigmacomputing.com", "name": "Order Analytics - Sigma Workbook", "facets": {"datasetType": {"datasetType": "REPORT"}}}]
}'

echo ""
echo "=== Done! Check Snowsight lineage graph for HRZN_DB tables. ==="

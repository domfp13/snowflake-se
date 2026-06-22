-- ============================================================
-- SEMANTIC VIEW + CORTEX AGENT
-- Order Analytics pipeline: PostgreSQL -> RAW -> TRANSFORM -> ANALYTICS -> Semantic View -> Agent
-- ============================================================

USE ROLE SYSADMIN;
USE DATABASE HRZN_DB;
USE SCHEMA ANALYTICS;
USE WAREHOUSE GENERIC;

-- ============================================================
-- STEP 1: SEMANTIC VIEW
-- ============================================================

CREATE OR REPLACE SEMANTIC VIEW HRZN_DB.ANALYTICS.ORDER_ANALYTICS_SEMANTIC_VIEW

  TABLES (
    ORD AS HRZN_DB.ANALYTICS.V_ORDER_ANALYTICS PRIMARY KEY (ORDER_ID)
      COMMENT = 'Order analytics view combining orders, customers, and products from PostgreSQL Iceberg tables'
  )

  FACTS (
    ORD.QUANTITY AS QUANTITY
      WITH SYNONYMS = ('qty', 'units', 'volume')
      COMMENT = 'Number of units in the order line',
    ORD.UNIT_PRICE AS UNIT_PRICE
      WITH SYNONYMS = ('price', 'selling price')
      COMMENT = 'Selling price per unit',
    ORD.TOTAL_PRICE AS TOTAL_PRICE
      WITH SYNONYMS = ('revenue', 'sales amount', 'order value')
      COMMENT = 'Total revenue for the order line (quantity x unit price)',
    ORD.UNIT_COST AS UNIT_COST
      WITH SYNONYMS = ('cost', 'COGS per unit')
      COMMENT = 'Cost per unit from product catalog',
    ORD.MARGIN_PER_UNIT AS MARGIN_PER_UNIT
      WITH SYNONYMS = ('unit margin', 'profit per unit')
      COMMENT = 'Profit per unit (unit_price - unit_cost)',
    ORD.TOTAL_MARGIN AS TOTAL_MARGIN
      WITH SYNONYMS = ('margin', 'gross profit', 'profit')
      COMMENT = 'Total margin for the order line (margin_per_unit x quantity)',
    ORD.CUSTOMER_LIFETIME_ORDERS AS CUSTOMER_LIFETIME_ORDERS
      WITH SYNONYMS = ('lifetime orders', 'total orders by customer')
      COMMENT = 'Total number of orders placed by this customer',
    ORD.CUSTOMER_LIFETIME_SPEND AS CUSTOMER_LIFETIME_SPEND
      WITH SYNONYMS = ('lifetime spend', 'CLV', 'customer value')
      COMMENT = 'Total spend by this customer across all orders',
    ORD.CUSTOMER_AVG_ORDER_VALUE AS CUSTOMER_AVG_ORDER_VALUE
      WITH SYNONYMS = ('AOV', 'average order value')
      COMMENT = 'Average order value for this customer',
    ORD.CUSTOMER_UNIQUE_PRODUCTS AS CUSTOMER_UNIQUE_PRODUCTS
      WITH SYNONYMS = ('unique products', 'product diversity')
      COMMENT = 'Number of distinct products ordered by this customer'
  )

  DIMENSIONS (
    ORD.ORDER_DATE AS ORDER_DATE
      WITH SYNONYMS = ('date', 'order date', 'purchase date')
      COMMENT = 'Date when the order was placed',
    ORD.ORDER_STATUS AS ORDER_STATUS
      WITH SYNONYMS = ('status', 'order state')
      COMMENT = 'Current status of the order',
    ORD.MFG_PLANT_ID AS MFG_PLANT_ID
      WITH SYNONYMS = ('plant', 'manufacturing plant', 'factory')
      COMMENT = 'Manufacturing plant identifier',
    ORD.CUSTOMER_NAME AS CUSTOMER_NAME
      WITH SYNONYMS = ('customer', 'buyer', 'client')
      COMMENT = 'Name of the customer',
    ORD.CUSTOMER_REGION AS CUSTOMER_REGION
      WITH SYNONYMS = ('region', 'geography', 'market')
      COMMENT = 'Geographic region of the customer',
    ORD.CUSTOMER_SEGMENT AS CUSTOMER_SEGMENT
      WITH SYNONYMS = ('segment', 'customer type')
      COMMENT = 'Business segment of the customer (Enterprise, SMB, etc.)',
    ORD.PRODUCT_NAME AS PRODUCT_NAME
      WITH SYNONYMS = ('product', 'item', 'SKU')
      COMMENT = 'Name of the product',
    ORD.PRODUCT_CATEGORY AS PRODUCT_CATEGORY
      WITH SYNONYMS = ('category', 'product type')
      COMMENT = 'Product category grouping',
    ORD.PRODUCT_BRAND AS PRODUCT_BRAND
      WITH SYNONYMS = ('brand', 'manufacturer')
      COMMENT = 'Brand or manufacturer of the product',
    ORD.CUSTOMER_FIRST_ORDER AS CUSTOMER_FIRST_ORDER
      WITH SYNONYMS = ('first purchase', 'acquisition date')
      COMMENT = 'Date of the customers first order',
    ORD.CUSTOMER_LAST_ORDER AS CUSTOMER_LAST_ORDER
      WITH SYNONYMS = ('last purchase', 'most recent order')
      COMMENT = 'Date of the customers most recent order'
  )

  METRICS (
    ORD.TOTAL_REVENUE AS SUM(ORD.TOTAL_PRICE)
      WITH SYNONYMS = ('total sales', 'revenue', 'gross sales')
      COMMENT = 'Sum of all order revenue',
    ORD.TOTAL_GROSS_MARGIN AS SUM(ORD.TOTAL_MARGIN)
      WITH SYNONYMS = ('total profit', 'gross margin', 'total gross profit')
      COMMENT = 'Sum of all order margins',
    ORD.TOTAL_UNITS_SOLD AS SUM(ORD.QUANTITY)
      WITH SYNONYMS = ('total units', 'total volume', 'units sold')
      COMMENT = 'Total number of units sold',
    ORD.ORDER_COUNT AS COUNT(ORD.ORDER_ID)
      WITH SYNONYMS = ('number of orders', 'order volume')
      COMMENT = 'Total number of orders',
    ORD.AVG_ORDER_VALUE AS AVG(ORD.TOTAL_PRICE)
      WITH SYNONYMS = ('average order value', 'AOV')
      COMMENT = 'Average revenue per order',
    ORD.AVG_MARGIN_PCT AS AVG(ORD.MARGIN_PER_UNIT / NULLIF(ORD.UNIT_PRICE, 0) * 100)
      WITH SYNONYMS = ('margin percentage', 'profit margin pct', 'gross margin pct')
      COMMENT = 'Average margin as a percentage of unit price'
  )

  COMMENT = 'Order analytics: revenue, margins, customer lifetime value, and product performance. Data sourced from PostgreSQL via Iceberg tables.'

  AI_SQL_GENERATION 'When computing margin percentage, always use NULLIF to avoid division by zero. Round monetary values to 2 decimal places. When grouping by time, use DATE_TRUNC on ORDER_DATE.'

  AI_QUESTION_CATEGORIZATION 'This semantic view answers questions about orders, revenue, margins, customers, and products. If the user asks about inventory, shipping, or returns, respond that this data is not available in this view.';

-- Grant privileges
USE ROLE ACCOUNTADMIN;
GRANT REFERENCES, SELECT ON SEMANTIC VIEW HRZN_DB.ANALYTICS.ORDER_ANALYTICS_SEMANTIC_VIEW TO ROLE SYSADMIN;

-- ============================================================
-- STEP 2: CORTEX AGENT (JSON Specification)
-- ============================================================

USE ROLE SYSADMIN;
USE DATABASE HRZN_DB;
USE SCHEMA ANALYTICS;
USE WAREHOUSE GENERIC;

CREATE OR REPLACE AGENT HRZN_DB.ANALYTICS.ORDER_ANALYTICS_AGENT
  COMMENT = 'Order Analytics Agent - answers questions about orders, revenue, margins, customers, and products sourced from PostgreSQL Iceberg tables'
  PROFILE = '{"display_name": "Order Analytics", "avatar": "CirclesAgentIcon", "color": "Blue"}'
  FROM SPECIFICATION $$
  {
    "models": {"orchestration": "auto"},
    "instructions": {
      "orchestration": "You are an order analytics assistant for a supply chain business. You help users explore order data, understand revenue and margin trends, analyze customer behavior, and evaluate product performance.\n\nDATA SOURCE:\nAll data originates from PostgreSQL Iceberg tables and flows through a managed pipeline: PostgreSQL -> RAW (Iceberg) -> TRANSFORM (Dynamic Tables) -> ANALYTICS (View).\n\nANALYSIS GUIDELINES:\n- When asked about revenue or sales, use the TOTAL_REVENUE metric.\n- When asked about profitability, use TOTAL_GROSS_MARGIN or AVG_MARGIN_PCT.\n- When comparing customers, consider CUSTOMER_LIFETIME_SPEND and CUSTOMER_LIFETIME_ORDERS for context.\n- When analyzing products, group by PRODUCT_CATEGORY or PRODUCT_BRAND.\n- When analyzing trends over time, use ORDER_DATE as the time dimension.\n- Always present results with clear formatting: tables for comparisons, summaries for single values.\n- Generate charts when presenting time-series or categorical comparisons.\n\nRESPONSE STYLE:\n- Be concise and data-driven.\n- Lead with the key insight, then provide supporting detail.\n- If the question is ambiguous, ask for clarification about the time period, customer segment, or product category.",
      "sample_questions": [
        {"question": "What is the total revenue and margin by product category?"},
        {"question": "Who are my top 5 customers by lifetime spend?"},
        {"question": "Show me the revenue trend over time by customer region."},
        {"question": "Which products have the highest margin percentage?"},
        {"question": "Compare revenue across customer segments."},
        {"question": "What is the average order value by product brand?"}
      ]
    },
    "tools": [
      {"tool_spec": {"type": "cortex_analyst_text_to_sql", "name": "order_analyst", "description": "Answers questions about orders, revenue, margins, customers, and products. Use this for any structured data question about the order analytics pipeline."}},
      {"tool_spec": {"type": "data_to_chart", "name": "data_to_chart", "description": "Generates charts and visualizations from query results. Use to create bar charts, line charts, and other visual representations of order data."}}
    ],
    "tool_resources": {
      "order_analyst": {
        "semantic_view": "HRZN_DB.ANALYTICS.ORDER_ANALYTICS_SEMANTIC_VIEW",
        "execution_environment": {"type": "warehouse", "warehouse": "GENERIC"}
      }
    }
  }
  $$;

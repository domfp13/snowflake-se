{{ config(materialized='semantic_view') }}
TABLES (
  orders AS {{ ref('fct_orders') }}
    PRIMARY KEY (order_id)
    WITH SYNONYMS ('sales', 'transactions')
    COMMENT = 'Fact table with one row per order, enriched with customer attributes',
  customers AS {{ ref('dim_customers') }}
    PRIMARY KEY (customer_id)
    COMMENT = 'Customer dimension with region and segment',
  refunds AS {{ ref('fct_refunds') }}
    PRIMARY KEY (refund_id)
    COMMENT = 'Refunds issued against completed orders'
)

RELATIONSHIPS (
  orders_to_customers AS orders (customer_id) REFERENCES customers,
  refunds_to_orders AS refunds (order_id) REFERENCES orders
)

FACTS (
  orders.order_amount AS order_amount
    COMMENT = 'Dollar amount of the order',
  refunds.refund_amount AS refund_amount
    COMMENT = 'Dollar amount refunded'
)

DIMENSIONS (
  customers.region AS region
    WITH SYNONYMS = ('geography', 'market')
    COMMENT = 'Customer region: North America, EMEA, APAC, LATAM',
  customers.segment AS segment
    WITH SYNONYMS = ('customer tier', 'size')
    COMMENT = 'Customer segment: Enterprise, Mid-Market, SMB',
  customers.customer_name AS customer_name
    COMMENT = 'Name of the customer',
  orders.order_date AS order_date
    COMMENT = 'Date the order was placed',
  orders.order_month AS DATE_TRUNC('month', order_date)
    COMMENT = 'Month the order was placed (truncated)',
  orders.order_quarter AS DATE_TRUNC('quarter', order_date)
    COMMENT = 'Quarter the order was placed',
  orders.status AS status
    COMMENT = 'Order status: COMPLETED, CANCELLED, PENDING',
  orders.is_completed AS is_completed
    COMMENT = 'Whether the order was completed (TRUE/FALSE)',
  refunds.refund_date AS refund_date
    COMMENT = 'Date the refund was issued'
)

METRICS (
  orders.total_revenue AS SUM(CASE WHEN orders.is_completed THEN orders.order_amount ELSE 0 END)
    COMMENT = 'Total gross revenue from completed orders',
  orders.completed_order_count AS COUNT(CASE WHEN orders.is_completed THEN orders.order_id END)
    COMMENT = 'Number of completed orders',
  orders.average_order_value AS AVG(CASE WHEN orders.is_completed THEN orders.order_amount END)
    COMMENT = 'Average value of a completed order',
  refunds.total_refunds AS SUM(refunds.refund_amount)
    COMMENT = 'Total amount refunded',
  refunds.refund_count AS COUNT(refunds.refund_id)
    COMMENT = 'Number of refunds issued',
  net_revenue AS (orders.total_revenue - refunds.total_refunds) * (0.9)
    COMMENT = 'Net revenue after subtracting refunds (governed metric)'
)

COMMENT = 'dbt-governed revenue semantic view for the CoWork + dbt Cloud demo. Metrics sourced from dbt project cowork_dbt.'

AI_SQL_GENERATION 'When computing revenue metrics, always filter for completed orders (is_completed = TRUE) unless the user explicitly asks for all orders. Round currency values to 2 decimal places. Use order_date for time-based grouping unless the user specifies refund_date.'

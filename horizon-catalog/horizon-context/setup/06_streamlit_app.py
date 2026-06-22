import streamlit as st
import pandas as pd
from snowflake.snowpark.context import get_active_session

st.set_page_config(page_title="Order Analytics", layout="wide")
st.title("Order Analytics Dashboard")
st.caption("Data sourced from PostgreSQL via Iceberg tables")

session = get_active_session()

# KPIs
kpis = session.sql("""
    SELECT 
        COUNT(*) AS total_orders,
        SUM(TOTAL_PRICE) AS total_revenue,
        SUM(TOTAL_MARGIN) AS total_margin,
        AVG(TOTAL_PRICE) AS avg_order_value
    FROM HRZN_DB.ANALYTICS.V_ORDER_ANALYTICS
""").to_pandas()

c1, c2, c3, c4 = st.columns(4)
c1.metric("Total Orders", f"{int(kpis['TOTAL_ORDERS'][0]):,}")
c2.metric("Total Revenue", f"${kpis['TOTAL_REVENUE'][0]:,.0f}")
c3.metric("Total Margin", f"${kpis['TOTAL_MARGIN'][0]:,.0f}")
c4.metric("Avg Order Value", f"${kpis['AVG_ORDER_VALUE'][0]:,.2f}")

st.divider()

col1, col2 = st.columns(2)

with col1:
    st.subheader("Revenue by Product Category")
    cat_df = session.sql("""
        SELECT PRODUCT_CATEGORY, SUM(TOTAL_PRICE) AS REVENUE
        FROM HRZN_DB.ANALYTICS.V_ORDER_ANALYTICS
        GROUP BY PRODUCT_CATEGORY
        ORDER BY REVENUE DESC
    """).to_pandas()
    st.bar_chart(cat_df, x="PRODUCT_CATEGORY", y="REVENUE")

with col2:
    st.subheader("Revenue by Customer Region")
    reg_df = session.sql("""
        SELECT CUSTOMER_REGION, SUM(TOTAL_PRICE) AS REVENUE
        FROM HRZN_DB.ANALYTICS.V_ORDER_ANALYTICS
        GROUP BY CUSTOMER_REGION
        ORDER BY REVENUE DESC
    """).to_pandas()
    st.bar_chart(reg_df, x="CUSTOMER_REGION", y="REVENUE")

st.divider()

col3, col4 = st.columns(2)

with col3:
    st.subheader("Top 10 Customers by Lifetime Spend")
    cust_df = session.sql("""
        SELECT DISTINCT CUSTOMER_NAME, CUSTOMER_LIFETIME_SPEND, CUSTOMER_SEGMENT
        FROM HRZN_DB.ANALYTICS.V_ORDER_ANALYTICS
        ORDER BY CUSTOMER_LIFETIME_SPEND DESC
        LIMIT 10
    """).to_pandas()
    st.dataframe(cust_df, use_container_width=True)

with col4:
    st.subheader("Margin % by Product Brand")
    brand_df = session.sql("""
        SELECT PRODUCT_BRAND, 
               AVG(MARGIN_PER_UNIT / NULLIF(UNIT_PRICE, 0) * 100) AS MARGIN_PCT
        FROM HRZN_DB.ANALYTICS.V_ORDER_ANALYTICS
        GROUP BY PRODUCT_BRAND
        ORDER BY MARGIN_PCT DESC
    """).to_pandas()
    st.bar_chart(brand_df, x="PRODUCT_BRAND", y="MARGIN_PCT")

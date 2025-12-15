import streamlit as st
import pandas as pd
import numpy as np
import altair as alt
from sqlalchemy import create_engine
import os

if "selected_category" not in st.session_state:
    st.session_state["selected_category"] = None

st.set_page_config(
    page_title="Olist E-Commerce Analytics Dashboard",
    layout="wide",
    initial_sidebar_state="expanded"
)

# --------DB CONNECTION----------
@st.cache_resource
def get_engine():
    db_url = os.getenv("DATABASE_URL")
    return create_engine(db_url)
    #return create_engine("postgresql://postgres:admin@localhost:5433/olist_db")

engine = get_engine()


st.title("Olist E-Commerce Analytics Dashboard")



# KPI METRICS
st.header("Key Performance Indicators")

kpi_query = """
SELECT 
    (select count(*) from products) AS total_products,
    (select count(distinct customer_unique_id) from customers) AS total_customers,
    (SELECT COUNT(*) FROM sellers) AS total_sellers,
    (SELECT CAST(SUM(price) AS DECIMAL(12,2)) FROM order_items) AS total_revenue
"""
kpi = pd.read_sql(kpi_query, engine)

def human_format(num):
    num = float(num)
    if num >= 1_000_000_000:
        return f"{num/1_000_000_000:.2f}B"
    elif num >= 1_000_000:
        return f"{num/1_000_000:.2f}M"
    elif num >= 1_000:
        return f"{num/1_000:.2f}K"
    else:
        return f"{num:.2f}"

col1, col2, col3, col4 = st.columns(4)

col1.metric("Total Products", int(kpi["total_products"][0]))
col2.metric("Total Customers", int(kpi["total_customers"][0]))
col3.metric("Total Sellers", int(kpi["total_sellers"][0]))
#col4.metric("Total Revenue", float(kpi["total_revenue"][0]))
col4.metric("Total Revenue", "$" + human_format(float(kpi["total_revenue"][0])))


# --------------------------- GRID ROW 1 ---------------------------
col1, col2 = st.columns(2)

with col1:
    
    # SALES OVER TIME (MONTHLY REVENUE)
    st.header("Revenue Over Time")

    revenue_query = """
    SELECT DATE_TRUNC('month', o.order_purchase_timestamp) AS month,
        SUM(oi.price) AS revenue
    FROM  orders o
    JOIN  order_items oi USING(order_id)
    GROUP BY month
    ORDER BY month;
    """
    df_revenue = pd.read_sql(revenue_query, engine)
    df_revenue["month"] = pd.to_datetime(df_revenue["month"])
    df_revenue["month"] = df_revenue["month"].dt.date

    chart2 = (
        alt.Chart(df_revenue)
        .mark_line(point=True)
        .encode(
            x=alt.X("month:T", title="Month"),
            y=alt.Y("revenue:Q", title="Revenue (BRL)")
        )
        .properties(height=450)
    )
    st.altair_chart(chart2, use_container_width=True)


with col2:
    st.header("State-wise Sales Analysis")

    state_query = """
    SELECT DISTINCT customer_state 
    FROM customers
    ORDER BY customer_state;
    """
    states = pd.read_sql(state_query, engine)

    selected_state = st.selectbox("Select a State:", states["customer_state"])

    category_query = f"""
    SELECT p.product_category_name, SUM(oi.price) AS category_sales
    FROM order_items oi
    JOIN orders o USING(order_id)
    JOIN customers c USING(customer_id)
    JOIN products p USING(product_id)
    WHERE c.customer_state = '{selected_state}'
    GROUP BY p.product_category_name
    ORDER BY category_sales DESC
    LIMIT 10;
    """

    df_cat = pd.read_sql(category_query, engine)

    st.write(f"Monthly Sales Trend for State: {selected_state}")

    trend_query = f"""
    SELECT 
        DATE_TRUNC('month', o.order_purchase_timestamp) AS month,
        SUM(oi.price) AS monthly_revenue
    FROM order_items oi
    JOIN orders o USING(order_id)
    JOIN customers c USING(customer_id)
    WHERE c.customer_state = '{selected_state}'
    GROUP BY month
    ORDER BY month;
    """

    df_trend = pd.read_sql(trend_query, engine)

    df_trend["month"] = pd.to_datetime(df_trend["month"])

    trend_chart = (
        alt.Chart(df_trend)
        .mark_line(point=True)
        .encode(
            x=alt.X("month:T", title="Month"),
            y=alt.Y("monthly_revenue:Q", title="Revenue (BRL)"),
            tooltip=["month:T", "monthly_revenue:Q"]
        )
        .properties(height=350)
    )

    st.altair_chart(trend_chart, use_container_width=True)





# --------------------------- GRID ROW 2 ---------------------------
col3, col4 = st.columns(2)

with col3:

    # TOP 10 BEST-SELLING CATEGORIES (BAR CHART)

    st.header("Top 10 Selling Product Categories")

    top_cat_query = """
    SELECT pt.product_category_name_english, SUM(oi.price) AS total_sales
    FROM  order_items oi
    JOIN products p on oi.product_id=p.product_id
    JOIN product_category_translation pt on p.product_category_name = pt.product_category_name
    GROUP BY pt.product_category_name_english
    ORDER BY total_sales DESC
    LIMIT 10;
    """
    df_top_cat = pd.read_sql(top_cat_query, engine)

    chart3 = (
        alt.Chart(df_top_cat)
        .mark_bar()
        .encode(
            x=alt.X("product_category_name_english:N", sort="-y", title="Category"),
            y=alt.Y("total_sales:Q", title="Total Sales (BRL)"),
            color="product_category_name_english"
        )
        .properties(height=400)
    )
    st.altair_chart(chart3, use_container_width=True)


with col4:
    from st_aggrid import AgGrid, GridOptionsBuilder, GridUpdateMode

    #st.header("Top 10 Selling Product Categories")

    query_top = """
    SELECT pt.product_category_name_english, CAST(SUM(oi.price) AS DECIMAL(12,2)) AS total_sales
    FROM order_items oi
    JOIN products p on oi.product_id=p.product_id
    JOIN product_category_translation pt on p.product_category_name = pt.product_category_name
    GROUP BY pt.product_category_name_english
    ORDER BY total_sales DESC
    LIMIT 10;
    """

    df_top = pd.read_sql(query_top, engine)

    st.write("### Click a row to view product details:")

    gb = GridOptionsBuilder.from_dataframe(df_top)
    gb.configure_selection("single", use_checkbox=False) 
    gb.configure_grid_options(domLayout='normal')

    grid_options = gb.build()

    grid_response = AgGrid(
    df_top,
    gridOptions=grid_options,
    height=350,
    update_mode=GridUpdateMode.SELECTION_CHANGED,
    allow_unsafe_jscode=True,)

    selected_rows = grid_response["selected_rows"]

    if selected_rows is not None and len(selected_rows) > 0:
        selected = selected_rows.iloc[0] 
        category = selected["product_category_name_english"]

        st.session_state["selected_category"] = category
        st.switch_page("pages/02_Product_Details.py")



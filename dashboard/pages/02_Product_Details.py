import streamlit as st
import pandas as pd
from sqlalchemy import create_engine
import altair as alt
import os

st.set_page_config(page_title="Product Category Details", layout="wide")

@st.cache_resource
def get_engine():
    db_url = os.getenv("DATABASE_URL")
    return create_engine(db_url)
    
engine = get_engine()

# -------------------------------------------
# Check if a category was selected
# -------------------------------------------
if "selected_category" not in st.session_state or st.session_state["selected_category"] is None:
    st.error("❌ No category selected. Go back to the Overview page.")
    st.stop()

category = st.session_state["selected_category"]

st.title(f"Product Details — {category}")
st.write("Displaying detailed metrics for the selected product category.")

# -------------------------------------------
# Query all products in this category
# -------------------------------------------
query = f"""
SELECT  p.product_name_length, p.product_description_length,
        p.product_photos_qty, p.product_weight_g,
       oi.price, oi.freight_value
FROM products p
JOIN order_items oi USING(product_id)
JOIN product_category_translation pt on p.product_category_name = pt.product_category_name

WHERE pt.product_category_name_english = '{category}'
LIMIT 500;
"""

df = pd.read_sql(query, engine)

st.subheader("📋 Product List")
st.dataframe(df)

# -------------------------------------------
# Revenue Chart for this category
# -------------------------------------------
st.subheader("Revenue Distribution")

chart = (
    alt.Chart(df)
    .mark_bar()
    .encode(
        x="price:Q",
        y="count()",
        tooltip=["price"]
    )
)

st.altair_chart(chart, use_container_width=True)

# -------------------------------------------
# Back button
# -------------------------------------------
if st.button("⬅ Back to Overview"):
    st.session_state["selected_category"] = None
    st.switch_page("app.py")

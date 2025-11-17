import pandas as pd
from sqlalchemy import create_engine
from tqdm import tqdm

# -------------1. CONNECT TO POSTGRES DOCKER CONTAINER------------

engine = create_engine(
    "postgresql://postgres:admin@localhost:5433/olist_db"
)


# ------------LOAD A CSV--------
def load_csv(path):
    return pd.read_csv(path, encoding='utf-8')


print("Loading Customers...")
df_customers = load_csv("../data/olist_customers_dataset.csv")
df_customers.to_sql("customers", engine, if_exists="append", index=False)


print("Loading Sellers...")
df_sellers = load_csv("../data/olist_sellers_dataset.csv")
df_sellers.to_sql("sellers", engine, if_exists="append", index=False)


print("Loading Geolocation...")
df_geo = load_csv("../data/olist_geolocation_dataset.csv")
df_geo.to_sql("geolocation", engine, if_exists="append", index=False)


print("Loading Product Category Translation...")
df_cat = load_csv("../data/product_category_name_translation.csv")
df_cat.to_sql("product_category_translation", engine, if_exists="append", index=False)


print("Loading Products...")
df_products = load_csv("../data/olist_products_dataset.csv")
df_products['product_category_name'] = df_products['product_category_name'].apply(
    lambda x: x if x in df_cat['product_category_name'].values else None
)
df_products.to_sql("products", engine, if_exists="append", index=False)


print("Loading Orders...")
df_orders = load_csv("../data/olist_orders_dataset.csv")

# Convert timestamp columns
ts_cols = [
    "order_purchase_timestamp", "order_approved_at",
    "order_delivered_carrier_date", "order_delivered_customer_date",
    "order_estimated_delivery_date"
]

for col in ts_cols:
    df_orders[col] = pd.to_datetime(df_orders[col], errors='coerce')

df_orders.to_sql("orders", engine, if_exists="append", index=False)


print("Loading Order Items...")
df_items = load_csv("../data/olist_order_items_dataset.csv")
df_items["shipping_limit_date"] = pd.to_datetime(df_items["shipping_limit_date"], errors='coerce')
df_items.to_sql("order_items", engine, if_exists="append", index=False)


print("Loading Payments...")
df_pay = load_csv("../data/olist_order_payments_dataset.csv")
df_pay.to_sql("order_payment", engine, if_exists="append", index=False)


print("Loading Reviews...")
df_reviews = load_csv("../data/olist_order_reviews_dataset.csv")
df_reviews["review_creation_date"] = pd.to_datetime(df_reviews["review_creation_date"], errors='coerce')
df_reviews["review_answer_timestamp"] = pd.to_datetime(df_reviews["review_answer_timestamp"], errors='coerce')

df_reviews = df_reviews.drop_duplicates(subset=["review_id"])
df_reviews.to_sql("order_reviews", engine, if_exists="append", index=False)


print("Data Ingestion Done!")

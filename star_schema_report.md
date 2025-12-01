# Phase 2 – Optional Dimensional Modeling & ETL (dbt)

## 1. Star Schema Design

The optional phase is to design and develop a star schema for Olist's e-commerce dataset using the:

- dbt
- PostgreSQL

### Fact Table: fact_order_items

- **Grain:** 1 row per order item (each product line in an order).
- **Keys:**
  - customer_key
  - seller_key
  - product_key
  - order_date_key
  - delivery_date_key
  - estimated_delivery_date_key
- **Measures:**
  - price
  - freight_value
  - item_revenue = price + freight_value
  - review_score
  - is_late_delivery (boolean flag based on delivered_date > estimated_delivery_date)

To allow analysis of:

- Revenue per seller
- Revenue per customer
- Revenue per product category
- Revenue per time period

### Dimensions

**dim_customer**

- Grain: A single row for a customer will be in the dimension table
- Attributes: customer_id, customer_unique_id, city, state, zip, first_order_date, most_recent_order_date, total_orders.
- Purpose: customer segmentation and LTV-style analyses.

**dim_seller**

- Grain: 1 row per seller.
- Attributes: seller_id, city, state, zip.
- Purpose: seller performance analysis by region and seller.

**dim_product**

- Grain: 1 row per product.
- Attributes: product_id, product_category_name, product_category_name_english, weight and size attributes.
- Purpose: allows for analysis of product category and product-level performance.

**dim_date**

- Grain: A single row per calendar date
- Attributes: date_key, date, year, month, day, month_name, day_name, day_of_week, is_weekend.
- Purpose: time-series analysis and aggregations by day, month, and year.
- Used in the fact table for: order_date, delivered_date, estimated_delivery_date.

A star schema diagram (star_schema.drawio/PNG) is located in this repo showing that the fact_order_items is at the center of a star schema and the dimension tables of customer, seller, product, and date surrounding it.

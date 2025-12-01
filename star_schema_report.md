# Phase 2 – Optional Dimensional Modeling & ETL (dbt)

## 1. Star Schema Design

For the optional part of Phase 2, I designed and implemented a star schema for the Olist e-commerce dataset using dbt and PostgreSQL.

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

This fact table supports analyses such as revenue by seller, customer, product category, and time.

### Dimensions

**dim_customer**

- Grain: 1 row per customer.
- Attributes: customer_id, customer_unique_id, city, state, zip, first_order_date, most_recent_order_date, total_orders.
- Purpose: customer segmentation and LTV-style analyses.

**dim_seller**

- Grain: 1 row per seller.
- Attributes: seller_id, city, state, zip.
- Purpose: seller performance analysis by region and seller.

**dim_product**

- Grain: 1 row per product.
- Attributes: product_id, product_category_name, product_category_name_english, weight and size attributes.
- Purpose: category and product-level performance analysis.

**dim_date**

- Grain: 1 row per calendar date.
- Attributes: date_key, date, year, month, day, month_name, day_name, day_of_week, is_weekend.
- Purpose: time-series analysis and aggregations by day, month, and year.
- Used in the fact table for: order_date, delivered_date, estimated_delivery_date.

A star schema diagram (star_schema.drawio / PNG) is included in the repo showing fact_order_items in the center with customer, seller, product, and date dimensions around it.

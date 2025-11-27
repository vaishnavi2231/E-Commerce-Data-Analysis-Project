# Phase 2 – Query Optimization & Performance Tuning  
## EAS 550 – Analytical Layer (OLAP)  

---

# 1. Query Selected for Optimization

For Phase 2, I selected **Query 2 – Seller Performance Analysis** for performance tuning because:

- It joins four large OLTP tables: `orders`, `order_items`, `order_reviews`, and `sellers`.
- It performs multiple aggregations: revenue, review score, average delay.
- It applies filters (delivered orders only).
- It uses window functions to rank sellers.
- It is the most computationally heavy analytical query in Phase 2.

This makes it an ideal candidate for performance profiling and index optimization.

---

# 2. Analytical Query Used for Tuning

WITH seller_stats AS (
    SELECT
        s.seller_id,
        COUNT(DISTINCT o.order_id) AS num_orders,
        SUM(oi.price + oi.freight_value) AS total_revenue,
        AVG(orv.review_score::numeric) AS avg_review_score,
        AVG(
            EXTRACT(
                DAY FROM (o.order_delivered_customer_date - o.order_estimated_delivery_date)
            )
        ) AS avg_delay_days
    FROM sellers s
    JOIN order_items oi ON s.seller_id = oi.seller_id
    JOIN orders o ON oi.order_id = o.order_id
    LEFT JOIN order_reviews orv ON o.order_id = orv.order_id
    WHERE 
        o.order_status = 'delivered'
        AND o.order_delivered_customer_date IS NOT NULL
        AND o.order_estimated_delivery_date IS NOT NULL
    GROUP BY s.seller_id
)

SELECT
    seller_id,
    num_orders,
    total_revenue,
    avg_review_score,
    avg_delay_days,
    RANK() OVER (ORDER BY total_revenue DESC) AS revenue_rank,
    RANK() OVER (ORDER BY avg_review_score DESC) AS satisfaction_rank,
    RANK() OVER (ORDER BY avg_delay_days ASC) AS delivery_speed_rank
FROM seller_stats
WHERE num_orders >= 20
ORDER BY total_revenue DESC;


# 3. Baseline Performance (Before Indexes)

EXPLAIN ANALYZE
WITH seller_stats AS ( ...same CTE... )
SELECT
    ...
FROM seller_stats
WHERE num_orders >= 20
ORDER BY total_revenue DESC;

<img width="684" height="259" alt="image" src="https://github.com/user-attachments/assets/6851048b-66a4-48ff-8629-5eb0d9ce2fee" />

This already indicates a reasonably efficient plan, helped by existing primary keys and indexes on join columns.

# 4. Indexing Strategy

The query:

Filters on orders.order_status = 'delivered'

Uses order_delivered_customer_date and order_estimated_delivery_date to compute delivery delay

Joins orders with order_items and order_reviews

To try to improve performance, I added the following indexes on the orders table in the public schema:

CREATE INDEX IF NOT EXISTS idx_orders_status
    ON orders(order_status);

CREATE INDEX IF NOT EXISTS idx_orders_delivered_date
    ON orders(order_delivered_customer_date);

CREATE INDEX IF NOT EXISTS idx_orders_estimated_date
    ON orders(order_estimated_delivery_date);

Rationale:

idx_orders_status lets PostgreSQL more quickly retrieve only “delivered” orders instead of scanning all rows.

idx_orders_delivered_date and idx_orders_estimated_date support the delivery delay calculation by giving the planner indexed access paths on these timestamp columns.

Together, these indexes should reduce the amount of data scanned and can improve join and aggregation performance for analytical queries that filter by status and date.

# 5. Baseline Performance (After Indexes)

<img width="822" height="244" alt="image" src="https://github.com/user-attachments/assets/033ac596-3154-4267-9f74-00d1f93d00be" />

This is an absolute improvement of about 5.16 ms, which corresponds to roughly 1.4% faster:

Improvement % ≈ (366.450 − 361.290) / 366.450 × 100 ≈ 1.4 %

The improvement is small because:

The dataset is moderate in size.

Several useful indexes on join keys already existed in the schema, so the original plan was already efficient.

Repeated runs of the query benefit from PostgreSQL’s buffer cache, further reducing the visible difference.

However, the EXPLAIN plans show that PostgreSQL can now use more selective index-based access paths on order_status and the delivery date columns, which would matter more as data volume grows.



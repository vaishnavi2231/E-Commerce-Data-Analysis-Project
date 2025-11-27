# Phase 2 – Query Optimization & Performance Tuning

## 1. Query Selected for Optimization

I optimized the **Seller Performance** analytical query (Phase 2 – Query 2), which joins
`sellers`, `order_items`, `orders`, and `order_reviews` to compute, per seller:

- number of orders
- total revenue
- average review score
- average delivery delay in days

This query is used to rank sellers by revenue, satisfaction, and delivery speed.

### Query (Seller Performance)

```sql
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

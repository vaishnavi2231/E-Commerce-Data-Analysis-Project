/* ============================================================
   Phase 2 – Advanced Analytical Queries (OLAP)
   Database : olist_db
   Schema   : public
   Purpose  : Three complex analytical queries using joins,
              CTEs, window functions, and aggregations.
   ============================================================ */

-- To ensure that we read from the right schema
SET search_path TO public;


/* ============================================================
   Query 1: Customer Lifetime Value (LTV) & Ordering Behavior
   ------------------------------------------------------------
   Business Question:
   - Who are our highest value customers?
   - How many orders have they placed?
   - When was their first and last order placed?

   Techniques used:
   - Join with multiple tables: orders + order_items
   - CTEs for reuse (customer_orders, ltv)
   - Aggregations: COUNT, SUM, AVG, MIN, MAX
   - Window function: NTILE(4) for LTV quartiles
   ============================================================ */

WITH customer_orders AS (
    SELECT
        o.customer_id,
        o.order_id,
        SUM(oi.price + oi.freight_value) AS order_total,
        o.order_purchase_timestamp::date AS order_date
    FROM orders o
    JOIN order_items oi ON o.order_id = oi.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY
        o.customer_id,
        o.order_id,
        o.order_purchase_timestamp::date
),

ltv AS (
    SELECT
        customer_id,
        COUNT(order_id) AS num_orders,
        SUM(order_total) AS lifetime_value,
        AVG(order_total) AS avg_order_value,
        MIN(order_date) AS first_order_date,
        MAX(order_date) AS most_recent_order
    FROM customer_orders
    GROUP BY customer_id
)

SELECT
    customer_id,
    num_orders,
    lifetime_value,
    avg_order_value,
    first_order_date,
    most_recent_order,
    NTILE(4) OVER (ORDER BY lifetime_value DESC) AS ltv_quartile
FROM ltv
ORDER BY lifetime_value DESC
LIMIT 50;


/* ============================================================
   Query 2: Seller Performance
   ------------------------------------------------------------
   Business Question:
   - Which sellers drive the most revenue?
   - Which sellers have the best customer satisfaction?
   - Which sellers deliver fastest (lowest average delay)?

   Metrics:
   - num_orders       : # of delivered orders per seller
   - total_revenue    : sum(price + freight_value)
   - avg_review_score : average review score
   - avg_delay_days   : avg(delivered_date - estimated_delivery_date)

   Techniques used:
   - Multi-table joins (sellers, order_items, orders, order_reviews)
   - Aggregations by seller
   - Window functions: RANK() for multi-dimensional ranking
   ============================================================ */

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
    RANK() OVER (ORDER BY total_revenue DESC)      AS revenue_rank,
    RANK() OVER (ORDER BY avg_review_score DESC)   AS satisfaction_rank,
    RANK() OVER (ORDER BY avg_delay_days ASC)      AS delivery_speed_rank
FROM seller_stats
WHERE num_orders >= 20          -- filter out very small / inactive sellers
ORDER BY total_revenue DESC;


/* ============================================================
   Query 3: Monthly Revenue & Month-over-Month (MoM) Change
   ------------------------------------------------------------
   Business Question:
   - How is monthly revenue trending over time?
   - What is the month-over-month percentage growth/decline?

   Metrics:
   - revenue              : monthly sum(price + freight_value)
   - prev_month_revenue   : previous month’s revenue
   - mom_percentage_change: % change vs previous month

   Techniques used:
   - DATE_TRUNC for monthly aggregation
   - Window function LAG() for previous-month comparison
   - Derived percentage metric
   ============================================================ */

WITH monthly_rev AS (
    SELECT
        DATE_TRUNC('month', o.order_purchase_timestamp)::date AS month,
        SUM(oi.price + oi.freight_value)::numeric AS revenue
    FROM orders o
    JOIN order_items oi ON o.order_id = oi.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY DATE_TRUNC('month', o.order_purchase_timestamp)
),

with_mom AS (
    SELECT
        month,
        revenue,
        LAG(revenue) OVER (ORDER BY month) AS prev_month_revenue
    FROM monthly_rev
)

SELECT
    month,
    revenue,
    prev_month_revenue,
    CASE
        WHEN prev_month_revenue IS NULL THEN NULL
        ELSE ROUND( ((revenue - prev_month_revenue) / prev_month_revenue) * 100, 2 )
    END AS mom_percentage_change
FROM with_mom
ORDER BY month;

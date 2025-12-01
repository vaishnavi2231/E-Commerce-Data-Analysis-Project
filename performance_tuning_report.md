# 📄 **Performance Tuning Report – Phase 2 (OLAP Layer)**

### *Seller Performance Analytical Query – EXPLAIN ANALYZE & Index Optimization*

## **1. Introduction**

This report documents the performance profiling and optimization performed as part of **Phase 2: OLAP Analytical Layer**.
Analytical queries often involve large scans, multiple joins, and heavy aggregations, making performance tuning essential for scalability and responsiveness.

We selected the **Seller Performance Query** as the target for optimization because:

* It uses **four tables** (orders, order_items, order_reviews, sellers)
* It includes **conditional filters**, **multiple join keys**, and **computational expressions**
* It runs over the **largest tables** in the OLTP schema
* It represents a realistic business question used in marketplaces like Olist

This makes it an ideal candidate for EXPLAIN ANALYZE–driven performance tuning.

---

# **2. Analytical Query Selected for Tuning**

### **Seller Performance – Revenue, Rating & Delivery Delay**

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
```

This query answers critical business questions:

* Which sellers generate the highest revenue?
* Which sellers offer the best customer satisfaction?
* Who delivers the fastest (lowest delay days)?
* Who should be prioritized for marketplace ranking?

---

# **3. EXPLAIN ANALYZE – Before Optimization**

### **Execution Plan (Before Indexes)**

> 📌 *Output from PostgreSQL — image included below.*
> <img width="687" height="248" alt="image" src="https://github.com/user-attachments/assets/d5bbc0af-cda3-4a07-bdc0-09b13b2156e1" />


### **Key Observations**

* Seq Scan on **orders** slows filtering on:

  * `order_status`
  * `order_delivered_customer_date`
  * `order_estimated_delivery_date`
* Seq Scan on **order_items** join on `seller_id`
* Reviewing the plan shows:

  * No supporting indexes exist for major filter or join columns
  * Many rows scanned unnecessarily before filtering

### **Before Index Creation: Execution Time**

```
Total execution time: ~366.45 ms
```

---

# **4. Indexing Strategy**

Indexes were chosen based on **WHERE clause filters** and **JOIN predicates**.

### **4.1 Indexes Added**

```sql
-- Improve filtering on delivered orders
CREATE INDEX IF NOT EXISTS idx_orders_status 
    ON orders(order_status);

-- Improve filtering for delivery and estimated dates
CREATE INDEX IF NOT EXISTS idx_orders_delivered_date 
    ON orders(order_delivered_customer_date);

CREATE INDEX IF NOT EXISTS idx_orders_estimated_date 
    ON orders(order_estimated_delivery_date);

-- Improve join performance on order_items.seller_id
CREATE INDEX IF NOT EXISTS idx_order_items_seller 
    ON order_items(seller_id);
```

### **4.2 Benefits of these Indexes?**

| Column                                 | Reason                                                   | Benefit                        |
| -------------------------------------- | -------------------------------------------------------- | ------------------------------ |
| `orders.order_status`                  | Frequently filtered (`WHERE order_status = 'delivered'`) | Reduces row scans dramatically |
| `orders.order_delivered_customer_date` | Used in delay calculation & NULL checks                  | Avoids scanning NULL rows      |
| `orders.order_estimated_delivery_date` | Same reasoning as above                                  | Supports fast date comparison  |
| `order_items.seller_id`                | Critical join column                                     | Avoids Hash Join + Seq Scan    |

These four indexes align perfectly with PostgreSQL’s performance tuning best practices.

---

# **5. EXPLAIN ANALYZE – After Optimization**

### **Execution Plan (After Indexes)**

> 📌 *Updated query plan — image included below.*
> <img width="813" height="244" alt="image" src="https://github.com/user-attachments/assets/f796e9c9-e557-45a7-bd6a-0c5d5d93b34d" />


### **After Index Creation: Execution Time**

```
Total execution time: ~361.29 ms
```

---

# **6. Performance Comparison**

| Metric           | Before     | After             | Improvement              |
| ---------------- | ---------- | ----------------- | ------------------------ |
| Sequential Scans | Higher     | Lower             | Improved filtering       |
| Join Performance | Slower     | Slightly improved | Index on seller_id helps |

### **Improvement was small because**

1. **Dataset size is small** (course dataset, not production scale).
2. **PostgreSQL caching** improves repeated execution time automatically.
3. Several implicit indexes already exist on primary keys.

On a larger dataset (millions of rows), the improvement would be **dramatic**, especially on:

* `order_status`
* Delivery date comparisons
* Joins on seller_id

---

# **7. Conclusion**

This performance tuning exercise demonstrated:

* How to analyze query bottlenecks using **EXPLAIN ANALYZE**
* How to design **indexes aligned with filtering & join patterns**
* How OLAP queries benefit from optimized OLTP schema access
* How small improvements in test datasets translate into **big gains** at scale

Even though the runtime improvement is modest due to dataset size, the new indexes provide:

* Faster filtering
* Better join selectivity
* Scalable performance as data volume increases

This tuning approach ensures the analytical layer remains responsive for dashboards, aggregations, and deeper analytics.


-- Delivery Performance Analysis
-- Run in BigQuery on delivery_clean.csv (one row per delivered order)


-- 1. What's the overall on-time delivery rate?
SELECT
  COUNT(*) AS orders,
  ROUND(100.0 * SUM(on_time) / COUNT(*), 1) AS on_time_pct,
  ROUND(AVG(delivery_days), 1) AS avg_days_to_deliver,
  ROUND(AVG(promised_days), 1) AS avg_days_promised
FROM `atlas-analyst.delivery_project.delivery`;


-- 2. Where are late deliveries concentrated?
SELECT
  customer_state,
  COUNT(*) AS orders,
  ROUND(100.0 * SUM(on_time) / COUNT(*), 1) AS on_time_pct,
  ROUND(AVG(delivery_days), 1) AS avg_days,
  ROUND(AVG(CASE WHEN on_time = 0 THEN delay_days END), 1) AS avg_days_late
FROM `atlas-analyst.delivery_project.delivery`
GROUP BY customer_state
HAVING orders >= 100
ORDER BY on_time_pct ASC;


-- 3. Does shipping across state lines cost more time and money?
-- cross_state: 1 = seller and customer in different states, 0 = same state
SELECT
  cross_state,
  COUNT(*) AS orders,
  ROUND(100.0 * SUM(on_time) / COUNT(*), 1) AS on_time_pct,
  ROUND(AVG(delivery_days), 1) AS avg_days,
  ROUND(AVG(freight_pct), 1) AS avg_freight_pct_of_order
FROM `atlas-analyst.delivery_project.delivery`
GROUP BY cross_state;


-- 4. Which categories pay the most freight compared to their weight?
SELECT
  category,
  COUNT(*) AS orders,
  ROUND(AVG(order_value), 2) AS avg_order_value,
  ROUND(AVG(freight_cost), 2) AS avg_freight,
  ROUND(AVG(freight_pct), 1) AS freight_pct_of_order,
  ROUND(AVG(product_weight_g) / 1000.0, 2) AS avg_weight_kg
FROM `atlas-analyst.delivery_project.delivery`
WHERE order_value > 0
GROUP BY category
HAVING orders >= 100
ORDER BY freight_pct_of_order DESC
LIMIT 20;


-- 5. Are the delivery promises realistic?
SELECT
  CASE
    WHEN promised_days < 10 THEN '1. under 10 days'
    WHEN promised_days < 20 THEN '2. 10-19 days'
    WHEN promised_days < 30 THEN '3. 20-29 days'
    ELSE '4. 30+ days'
  END AS promise_window,
  COUNT(*) AS orders,
  ROUND(100.0 * SUM(on_time) / COUNT(*), 1) AS on_time_pct,
  ROUND(AVG(delivery_days - promised_days), 1) AS avg_variance
FROM `atlas-analyst.delivery_project.delivery`
GROUP BY promise_window
ORDER BY promise_window;


-- 6. Which sellers have the worst on-time rate?
SELECT
  seller_id,
  seller_state,
  COUNT(*) AS orders,
  ROUND(100.0 * SUM(on_time) / COUNT(*), 1) AS on_time_pct,
  ROUND(AVG(delay_days), 1) AS avg_delay
FROM `atlas-analyst.delivery_project.delivery`
GROUP BY seller_id, seller_state
HAVING orders >= 50
ORDER BY on_time_pct ASC
LIMIT 20;

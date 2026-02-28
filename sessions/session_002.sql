
-- Session 001

-- Request 1
-- Question:
-- Request 1/25 [CORPORATE]
-- Business question:
-- Management wants a simple overview of total revenue generated
-- during the last full calendar month.
-- The result must be aggregated at monthly level.

-- Expected output:
-- - reporting_month
-- - total_revenue
-- - total_transactions

 

-- My SQL:

WITH reporting_m AS(
     SELECT date_sk , calendar_month 
     FROM dw.dim_date 
     WHERE full_date BETWEEN '2025-12-01' AND '2025-12-31' 
    ) 
     SELECT r.calendar_month, SUM(f.net_amount)AS total_revenue ,COUNT(*) AS total_transactions 
     FROM dw.fact_sales f 
     JOIN reporting_m r 
     ON f.date_sk = r.date_sk 
     GROUP BY r.calendar_month



-- SQL Correction:

-- Score: Partial

--Best Professional TSQL Solution:

-- Last full calendar month boundaries
DECLARE @StartDate DATE = DATEADD(MONTH, DATEDIFF(MONTH, 0, GETDATE()) - 1, 0);
DECLARE @EndDate   DATE = EOMONTH(@StartDate);

SELECT
    d.calendar_year * 100 + d.calendar_month AS reporting_month,
    SUM(f.net_amount) AS total_revenue,
    COUNT_BIG(*) AS total_transactions
FROM dw.fact_sales f
INNER JOIN dw.dim_date d
    ON f.date_sk = d.date_sk
WHERE d.full_date BETWEEN @StartDate AND @EndDate
GROUP BY d.calendar_year, d.calendar_month
ORDER BY reporting_month;



-- Request 2
-- Question:

-- Request 2/25 [INTERVIEW]
-- Business question:
-- Identify the top 3 customers by total revenue
-- during the last 90 days.
-- If two customers tie, use customer identifier as deterministic tie-breaker.
-- Result must be ranked.

-- Expected output:
-- - rank_position
-- - customer_identifier
-- - total_revenue_last_90_days


-- My SQL:
WITH max_dwh_date AS (
    SELECT MAX(full_date) AS max_date
    FROM dw.dim_date
),
revenue_90d AS (
    SELECT
        f.customer_sk AS customer_identifier,
        SUM(f.net_amount) AS total_revenue_last_90_days
    FROM dw.fact_sales f
    JOIN dw.dim_date d
        ON f.date_sk = d.date_sk
    CROSS JOIN max_dwh_date m
    WHERE d.full_date >= DATEADD(DAY, -90, m.max_date)
      AND d.full_date <= m.max_date
    GROUP BY f.customer_sk
),
ranked AS (
    SELECT
        ROW_NUMBER() OVER (
            ORDER BY total_revenue_last_90_days DESC, customer_identifier ASC
        ) AS rank_position,
        customer_identifier,
        total_revenue_last_90_days
    FROM revenue_90d
)
SELECT
    rank_position,
    customer_identifier,
    total_revenue_last_90_days
FROM ranked
WHERE rank_position <= 3
ORDER BY rank_position;

 

-- SQL Correction:

-- Correct 
 


-- Request 3
-- Question:

-- Request 3/25 [CORPORATE]
-- Business question:
-- Operations wants to understand device reliability.
-- For the last 30 days, show the number of distinct devices that reported activity,
-- and the number of distinct devices that reported at least one error.
-- Report at daily granularity.

-- Expected output:
-- - activity_date
-- - active_devices
-- - devices_with_errors

 

-- My SQL:
-- this is now with Postgres
WITH the_max_date AS (
  SELECT MAX(full_date)::date AS max_date
  FROM dw.dim_date
),
bounds AS (
  SELECT (max_date - INTERVAL '30 days')::date AS min_date, max_date
  FROM the_max_date
)
SELECT
  d.full_date::date AS activity_date,
  COUNT(DISTINCT CASE WHEN f.is_device_active = TRUE  THEN de.device_id END) AS active_devices,
  COUNT(DISTINCT CASE WHEN f.is_device_active = FALSE THEN de.device_id END) AS devices_with_errors
FROM dw.fact_device_usage_daily f
JOIN dw.dim_date d
  ON f.date_sk = d.date_sk
JOIN dw.dim_device de
  ON f.device_sk = de.device_sk
CROSS JOIN bounds b
WHERE d.full_date::date BETWEEN b.min_date AND b.max_date
GROUP BY 1
ORDER BY 1;


-- SQL Correction:

-- Correct
 


-- Request 4
-- Question:

-- Request 4/25 [INTERVIEW]
-- Business question:
-- Finance suspects discounting is hurting performance.
-- Using the last full calendar quarter (anchored to the latest available warehouse date),
-- return the 5 products with the highest total discount amount.
-- Use a deterministic tie-breaker by product identifier.
-- Granularity: per product.

-- Expected output:
-- - product_identifier
-- - product_name
-- - total_discount_amount
-- - total_revenue

 
-- My SQL:

WITH date_products AS( 
    SELECT p.product_id, p.product_name , SUM(s.unit_price * s.quantity * s.discount / 100 ) AS total_discount_amount , SUM(s.net_amount) AS total_revenue
    FROM dw.dim_product p 
    JOIN dw.fact_sales s 
    ON p.product_sk = s.product_sk 
    JOIN dw.dim_date d 
    ON s.date_sk = d.date_sk 
    WHERE d.calendar_year = 2025 AND d.calendar_quarter = 4 
    GROUP BY 1,2 
    ) 
    SELECT product_id, product_name , total_discount_amount , total_revenue 
    FROM date_products 
    ORDER BY total_discount_amount DESC , product_id LIMIT 5



-- SQL Correction:

-- Score: Partial

--What’s correct:

--Correct aggregation at product level.

--Correct discount calculation logic.

--Deterministic tie-breaker (ORDER BY total_discount_amount DESC, product_id).

--Correct LIMIT 5 for Postgres.

--Proper grouping.

--What’s missing:

--You hardcoded 2025 Q4.

--The request required last full calendar quarter anchored to max warehouse date.

--If we move into 2026, your query breaks conceptually.

--Not robust for production analytics.

WITH max_dwh_date AS (
    SELECT MAX(full_date) AS max_date
    FROM dw.dim_date
),
last_full_quarter AS (
    SELECT
        DATE_TRUNC('quarter', max_date) - INTERVAL '3 months' AS quarter_start,
        DATE_TRUNC('quarter', max_date) - INTERVAL '1 day' AS quarter_end
    FROM max_dwh_date
),
product_agg AS (
    SELECT
        p.product_id AS product_identifier,
        p.product_name,
        SUM(s.unit_price * s.quantity * s.discount / 100.0) AS total_discount_amount,
        SUM(s.net_amount) AS total_revenue
    FROM public.fact_sales s
    JOIN public.dim_product p
        ON s.product_sk = p.product_sk
    JOIN public.dim_date d
        ON s.date_sk = d.date_sk
    CROSS JOIN last_full_quarter q
    WHERE d.full_date BETWEEN q.quarter_start AND q.quarter_end
    GROUP BY p.product_id, p.product_name
)
SELECT
    product_identifier,
    product_name,
    total_discount_amount,
    total_revenue
FROM product_agg
ORDER BY total_discount_amount DESC, product_identifier
LIMIT 5;




-- Request 5
-- Question:

-- Request 5/25 [CORPORATE]
-- Business question:
-- Marketing wants to understand subscription performance.
-- For the last 12 months, show total revenue per subscription type.
-- Granularity: per subscription type.
-- Time window: rolling 12 months based on max warehouse date.

-- Expected output:
-- - subscription_type
-- - total_revenue_last_12_months
-- - total_transactions



-- My SQL:

WITH maxim_date AS (
    SELECT MAX(full_date) AS max_date
    FROM dw.dim_date
),
interval_date AS (
    SELECT
        (DATE_TRUNC('day', max_date) - INTERVAL '1 year')::date AS min_date,
        DATE_TRUNC('day', max_date)::date AS max_date
    FROM maxim_date
)
SELECT
    c.subscription_type,
    SUM(f.net_amount) AS total_revenue_last_12_months,
    COUNT(f.sales_fact_id) AS total_transactions
FROM dw.dim_customer c
JOIN dw.fact_sales f
    ON c.customer_sk = f.customer_sk
JOIN dw.dim_date d
    ON f.date_sk = d.date_sk
CROSS JOIN interval_date i
WHERE d.full_date BETWEEN i.min_date AND i.max_date
GROUP BY 1
ORDER BY total_revenue_last_12_months DESC;



-- SQL Correction:

-- Score: Correct


-- Request 6
-- Question:

-- Request 6/25 [INTERVIEW]
-- Business question:
-- Product wants to find customers who are “highly active”.
-- For the last 60 days (anchored to max warehouse date),
-- return the top 10 customers by number of active days (days with at least 1 sale).
-- Use deterministic tie-breakers by customer identifier.
-- Granularity: per customer.

-- Expected output:
-- - customer_identifier
-- - active_days_last_60
-- - total_revenue_last_60
 

-- My SQL:


WITH max_dw_date AS (
    SELECT MAX(full_date) AS max_date 
    FROM dw.dim_date
),
dw_date AS(
    SELECT  max_date , max_date - INTERVAL '60 days' AS min_date
    FROM  max_dw_date    
     
) ,
dw_products AS (
SELECT c.customer_id AS customer_identifier , COUNT(DISTINCT f.date_sk) AS active_days_last_60 , SUM(f.net_amount) AS total_revenue_last_60
FROM dw.dim_customer c 
JOIN dw.fact_sales f  
ON c.customer_sk = f.customer_sk 
JOIN dw.dim_date d
ON f.date_sk = d.date_sk
CROSS JOIN dw_date a
WHERE d.full_date BETWEEN a.min_date AND a.max_date
GROUP BY c.customer_id
) 
SELECT ROW_NUMBER() OVER(ORDER BY active_days_last_60 DESC , customer_identifier ASC ) AS RANKING , customer_identifier , active_days_last_60 , total_revenue_last_60
FROM dw_products
ORDER BY active_days_last_60 DESC , customer_identifier ASC
LIMIT 10 


-- SQL Correction:

-- Score: Correct



-- Request 7
-- Question:

-- Request 7/25 [CORPORATE]
-- Business question:
-- Sales leadership wants to track day-to-day momentum.
-- For the last 14 days (anchored to max warehouse date),
-- show daily revenue and the 7-day moving average of daily revenue.
-- Granularity: per day.

-- Expected output:
-- - activity_date
-- - daily_revenue
-- - revenue_7d_moving_avg
 

-- My SQL:

WITH the_date AS (
    SELECT MAX(d.full_date) AS max_date
    FROM dw.fact_sales f
    JOIN dw.dim_date d ON f.date_sk = d.date_sk
),
dw_date AS (
    SELECT max_date, max_date - INTERVAL '13 days' AS min_date
    FROM the_date
),
the_table AS (
    SELECT
        d.full_date AS activity_date,
        SUM(f.net_amount) AS daily_revenue
    FROM dw.fact_sales f
    JOIN dw.dim_date d ON f.date_sk = d.date_sk
    CROSS JOIN dw_date a
    WHERE d.full_date BETWEEN a.min_date AND a.max_date
    GROUP BY d.full_date
)
SELECT
    activity_date,
    daily_revenue,
    AVG(daily_revenue) OVER (
        ORDER BY activity_date
        ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
    ) AS revenue_7d_moving_avg
FROM the_table
ORDER BY activity_date;


 

-- SQL Correction:

-- Score: Partial

--  WHAT’S CORRECT
-- 1) Last 14-day window is correctly built (min_date = max_date - 13).
-- 2) Daily revenue is properly aggregated.
-- 3) 7-day moving average is correctly calculated with:
-- ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
-- 4) Correct ordering by date.

--  WHAT’S MISSING / RISK
-- 1) The request required anchoring to the max warehouse date (dim_date),
-- but your query anchors to the latest day with sales (fact_sales).
-- If there are trailing days with no sales, your “last 14 days” window shifts.

-- 2) If there are days with no sales inside the range, they won’t appear as rows,
-- so the moving average is computed over “sales days” instead of “calendar days”.
-- In corporate reporting, all calendar days are usually expected.


-- Best Professional PostgreSQL Solution (calendar-complete, anchored to DW max date)

WITH max_dwh_date AS (
    SELECT MAX(full_date)::date AS max_date
    FROM dw.dim_date
),
bounds AS (
    SELECT
        (max_date - INTERVAL '13 days')::date AS min_date,
        max_date::date AS max_date
    FROM max_dwh_date
),
calendar AS (
    SELECT d.full_date::date AS activity_date
    FROM dw.dim_date d
    CROSS JOIN bounds b
    WHERE d.full_date::date BETWEEN b.min_date AND b.max_date
),
daily_sales AS (
    SELECT
        d.full_date::date AS activity_date,
        SUM(f.net_amount) AS daily_revenue
    FROM dw.fact_sales f
    JOIN dw.dim_date d
        ON f.date_sk = d.date_sk
    CROSS JOIN bounds b
    WHERE d.full_date::date BETWEEN b.min_date AND b.max_date
    GROUP BY d.full_date::date
)
SELECT
    c.activity_date,
    COALESCE(s.daily_revenue, 0) AS daily_revenue,
    AVG(COALESCE(s.daily_revenue, 0)) OVER (
        ORDER BY c.activity_date
        ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
    ) AS revenue_7d_moving_avg
FROM calendar c
LEFT JOIN daily_sales s
    ON s.activity_date = c.activity_date
ORDER BY c.activity_date;





-- Request 8
-- Question:

-- Request 8/25 [INTERVIEW]
-- Business question:
-- Customer Success wants to detect churn risk.
-- Find customers who had revenue in the prior 60-day window,
-- but had ZERO revenue in the most recent 30 days (anchored to max warehouse date).
-- Granularity: per customer.

-- Expected output:
-- - customer_identifier
-- - revenue_prior_60_days
-- - last_purchase_date
 

-- My SQL:

WITH dw_max_date AS (
  SELECT MAX(full_date) AS max_date
  FROM dw.dim_date
),
dates AS (
  SELECT
    max_date,
    -- recent 30 days: (max_date - 30, max_date]
    max_date - INTERVAL '30 days' AS recent_start,
    max_date                     AS recent_end,

    -- prior 60 days: (max_date - 90, max_date - 30]
    max_date - INTERVAL '90 days' AS prior_start,
    max_date - INTERVAL '30 days' AS prior_end
  FROM dw_max_date
),
per_customer AS (
  SELECT
    c.customer_id AS customer_identifier,

    -- revenue in prior 60-day window
    SUM(
      CASE
        WHEN d.full_date >  a.prior_start
         AND d.full_date <= a.prior_end
        THEN f.net_amount
        ELSE 0
      END
    ) AS revenue_prior_60_days,

    -- revenue in recent 30-day window (needed to filter)
    SUM(
      CASE
        WHEN d.full_date >  a.recent_start
         AND d.full_date <= a.recent_end
        THEN f.net_amount
        ELSE 0
      END
    ) AS revenue_recent_30_days,

    -- last purchase date (typically: last purchase in the prior window)
    MAX(
      CASE
        WHEN d.full_date >  a.prior_start
         AND d.full_date <= a.prior_end
         AND f.net_amount > 0
        THEN d.full_date
        ELSE NULL
      END
    ) AS last_purchase_date

  FROM dw.fact_sales f
  JOIN dw.dim_date d
    ON f.date_sk = d.date_sk
  JOIN dw.dim_customer c
    ON f.customer_sk = c.customer_sk
  CROSS JOIN dates a
  GROUP BY c.customer_id
)
SELECT
  customer_identifier,
  revenue_prior_60_days,
  last_purchase_date
FROM per_customer
WHERE revenue_prior_60_days > 0
  AND revenue_recent_30_days = 0
ORDER BY revenue_prior_60_days DESC;

 

-- SQL Correction:

--Score: Correct

-- Request 9
-- Question:

-- Request 9/25 [CORPORATE]
-- Business question:
-- Support wants to spot customers who might be struggling with engagement.
-- For the last full calendar month (anchored to max warehouse date),
-- show, per subscription type:
-- - number of distinct customers
-- - average days since their last sale (as of the max warehouse date)
-- Granularity: per subscription type.

-- Expected output:
-- - subscription_type
-- - customer_count
-- - avg_days_since_last_sale

 
 

-- My SQL:

WITH max_dw AS (
  SELECT MAX(full_date) AS max_dw_date
  FROM dw.dim_date
),
last_sale_per_customer AS (
  SELECT
    c.subscription_type,
    c.customer_id,
    MAX(d.full_date) AS last_sale_date
  FROM dw.dim_customer c
  JOIN dw.fact_sales f
    ON c.customer_sk = f.customer_sk
  JOIN dw.dim_date d
    ON f.date_sk = d.date_sk
  GROUP BY 1, 2
)
SELECT
  l.subscription_type,
  COUNT(DISTINCT l.customer_id) AS customer_count,
  AVG((m.max_dw_date - l.last_sale_date))::numeric(10,2) AS avg_days_since_last_sale
FROM last_sale_per_customer l
CROSS JOIN max_dw m
GROUP BY 1
ORDER BY 1;




-- SQL Correction:

-- Score: Partial

WITH max_dwh AS (
  SELECT MAX(full_date)::date AS max_date
  FROM dw.dim_date
),
last_full_month AS (
  SELECT
    (DATE_TRUNC('month', max_date) - INTERVAL '1 month')::date AS month_start,
    (DATE_TRUNC('month', max_date) - INTERVAL '1 day')::date   AS month_end,
    max_date
  FROM max_dwh
),
customers_in_month AS (
  SELECT DISTINCT
    c.subscription_type,
    c.customer_id
  FROM dw.fact_sales f
  JOIN dw.dim_date d
    ON f.date_sk = d.date_sk
  JOIN dw.dim_customer c
    ON f.customer_sk = c.customer_sk
  CROSS JOIN last_full_month m
  WHERE d.full_date::date BETWEEN m.month_start AND m.month_end
),
last_sale_per_customer AS (
  SELECT
    c.customer_id,
    MAX(d.full_date)::date AS last_sale_date
  FROM dw.fact_sales f
  JOIN dw.dim_date d
    ON f.date_sk = d.date_sk
  JOIN dw.dim_customer c
    ON f.customer_sk = c.customer_sk
  GROUP BY c.customer_id
)
SELECT
  cm.subscription_type,
  COUNT(*) AS customer_count,
  AVG((m.max_date - ls.last_sale_date))::numeric(10,2) AS avg_days_since_last_sale
FROM customers_in_month cm
JOIN last_sale_per_customer ls
  ON ls.customer_id = cm.customer_id
CROSS JOIN last_full_month m
GROUP BY cm.subscription_type
ORDER BY cm.subscription_type;
 


-- Request 10
-- Question:

-- Request 10/25 [INTERVIEW]
-- Business question:
-- Revenue Ops wants to measure concentration risk.
-- For the last 6 months (anchored to max warehouse date),
-- calculate what percentage of total revenue comes from the top 10 customers.
-- Return a single row.

-- Expected output:
-- - total_revenue_last_6_months
-- - top10_revenue_last_6_months
-- - top10_revenue_share_pct


 

-- My SQL:

WITH max_date AS (
  SELECT MAX(full_date)::date AS max_dw_date
  FROM dw.dim_date
),
dates AS (
  SELECT
    max_dw_date,
    (max_dw_date - INTERVAL '6 months')::date AS start_date
  FROM max_date
),
revenue_by_customer AS (
  SELECT
    f.customer_sk,
    SUM(f.net_amount) AS customer_revenue_last_6_months
  FROM dw.fact_sales f
  JOIN dw.dim_date d
    ON f.date_sk = d.date_sk
  CROSS JOIN dates da
  WHERE d.full_date BETWEEN da.start_date AND da.max_dw_date
  GROUP BY f.customer_sk
),
total_revenue AS (
  SELECT
    SUM(customer_revenue_last_6_months) AS total_revenue_last_6_months
  FROM revenue_by_customer
),
top10 AS (
  SELECT
    SUM(customer_revenue_last_6_months) AS top10_revenue_last_6_months
  FROM (
    SELECT customer_revenue_last_6_months
    FROM revenue_by_customer
    ORDER BY customer_revenue_last_6_months DESC
    LIMIT 10
  ) t
)
SELECT
  tr.total_revenue_last_6_months,
  t10.top10_revenue_last_6_months,
  ROUND(
    (t10.top10_revenue_last_6_months::numeric / NULLIF(tr.total_revenue_last_6_months::numeric, 0)) * 100,
    2
  ) AS top10_revenue_share_pct
FROM total_revenue tr
CROSS JOIN top10 t10;




-- SQL Correction:

-- Score: Correct
 


-- Request 11
-- Question:

-- Request 11/25 [CORPORATE]
-- Business question:
-- Leadership wants a simple customer growth pulse.
-- Since signup_date is not available,
-- approximate new customers as customers whose first-ever sale
-- occurred in the month.
-- For the last 3 full calendar months (anchored to max warehouse date),
-- report new customers per month and the running total across those months.
-- Granularity: per month.

-- Expected output:
-- - reporting_month
-- - new_customers
-- - running_total_new_customers

 

-- My SQL:



WITH max_full_date AS (
  SELECT MAX(full_date) AS max_date
  FROM dw.dim_date
),
bounds AS (
  SELECT
    date_trunc('month', max_date) AS this_month_start,
    date_trunc('month', max_date) - INTERVAL '3 months' AS start_3_full_months
  FROM max_full_date
),
customers_first AS (
  -- 1) primera compra histórica por cliente
  SELECT
    f.customer_sk,
    MIN(d.full_date) AS first_sale_date
  FROM dw.fact_sales f
  JOIN dw.dim_date d
    ON f.date_sk = d.date_sk
  GROUP BY f.customer_sk
),
monthly_new_customers AS (
  -- 2) nuevos clientes por mes (según su primera compra)
  SELECT
    date_trunc('month', first_sale_date)::date AS reporting_month,
    COUNT(*) AS new_customers
  FROM customers_first
  CROSS JOIN bounds b
  WHERE first_sale_date >= b.start_3_full_months
    AND first_sale_date <  b.this_month_start
  GROUP BY 1
)
SELECT
  reporting_month,
  new_customers,
  SUM(new_customers) OVER (ORDER BY reporting_month) AS running_total_new_customers
FROM monthly_new_customers
ORDER BY reporting_month;





-- SQL Correction:


-- Score: Partial

-- What is missing (important)
--
-- The request specifies "last 3 full calendar months", but your query
-- may return fewer than 3 rows if in any month there were no "new customers"
-- (i.e., no first-ever purchases).
--
-- In corporate reporting, stakeholders usually expect to see all 3 months
-- regardless of activity, even if the value is 0.
--
-- Additionally, "reporting_month" should be consistent (for example,
-- always using the first day of the month is correct practice).
-- It is recommended to explicitly generate the 3 reporting months
-- to ensure completeness and consistent output structure.

WITH max_full_date AS (
  SELECT MAX(full_date)::date AS max_date
  FROM dw.dim_date
),
bounds AS (
  SELECT
    date_trunc('month', max_date)::date AS this_month_start,
    (date_trunc('month', max_date) - INTERVAL '3 months')::date AS start_3_full_months
  FROM max_full_date
),
months AS (
  SELECT generate_series(
           (SELECT start_3_full_months FROM bounds),
           (SELECT this_month_start - INTERVAL '1 month' FROM bounds),
           INTERVAL '1 month'
         )::date AS reporting_month
),
customers_first AS (
  SELECT
    f.customer_sk,
    MIN(d.full_date)::date AS first_sale_date
  FROM dw.fact_sales f
  JOIN dw.dim_date d
    ON f.date_sk = d.date_sk
  GROUP BY f.customer_sk
),
monthly_new_customers AS (
  SELECT
    date_trunc('month', first_sale_date)::date AS reporting_month,
    COUNT(*) AS new_customers
  FROM customers_first
  CROSS JOIN bounds b
  WHERE first_sale_date >= b.start_3_full_months
    AND first_sale_date <  b.this_month_start
  GROUP BY 1
)
SELECT
  m.reporting_month,
  COALESCE(n.new_customers, 0) AS new_customers,
  SUM(COALESCE(n.new_customers, 0)) OVER (ORDER BY m.reporting_month) AS running_total_new_customers
FROM months m
LEFT JOIN monthly_new_customers n
  ON n.reporting_month = m.reporting_month
ORDER BY m.reporting_month;


 
-- Request 12
-- Question:
 

-- My SQL:


-- SQL Correction:
 


-- Request 13
-- Question:
 

-- My SQL:


-- SQL Correction:
 


-- Request 14
-- Question:
 

-- My SQL:


-- SQL Correction:
 


-- Request 15
-- Question:
 

-- My SQL:


-- SQL Correction:
 


-- Request 16
-- Question:
 

-- My SQL:


-- SQL Correction:
 


-- Request 17
-- Question:
 
-- My SQL:


-- SQL Correction:
 


-- Request 18
-- Question:
 

-- My SQL:


-- SQL Correction:
 


-- Request 19
-- Question:
 

-- My SQL:

 
-- SQL Correction:


-- Request 20
-- Question:
 

-- My SQL:


-- SQL Correction:
 


-- Request 21
-- Question:
 

-- My SQL:


-- SQL Correction:
 


-- Request 22
-- Question:
 

-- My SQL:


-- SQL Correction:
 


-- Request 23
-- Question:
 

-- My SQL:


-- SQL Correction:
 


-- Request 24
-- Question:
 

-- My SQL:


-- SQL Correction:
 


-- Request 25
-- Question:
 

-- My SQL:


-- SQL Correction:
 

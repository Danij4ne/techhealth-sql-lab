
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

-- Request 12/25 [INTERVIEW]
-- Business question:
-- Device analytics wants to compare engagement by device type.
-- For the last 8 full calendar weeks (anchored to max warehouse date),
-- return, per device_type:
-- - distinct active customers (is_device_active = 1)
-- - average daily usage minutes (only for active device-days)
-- Granularity: per device_type.

-- Expected output:
-- - device_type
-- - active_customers
-- - avg_daily_usage_minutes

 
 

-- My SQL:



WITH max_time AS(
    SELECT MAX(full_date) AS max_date
    FROM dw.dim_date           
) ,
dates AS(
    SELECT DATE_TRUNC('week', max_date) AS finish_week ,
    DATE_TRUNC('week', max_date) - INTERVAL '8 weeks ' AS start_week
    FROM max_time
)  
SELECT de.device_type , COUNT(DISTINCT f.customer_sk ) AS active_customers ,
AVG(f.usage_minutes)::NUMERIC(10,2) AS avg_daily_usage_minutes
FROM dw.dim_device de 
JOIN dw.fact_device_usage_daily f
ON f.device_sk = de.device_sk
JOIN dw.dim_date d
ON f.date_sk = d.date_sk
CROSS JOIN dates s
WHERE f.is_device_active = TRUE AND d.full_date >= s.start_week AND d.full_date < s.finish_week
GROUP BY de.device_type



-- SQL Correction:

--Score: Correct
 

-- Request 13
-- Question:

-- Request 13/25 [CORPORATE]
-- Business question:
-- Regional leadership wants to understand market mix.
-- For the last full calendar month (anchored to max warehouse date),
-- show, per market:
-- - total revenue
-- - distinct customers
-- Also include each market’s share of total revenue for that month.
-- Granularity: per market.

-- Expected output:
-- - market
-- - total_revenue
-- - distinct_customers
-- - revenue_share_pct


-- My SQL:


WITH max_day AS (
    SELECT MAX(full_date) AS max_date
    FROM dw.dim_date

) ,
last_month AS (
    SELECT 
        DATE_TRUNC('month', max_date) - INTERVAL '1 month' AS month_start,
        DATE_TRUNC('month', max_date) AS month_end
    FROM max_day
    
) ,
revenue_market AS (
    SELECT r.market , SUM(f.net_amount) AS  total_revenue , 
    COUNT(DISTINCT f.customer_sk) AS distinct_customers
    FROM dw.fact_sales f
    JOIN dw.dim_region r
    ON f.region_sk = r.region_sk
    JOIN dw.dim_date d
    ON f.date_sk = d.date_sk
    CROSS JOIN last_month l
    WHERE d.full_date >= l.month_start AND d.full_date < l.month_end
    GROUP BY r.market
)
SELECT market , total_revenue , distinct_customers , 
ROUND(100.0 * total_revenue / NULLIF(SUM(total_revenue) OVER (), 0),2 ) AS revenue_share_pct
FROM revenue_market
ORDER BY total_revenue DESC;



-- SQL Correction:
 
 --Score: Correct


-- Request 14
-- Question:

-- Request 14/25 [INTERVIEW]
-- Business question:
-- Product wants to see whether discounts are being used strategically.
-- For the last 6 full calendar months (anchored to max warehouse date),
-- return, per product_category:
-- - total revenue
-- - average discount rate (weighted by revenue before discount)
-- Granularity: per product_category.

-- Expected output:
-- - product_category
-- - total_revenue
-- - weighted_avg_discount_rate
 

-- My SQL:



WITH max_dates AS (
    SELECT MAX(full_date) AS max_date                  
    FROM dw.dim_date

),
calendar_months AS(
    SELECT 
    DATE_TRUNC('month',max_date) AS end_month ,
    DATE_TRUNC('month',max_date) - INTERVAL '6 months' AS start_month
    FROM max_dates
    
)
SELECT d.product_category , SUM(f.net_amount) AS total_revenue , 
  ROUND( SUM(f.quantity * f.unit_price * f.discount) / SUM(f.quantity * f.unit_price),2) AS weighted_avg_discount
  FROM dw.fact_sales f
  JOIN dw.dim_product d
  ON f.product_sk = d.product_sk
  JOIN dw.dim_date a
  ON f.date_sk = a.date_sk
  CROSS JOIN calendar_months c
  WHERE a.full_date >= c.start_month AND a.full_date < c.end_month 
  GROUP BY d.product_category



-- SQL Correction:
 
 --Score: Partial

 -- ==========================================
-- Notes: Adjustments for weighted_avg_discount_rate
-- ==========================================

-- 1) Ensure metric name matches the requirement exactly:
--    Use alias: weighted_avg_discount_rate

-- 2) Clarify discount scale:
--    If discount is stored as 10 = 10%, result will be 0–100 scale.
--    If discount is stored as 0.10 = 10%, result will be 0–1 scale.
--    Choose one scale and be consistent (report-ready usually 0–100).

-- 3) Make division NULL-safe:
--    Use NULLIF() in denominator to prevent division-by-zero errors.

-- 4) Optional: Multiply by 100.0
--    Only if discount is stored as decimal (0–1)
--    and reporting requires percentage (0–100).

-- 5) Add stable ORDER BY when using GROUP BY:
--    Corporate-style queries should return deterministic ordering.

WITH max_dates AS (
    SELECT MAX(full_date)::date AS max_date
    FROM dw.dim_date
),
bounds AS (
    SELECT
        (date_trunc('month', max_date))::date AS end_month,
        (date_trunc('month', max_date) - INTERVAL '6 months')::date AS start_month
    FROM max_dates
)
SELECT
    p.product_category AS product_category,
    SUM(f.net_amount) AS total_revenue,
    ROUND(
        (SUM(f.quantity * f.unit_price * f.discount)::numeric
         / NULLIF(SUM(f.quantity * f.unit_price)::numeric, 0)),
        4
    ) AS weighted_avg_discount_rate
FROM dw.fact_sales f
JOIN dw.dim_product p
    ON f.product_sk = p.product_sk
JOIN dw.dim_date d
    ON f.date_sk = d.date_sk
CROSS JOIN bounds b
WHERE d.full_date::date >= b.start_month
  AND d.full_date::date <  b.end_month
GROUP BY p.product_category
ORDER BY total_revenue DESC, product_category;


-- Request 15
-- Question:

-- Request 15/25 [CORPORATE]
-- Business question:
-- Executive team wants a simple cross-domain view of value vs engagement.
-- For the last full calendar month (anchored to max warehouse date),
-- show, per subscription type:
-- - total revenue
-- - distinct active customers (customers with at least 1 active device-day)
-- Granularity: per subscription type.

-- Expected output:
-- - subscription_type
-- - total_revenue
-- - active_customers

 

-- My SQL:



WITH max_cal AS (
  SELECT MAX(full_date) AS max_date
  FROM dw.dim_date
),
calendars AS (
  SELECT
    DATE_TRUNC('month', max_date) - INTERVAL '1 month' AS start_month,
    DATE_TRUNC('month', max_date)  AS end_month
  FROM max_cal
) 
SELECT c.subscription_type , SUM(f.net_amount) AS total_revenue , 
COUNT(DISTINCT c.customer_sk ) AS active_customers
FROM dw.dim_customer c
JOIN dw.fact_sales f
ON f.customer_sk = c.customer_sk
JOIN dw.fact_device_usage_daily d
ON d.customer_sk = c.customer_sk
JOIN dw.dim_date a
ON a.date_sk = d.date_sk
CROSS JOIN calendars s
WHERE a.full_date >= s.start_month AND a.full_date < s.end_month AND d.is_device_active = True
GROUP BY c.subscription_type
ORDER BY active_customers DESC






-- SQL Correction:
 
-- Score: Partial

-- IMPORTANT PROBLEM (double counting / revenue inflation)
--
-- Issue:
-- You are doing SUM(f.net_amount) while JOINing fact_sales to fact_device_usage_daily.
--
-- Why it’s a problem:
-- fact_device_usage_daily has multiple rows per customer per month (one per device-day).
-- When you join sales (fact_sales) to device usage (fact_device_usage_daily) by customer_sk,
-- each sales row can be repeated once for every active device-day.
--
-- Example:
-- If a customer has 10 active device-days in the month,
-- their sales rows may appear 10 times in the joined result.
-- SUM(f.net_amount) will then be multiplied by ~10  --> revenue is inflated (double counting).
--
-- Additional note (date filter mismatch):
-- The month filter is applied using a.full_date (from device usage via dim_date),
-- but sales are not filtered to the same month range.
-- This becomes less of an issue once you restructure (e.g., separate aggregates),
-- but in the current query it adds inconsistency.


WITH max_cal AS (
  SELECT MAX(full_date)::date AS max_date
  FROM dw.dim_date
),
month_window AS (
  SELECT
    (date_trunc('month', max_date) - INTERVAL '1 month')::date AS start_month,
    (date_trunc('month', max_date))::date AS end_month
  FROM max_cal
),
revenue_by_sub AS (
  SELECT
    c.subscription_type,
    SUM(f.net_amount) AS total_revenue
  FROM dw.fact_sales f
  JOIN dw.dim_customer c
    ON f.customer_sk = c.customer_sk
  JOIN dw.dim_date d
    ON f.date_sk = d.date_sk
  CROSS JOIN month_window w
  WHERE d.full_date::date >= w.start_month
    AND d.full_date::date <  w.end_month
  GROUP BY c.subscription_type
),
active_customers_by_sub AS (
  SELECT
    c.subscription_type,
    COUNT(DISTINCT ddu.customer_sk) AS active_customers
  FROM dw.fact_device_usage_daily ddu
  JOIN dw.dim_customer c
    ON ddu.customer_sk = c.customer_sk
  JOIN dw.dim_date dd
    ON ddu.date_sk = dd.date_sk
  CROSS JOIN month_window w
  WHERE dd.full_date::date >= w.start_month
    AND dd.full_date::date <  w.end_month
    AND ddu.is_device_active = TRUE
  GROUP BY c.subscription_type
)
SELECT
  COALESCE(r.subscription_type, a.subscription_type) AS subscription_type,
  COALESCE(r.total_revenue, 0) AS total_revenue,
  COALESCE(a.active_customers, 0) AS active_customers
FROM revenue_by_sub r
FULL JOIN active_customers_by_sub a
  ON a.subscription_type = r.subscription_type
ORDER BY active_customers DESC, total_revenue DESC, subscription_type;


-- Request 16
-- Question:

-- Request 16/25 [INTERVIEW]
-- Business question:
-- Retention analytics wants a cohort-based view with “missing activity” explicitly shown.
-- Define cohort_month as the month of a customer’s first-ever sale.
-- Consider cohorts within the last 6 full calendar months (anchored to max warehouse date).
-- For each cohort_month, calculate:
-- - number of customers in the cohort
-- - number of those customers who made at least one purchase in the 2nd calendar month after cohort_month
-- - month2_return_rate_pct
-- Also ensure cohorts with zero month-2 returns still appear.

-- Expected output:
-- - cohort_month
-- - cohort_customers
-- - month2_returning_customers
-- - month2_return_rate_pct
 

-- My SQL:

WITH max_cal AS (
  SELECT MAX(full_date) AS max_date
  FROM dw.dim_date
),
bounds AS (
  SELECT
    DATE_TRUNC('month', max_date) AS end_month,                 
    DATE_TRUNC('month', max_date) - INTERVAL '6 month' AS start_month
  FROM max_cal
),

first_sale AS (
  SELECT
    c.customer_id,
    MIN(d.full_date) AS first_sale_date
  FROM dw.fact_sales f
  JOIN dw.dim_customer c ON c.customer_sk = f.customer_sk
  JOIN dw.dim_date d     ON d.date_sk     = f.date_sk
  GROUP BY c.customer_id
),

cohorts AS (
  SELECT
    fs.customer_id,
    DATE_TRUNC('month', fs.first_sale_date) AS cohort_month
  FROM first_sale fs
),

cohorts_in_scope AS (
  SELECT c.*
  FROM cohorts c
  CROSS JOIN bounds b
  WHERE c.cohort_month >= b.start_month
    AND c.cohort_month <  b.end_month
),


cohort_counts AS (
  SELECT
    cohort_month,
    COUNT(DISTINCT customer_id) AS cohort_customers
  FROM cohorts_in_scope
  GROUP BY cohort_month
),
 
customer_purchase_months AS (
  SELECT DISTINCT
    c.customer_id,
    DATE_TRUNC('month', d.full_date) AS purchase_month
  FROM dw.fact_sales f
  JOIN dw.dim_customer c ON c.customer_sk = f.customer_sk
  JOIN dw.dim_date d     ON d.date_sk     = f.date_sk
),

month2_returns AS (
  SELECT
    ci.cohort_month,
    COUNT(DISTINCT ci.customer_id) AS month2_returning_customers
  FROM cohorts_in_scope ci
  JOIN customer_purchase_months pm
    ON pm.customer_id = ci.customer_id
   AND pm.purchase_month = ci.cohort_month + INTERVAL '2 month'
  GROUP BY ci.cohort_month
)

SELECT
  cc.cohort_month,
  cc.cohort_customers,
  COALESCE(m2.month2_returning_customers, 0) AS month2_returning_customers,
  CASE
    WHEN cc.cohort_customers = 0 THEN 0
    ELSE ROUND(
      (COALESCE(m2.month2_returning_customers, 0) * 100.0) / cc.cohort_customers
      , 2
    )
  END AS month2_return_rate_pct
FROM cohort_counts cc
LEFT JOIN month2_returns m2
  ON m2.cohort_month = cc.cohort_month
ORDER BY cc.cohort_month;



-- SQL Correction:
 
-- Score: Correct


-- Request 17
-- Question:

-- Request 17/25 [CORPORATE]
-- Business question:
-- Finance wants a reconciliation-style report that never hides missing sides.
-- For the last full calendar month (anchored to max warehouse date),
-- produce a per-customer view showing:
-- - customer_identifier
-- - revenue_last_month
-- - active_device_days_last_month
-- - a label that classifies each customer into one of:
--   "Sales only" (revenue > 0 but zero active device-days),
--   "Engagement only" (zero revenue but has active device-days),
--   "Both",
--   "Neither"
-- Important: Customers must appear even if they have sales but no device usage,
-- or device usage but no sales, or neither.
-- Granularity: per customer.

-- Expected output:
-- - customer_identifier
-- - revenue_last_month
-- - active_device_days_last_month
-- - customer_classification


 
-- My SQL:



WITH max_date AS(
    SELECT MAX(full_date) AS max_full_date
    FROM dw.dim_date
    ) ,
months AS (
    SELECT 
    DATE_TRUNC('month',max_full_date) AS finish_month ,
    DATE_TRUNC('month',max_full_date) - INTERVAL '1 month' AS start_month 
    FROM max_date
    ),
customers_data AS (
    SELECT c.customer_id , SUM(f.net_amount) AS revenue_last_month , SUM(u.active_days) AS active_device_days_last_month
    FROM dw.dim_customer c
    LEFT JOIN dw.fact_sales f
    ON c.customer_sk = f.customer_sk
    LEFT JOIN dw.fact_user_engagement_monthly u
    ON c.customer_sk = u.customer_sk
    LEFT JOIN dw.dim_date a
    ON f.date_sk = a.date_sk
    CROSS JOIN months m
    WHERE a.full_date >= m.start_month AND a.full_date < m.finish_month 
    GROUP BY c.customer_id 
) 
SELECT customer_id , revenue_last_month , active_device_days_last_month ,
CASE
    WHEN revenue_last_month > 0 AND  active_device_days_last_month = 0 THEN 'Sales only'
    WHEN revenue_last_month = 0 AND  active_device_days_last_month > 0 THEN 'Engagement only'
    WHEN revenue_last_month > 0 AND  active_device_days_last_month > 0 THEN 'Both'
    WHEN revenue_last_month = 0 AND  active_device_days_last_month = 0 THEN 'Neither'
END AS customer_classification
FROM customers_data




-- SQL Correction:

-- Score: Wrong

-- Used dw.fact_user_engagement_monthly, which is not part of the model we are using.

-- The WHERE a.full_date ... condition applied to a table linked to sales
-- effectively turns the LEFT JOIN on sales into INNER JOIN behavior,
-- so customers without sales are lost.

-- The query does not guarantee customers that have only engagement
-- or customers that have neither sales nor engagement.

-- SUM(u.active_days) can also be duplicated when combined with sales
-- if engagement is not aggregated separately before the join.


 
WITH max_date AS (
    SELECT MAX(full_date)::date AS max_full_date
    FROM dw.dim_date
),
month_window AS (
    SELECT
        (date_trunc('month', max_full_date) - INTERVAL '1 month')::date AS start_month,
        date_trunc('month', max_full_date)::date AS finish_month
    FROM max_date
),
sales_per_customer AS (
    SELECT
        c.customer_id AS customer_identifier,
        SUM(f.net_amount) AS revenue_last_month
    FROM dw.dim_customer c
    JOIN dw.fact_sales f
        ON c.customer_sk = f.customer_sk
    JOIN dw.dim_date d
        ON f.date_sk = d.date_sk
    CROSS JOIN month_window m
    WHERE d.full_date::date >= m.start_month
      AND d.full_date::date <  m.finish_month
    GROUP BY c.customer_id
),
engagement_per_customer AS (
    SELECT
        c.customer_id AS customer_identifier,
        COUNT(DISTINCT CASE WHEN u.is_device_active = TRUE THEN u.date_sk END) AS active_device_days_last_month
    FROM dw.dim_customer c
    JOIN dw.fact_device_usage_daily u
        ON c.customer_sk = u.customer_sk
    JOIN dw.dim_date d
        ON u.date_sk = d.date_sk
    CROSS JOIN month_window m
    WHERE d.full_date::date >= m.start_month
      AND d.full_date::date <  m.finish_month
    GROUP BY c.customer_id
)
SELECT
    c.customer_id AS customer_identifier,
    COALESCE(s.revenue_last_month, 0) AS revenue_last_month,
    COALESCE(e.active_device_days_last_month, 0) AS active_device_days_last_month,
    CASE
        WHEN COALESCE(s.revenue_last_month, 0) > 0
         AND COALESCE(e.active_device_days_last_month, 0) = 0 THEN 'Sales only'
        WHEN COALESCE(s.revenue_last_month, 0) = 0
         AND COALESCE(e.active_device_days_last_month, 0) > 0 THEN 'Engagement only'
        WHEN COALESCE(s.revenue_last_month, 0) > 0
         AND COALESCE(e.active_device_days_last_month, 0) > 0 THEN 'Both'
        ELSE 'Neither'
    END AS customer_classification
FROM dw.dim_customer c
LEFT JOIN sales_per_customer s
    ON c.customer_id = s.customer_identifier
LEFT JOIN engagement_per_customer e
    ON c.customer_id = e.customer_identifier
ORDER BY customer_identifier;

-- Request 18
-- Question:

-- Request 18/25 [INTERVIEW]
-- Business question:
-- Commercial strategy wants a ranking report that compares each product
-- against others inside its own category.
-- For the last 9 full calendar months (anchored to max warehouse date),
-- return all products with:
-- - product_identifier
-- - product_category
-- - total_revenue
-- - revenue_rank_within_category
-- - revenue_gap_vs_category_leader
-- - revenue_share_within_category_pct
-- Include products even if they generated zero revenue in the period.
-- Granularity: per product.

-- Expected output:
-- - product_identifier
-- - product_category
-- - total_revenue
-- - revenue_rank_within_category
-- - revenue_gap_vs_category_leader
-- - revenue_share_within_category_pct
 

-- My SQL:

WITH max_dates AS(
    SELECT MAX(full_date) AS max_date
    FROM dw.dim_date
) ,
dates AS ( 
    SELECT 
    DATE_TRUNC('month',max_date) AS last_month ,
    DATE_TRUNC('month', max_date) - INTERVAL '9 months' AS first_month
    FROM max_dates
),
the_products AS (
    SELECT p.product_id , p.product_category , COALESCE(SUM(f.net_amount),0 )AS total_revenue 
    FROM dw.dim_product p
    LEFT JOIN dw.fact_sales f
    ON p.product_sk = f.product_sk
    LEFT JOIN dw.dim_date d
    ON f.date_sk = d.date_sk
    CROSS JOIN dates a
    WHERE d.full_date >= a.first_month AND d.full_date < a.last_month
    GROUP BY p.product_id , p.product_category
) 
    SELECT product_id, product_category, total_revenue, 
    DENSE_RANK() OVER(PARTITION BY product_category ORDER BY total_revenue DESC) AS revenue_rank_within_category,
    MAX(total_revenue) OVER(PARTITION BY product_category ) - total_revenue AS revenue_gap_vs_category_leader ,
    total_revenue / SUM(total_revenue) OVER (PARTITION BY product_category) * 100 AS revenue_share_within_category_pct
    FROM the_products


-- SQL Correction:

-- Score: Partial

-- The window functions are correctly designed:
-- - DENSE_RANK for ranking products within their category
-- - revenue gap vs category leader
-- - revenue share within the category

-- The time window of the last 9 full calendar months is also correctly defined.

-- However, there is a key issue:

-- Using a WHERE condition on d.full_date (a table joined with LEFT JOIN)
-- effectively converts the LEFT JOIN into INNER JOIN behavior.

-- As a consequence, products with no sales during the period are removed
-- from the result set.

-- This breaks the most important requirement of the task:
-- "Include products even if they generated zero revenue in the period."

-- Additionally, the revenue share percentage may produce NULL values
-- or a conceptual error if the total revenue of a category equals 0.

WITH max_dates AS (
    SELECT MAX(full_date)::date AS max_date
    FROM dw.dim_date
),
bounds AS (
    SELECT
        date_trunc('month', max_date)::date AS last_month,
        (date_trunc('month', max_date) - INTERVAL '9 months')::date AS first_month
    FROM max_dates
),
sales_in_scope AS (
    SELECT
        f.product_sk,
        SUM(f.net_amount) AS total_revenue
    FROM dw.fact_sales f
    JOIN dw.dim_date d
        ON f.date_sk = d.date_sk
    CROSS JOIN bounds b
    WHERE d.full_date::date >= b.first_month
      AND d.full_date::date <  b.last_month
    GROUP BY f.product_sk
),
products_with_revenue AS (
    SELECT
        p.product_id AS product_identifier,
        p.product_category,
        COALESCE(s.total_revenue, 0) AS total_revenue
    FROM dw.dim_product p
    LEFT JOIN sales_in_scope s
        ON p.product_sk = s.product_sk
)
SELECT
    product_identifier,
    product_category,
    total_revenue,
    DENSE_RANK() OVER (
        PARTITION BY product_category
        ORDER BY total_revenue DESC, product_identifier
    ) AS revenue_rank_within_category,
    MAX(total_revenue) OVER (
        PARTITION BY product_category
    ) - total_revenue AS revenue_gap_vs_category_leader,
    ROUND(
        100.0 * total_revenue
        / NULLIF(SUM(total_revenue) OVER (PARTITION BY product_category), 0),
        2
    ) AS revenue_share_within_category_pct
FROM products_with_revenue
ORDER BY product_category, revenue_rank_within_category, product_identifier;


-- Request 19
-- Question:
 
 -- Request 19/25 [CORPORATE]
-- Business question:
-- Operations wants a completeness-style device report that makes gaps visible.
-- For the last 12 full calendar weeks (anchored to max warehouse date),
-- show, per week and per device_type:
-- - total distinct devices
-- - distinct devices with at least one active day
-- - distinct devices with zero activity all week
-- Ensure weeks appear even when a device_type has no active devices in that week.
-- Granularity: per week, per device_type.

-- Expected output:
-- - reporting_week
-- - device_type
-- - total_distinct_devices
-- - devices_with_activity
-- - devices_with_zero_activity

 

-- My SQL:




WITH max_dates AS(
    SELECT MAX(full_date) AS max_date
    FROM dw.dim_date
) ,
weeks AS (
    SELECT
    DATE_TRUNC('week', max_date) AS last_week,
    DATE_TRUNC('week', max_date) - INTERVAL '12 weeks' AS first_week
    FROM max_dates
),
reporting_weeks AS (
    SELECT
        generate_series(
            first_week,
            last_week - INTERVAL '1 week',
            INTERVAL '1 week'
        ) AS reporting_week
    FROM weeks
),
base_device AS (
    SELECT
        d.device_sk,
        d.device_id,
        d.device_type
    FROM dw.dim_device d
),
device_weeks AS (
    SELECT
        rw.reporting_week,
        d.device_sk,
        d.device_id,
        d.device_type
    FROM reporting_weeks rw
    CROSS JOIN base_device d
),
activity_by_device_week AS (
    SELECT
        DATE_TRUNC('week', a.full_date) AS reporting_week,
        f.device_sk
    FROM dw.fact_device_usage_daily f
    JOIN dw.dim_date a
        ON f.date_sk = a.date_sk
    CROSS JOIN weeks w
    WHERE a.full_date >= w.first_week
      AND a.full_date <  w.last_week
    GROUP BY
        DATE_TRUNC('week', a.full_date),
        f.device_sk
),
joined AS (
    SELECT
        dw.reporting_week,
        dw.device_type,
        dw.device_id,
        CASE
            WHEN abw.device_sk IS NOT NULL THEN 1
            ELSE 0
        END AS has_activity
    FROM device_weeks dw
    LEFT JOIN activity_by_device_week abw
        ON dw.reporting_week = abw.reporting_week
       AND dw.device_sk = abw.device_sk
)
SELECT
    reporting_week,
    device_type,
    COUNT(DISTINCT device_id) AS total_distinct_devices,
    COUNT(DISTINCT CASE WHEN has_activity = 1 THEN device_id END) AS devices_with_activity,
    COUNT(DISTINCT CASE WHEN has_activity = 0 THEN device_id END) AS devices_with_zero_activity
FROM joined
GROUP BY
    reporting_week,
    device_type
ORDER BY
    reporting_week,
    device_type;



 
-- SQL Correction:

-- Score: Partial

-- Score: Partial

-- Correct parts of the solution

-- The overall structure is good.
-- You correctly generate the last 12 weeks.

-- CROSS JOIN with devices is used to create all possible combinations
-- of week × device.

-- LEFT JOIN is then used so that combinations without activity
-- are not lost.

-- This satisfies the requirement of showing gaps
-- (weeks where devices had no activity).

-- The metrics below are correctly designed:
-- total_distinct_devices
-- devices_with_zero_activity


-- Main issue in the query

-- The metric devices_with_activity should count devices
-- that had at least one active day during the week.

-- However, in the CTE activity_by_device_week
-- there is no filter for:

-- f.is_device_active = TRUE

-- Because of this, the query currently treats
-- any weekly device record as activity.

-- This means a device can be counted as "active"
-- even if it was inactive during the entire week.


-- Correct logic

-- The activity CTE should filter real activity:

-- WHERE f.is_device_active = TRUE

-- This guarantees that devices_with_activity
-- counts only devices with at least one active day.

WITH max_dates AS (
    SELECT MAX(full_date)::date AS max_date
    FROM dw.dim_date
),
weeks AS (
    SELECT
        date_trunc('week', max_date)::date AS last_week,
        (date_trunc('week', max_date) - INTERVAL '12 weeks')::date AS first_week
    FROM max_dates
),
reporting_weeks AS (
    SELECT generate_series(
        (SELECT first_week FROM weeks),
        (SELECT last_week - INTERVAL '1 week' FROM weeks),
        INTERVAL '1 week'
    )::date AS reporting_week
),
base_device AS (
    SELECT
        d.device_sk,
        d.device_id,
        d.device_type
    FROM dw.dim_device d
),
device_weeks AS (
    SELECT
        rw.reporting_week,
        bd.device_sk,
        bd.device_id,
        bd.device_type
    FROM reporting_weeks rw
    CROSS JOIN base_device bd
),
active_device_by_week AS (
    SELECT
        date_trunc('week', dd.full_date)::date AS reporting_week,
        f.device_sk
    FROM dw.fact_device_usage_daily f
    JOIN dw.dim_date dd
        ON f.date_sk = dd.date_sk
    CROSS JOIN weeks w
    WHERE dd.full_date::date >= w.first_week
      AND dd.full_date::date <  w.last_week
      AND f.is_device_active = TRUE
    GROUP BY 1, 2
),
joined AS (
    SELECT
        dw.reporting_week,
        dw.device_type,
        dw.device_id,
        CASE
            WHEN adw.device_sk IS NOT NULL THEN 1
            ELSE 0
        END AS has_activity
    FROM device_weeks dw
    LEFT JOIN active_device_by_week adw
        ON dw.reporting_week = adw.reporting_week
       AND dw.device_sk = adw.device_sk
)
SELECT
    reporting_week,
    device_type,
    COUNT(DISTINCT device_id) AS total_distinct_devices,
    COUNT(DISTINCT CASE WHEN has_activity = 1 THEN device_id END) AS devices_with_activity,
    COUNT(DISTINCT CASE WHEN has_activity = 0 THEN device_id END) AS devices_with_zero_activity
FROM joined
GROUP BY reporting_week, device_type
ORDER BY reporting_week, device_type;



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
 

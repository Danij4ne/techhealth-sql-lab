
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
 
-- My SQL:


-- SQL Correction:
 


-- Request 5
-- Question:
 

-- My SQL:
 

-- SQL Correction:


-- Request 6
-- Question:
 

-- My SQL:
 

-- SQL Correction:



-- Request 7
-- Question:
 

-- My SQL:
 

-- SQL Correction:




-- Request 8
-- Question:
 

-- My SQL:
 

-- SQL Correction:



-- Request 9
-- Question:
 

-- My SQL:


-- SQL Correction:
 


-- Request 10
-- Question:
 

-- My SQL:


-- SQL Correction:
 


-- Request 11
-- Question:
 

-- My SQL:


-- SQL Correction:
 


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
 

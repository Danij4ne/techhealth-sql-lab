
-- Session 001

-- Request 1
-- Question:

-- Request 1/25 [CORPORATE]
-- Business question:
-- For the last full calendar month (2025-11-01 to 2025-11-30),
-- provide a list of customers who registered during that period.

-- Expected output:
-- - customer identifier
-- - registration date
-- - country
-- - subscription tier


-- My SQL:

 SELECT user_id , registration_date , country , subscription_type 
 FROM dbo.customers
 WHERE registration_date BETWEEN '2025-11-01' AND '2025-11-30';


-- SQL Correction:
 
--Approved ✅


-- Request 2
-- Question:

-- Request 2/25 [INTERVIEW]
-- Business question:
-- Identify customers who have made purchases above their own average purchase value.
-- Return one row per qualifying transaction.

-- Expected output:
-- - customer identifier
-- - sale identifier
-- - transaction amount
-- - customer average transaction amount


-- My SQL:

SELECT s.user_id , s.sale_id , s.total_amount , (
    SELECT AVG(s2.total_amount)
    FROM sales s2
    WHERE s2.user_id = s.user_id
) AS customer_avg_total_amount
FROM sales s
WHERE  s.total_amount > (
     SELECT AVG(s2.total_amount)
    FROM sales s2
    WHERE s2.user_id = s.user_id
)


-- SQL Correction:
 
--Approved ✅

-- Request 3
-- Question:

 -- Request 3/25 [CORPORATE]
-- Business question:
-- For the last 12 months (from 2024-12-01 to 2025-11-30),
-- return total revenue per sales channel.

-- Expected output:
-- - sales channel
-- - total revenue

-- My SQL:

SELECT sales_channel , SUM(total_amount) AS total_revenue
FROM sales
WHERE sale_date BETWEEN '2024-12-01' AND '2025-11-30'
GROUP BY sales_channel


-- SQL Correction:
 
 --Approved ✅

-- Request 4
-- Question:

-- Request 4/25 [INTERVIEW]
-- Business question:
-- Identify customers who own more than one active device.
-- Return one row per qualifying customer.

-- Expected output:
-- - customer identifier
-- - number of active devices


 
-- My SQL:

SELECT user_id , COUNT(device_id) AS devices 
FROM devices 
WHERE device_status = 'Active' 
GROUP BY user_id 
HAVING COUNT(device_id) > 1



-- SQL Correction:
 
--Approved ✅


-- Request 5
-- Question:

-- Request 5/25 [CORPORATE]
-- Business question:
-- For June 2023, identify customers whose average daily steps
-- are above the overall population average for that month.

-- Expected output:
-- - customer identifier
-- - average daily steps
-- - overall average daily steps



-- My SQL:


WITH AvgSteps AS (
    SELECT AVG(avg_daily_steps) AS avg_steps
    FROM HealthMetrics
    WHERE month_date BETWEEN '2023-06-01' AND '2023-06-30'
)
SELECT
    h.user_id,
    h.avg_daily_steps,
    a.avg_steps
FROM HealthMetrics h
CROSS JOIN AvgSteps a
WHERE h.avg_daily_steps > a.avg_steps;

 

-- SQL Correction: 

--Score: Partial

--You nailed the core logic (compute June 2023 population average, compare each customer’s June steps against it, and return the required fields). 
--What’s missing is the June 2023 filter on the main HealthMetrics rows, so your query can accidentally include other months 
--if they exist (and compare them to June’s average), which breaks the “For June 2023” requirement.

-- Best professional solution  

WITH AvgSteps AS (
    SELECT
        AVG(CAST(hm.avg_daily_steps AS DECIMAL(18,2))) AS overall_avg_daily_steps
    FROM dbo.HealthMetrics hm
    WHERE hm.month_date >= '2023-06-01'
      AND hm.month_date <= '2023-06-30'
)
SELECT
    hm.user_id AS customer_identifier,
    hm.avg_daily_steps AS average_daily_steps,
    a.overall_avg_daily_steps AS overall_average_daily_steps
FROM dbo.HealthMetrics hm
CROSS JOIN AvgSteps a
WHERE hm.month_date >= '2023-06-01'
  AND hm.month_date <= '2023-06-30'
  AND hm.avg_daily_steps > a.overall_avg_daily_steps
ORDER BY
    hm.avg_daily_steps DESC,
    hm.user_id ASC;




-- Request 6
-- Question:

-- Request 6/25 [INTERVIEW]
-- Business question:
-- For May 2025 (2025-05-01 to 2025-05-31), find the single most recent purchase per customer.
-- If a customer has multiple purchases on the same latest day, pick the one with the highest transaction amount.
-- Return one row per customer.

-- Expected output:
-- - customer identifier
-- - sale identifier
-- - sale date
-- - transaction amount


 
-- My SQL:

WITH ranks AS (
    SELECT
        user_id, sale_id, sale_date, total_amount,
        ROW_NUMBER() OVER(
            PARTITION BY user_id
            ORDER BY sale_date DESC, total_amount DESC
        ) AS rn
    FROM sales
    WHERE sale_date >= '2025-05-01'
      AND sale_date <  '2025-06-01'
)
SELECT
    user_id, sale_id, sale_date, total_amount
FROM ranks
WHERE rn = 1;
 

-- SQL Correction:

--Approved ✅


-- Request 7
-- Question:

-- Request 7/25 [CORPORATE]
-- Business question:
-- For each subscription tier, calculate the total number of customers
-- and the average customer age.
-- Return one row per subscription tier.

-- Expected output:
-- - subscription tier
-- - total customers
-- - average age


-- My SQL:



WITH avg_age_users AS (
    SELECT 
        s.subscription_plan,
        AVG(c.age) AS avg_age
    FROM customers c
    INNER JOIN sales s
        ON c.user_id = s.user_id
    GROUP BY s.subscription_plan
),
total_n_customers AS (
    SELECT 
        s.subscription_plan,
        COUNT(DISTINCT c.user_id) AS number_customers
    FROM customers c
    INNER JOIN sales s
        ON c.user_id = s.user_id
    GROUP BY s.subscription_plan
)
SELECT 
    t.subscription_plan,
    t.number_customers,
    a.avg_age
FROM total_n_customers t
JOIN avg_age_users a
    ON a.subscription_plan = t.subscription_plan;


 

-- SQL Correction:

--Score: Wrong

-- You grouped by purchase subscription_plan from Sales, not the customer’s current subscription tier from Customers (subscription_type).
-- That changes the business meaning, and AVG(c.age) is also biased because the join duplicates customers with multiple sales (so frequent buyers get more weight)

SELECT
    c.subscription_type AS subscription_tier,
    COUNT(*) AS total_customers,
    AVG(CAST(c.age AS DECIMAL(18,2))) AS average_age
FROM dbo.Customers c
GROUP BY
    c.subscription_type
ORDER BY
    c.subscription_type ASC;

--Tip: When the question is “customers by tier,” start from Customers and avoid joining 
--Sales unless it’s explicitly required.



-- Request 8
-- Question:

-- Request 8/25 [INTERVIEW]
-- Business question:
-- For each region, find the single customer who generated the highest total revenue
-- during the last full calendar year (2025-01-01 to 2025-12-31).
-- If there is a tie, pick the customer with the most recent purchase date in that year.
-- Return one row per region.

-- Expected output:
-- - region
-- - customer identifier
-- - total revenue in 2025
-- - most recent purchase date in 2025
 

-- My SQL:

WITH per_customer AS (
  SELECT
      region,
      user_id,
      SUM(total_amount) AS total_revenue_2025,
      MAX(sale_date)    AS last_purchase_2025
  FROM sales
  WHERE sale_date >= '2025-01-01'
    AND sale_date <= '2025-12-31'
  GROUP BY region, user_id
),
ranked AS (
  SELECT
      region,
      user_id,
      total_revenue_2025,
      last_purchase_2025,
      ROW_NUMBER() OVER (
        PARTITION BY region
        ORDER BY total_revenue_2025 DESC, last_purchase_2025 DESC
      ) AS rn
  FROM per_customer
)
SELECT
    region,
    user_id,
    total_revenue_2025,
    last_purchase_2025
FROM ranked
WHERE rn = 1
ORDER BY region;

 

-- SQL Correction:

--Approved ✅



-- Request 9
-- Question:

-- Request 9/25 [CORPORATE]
-- Business question:
-- For June 2023, calculate the average sleep hours per subscription tier.
-- Return one row per subscription tier.

-- Expected output:
-- - subscription tier
-- - average sleep hours


-- My SQL:

SELECT
    c.subscription_type AS subscription_tier,
    AVG(CAST(h.avg_sleep_hours AS DECIMAL(18,2))) AS average_sleep_hours
FROM dbo.Customers c
JOIN dbo.HealthMetrics h
  ON h.user_id = c.user_id
WHERE h.month_date >= '2023-06-01'
  AND h.month_date <= '2023-06-30'
GROUP BY
    c.subscription_type
ORDER BY
    c.subscription_type;





-- SQL Correction:
 
--Approved ✅

-- Request 10
-- Question:
 
-- Request 10/25 [INTERVIEW]
-- Business question:
-- Identify customers whose total number of workouts recorded on their devices
-- is above the average across all customers.
-- Return one row per qualifying customer.

-- Expected output:
-- - customer identifier
-- - total workouts recorded
-- - overall average workouts



-- My SQL:

SELECT
    d.user_id,
    SUM(d.total_workouts_recorded) AS total_workouts
FROM Devices d
GROUP BY d.user_id
HAVING SUM(d.total_workouts_recorded) >
       (
         SELECT AVG(total_workouts)
         FROM (
             SELECT SUM(total_workouts_recorded) AS total_workouts
             FROM Devices
             GROUP BY user_id
         ) t
       )
ORDER BY total_workouts DESC;



-- SQL Correction:
 
--Approved ✅


-- Request 11
-- Question:

-- Request 11/25 [CORPORATE]
-- Business question:
-- For the last 90 days ending on 2025-05-08 (i.e., 2025-02-07 to 2025-05-08),
-- list customers who have an Active device but recorded zero total steps on that device.
-- Return one row per device.

-- Expected output:
-- - customer identifier
-- - device identifier
-- - device type
-- - purchase date
-- - total steps recorded

 

-- My SQL:


 SELECT user_id , device_id , device_type , purchase_date , total_steps_recorded 
 FROM Devices
 WHERE purchase_date BETWEEN '2025-02-07' 
 AND '2025-05-08' 
 AND Device_status = 'Active' 
 AND total_steps_recorded = 0



-- SQL Correction:
 
-- Score: Partial

--Why:

--Correctly filters Active devices ✔️

--Correctly identifies zero total steps ✔️

--Correct fields returned ✔️

--❌ Date logic issue: the business question is about the last 90 days ending on 2025-05-08, but that refers to the period of interest, 
--not necessarily the purchase date. Using purchase_date incorrectly excludes devices purchased earlier but still active during that window.

SELECT
    d.user_id AS customer_identifier,
    d.device_id AS device_identifier,
    d.device_type,
    d.purchase_date,
    d.total_steps_recorded
FROM dbo.Devices d
WHERE d.device_status = 'Active'
  AND d.total_steps_recorded = 0
  AND d.last_sync_date >= '2025-02-07'
  AND d.last_sync_date <= '2025-05-08'
ORDER BY
    d.user_id,
    d.device_id;




-- Request 12
-- Question:

-- Request 12/25 [INTERVIEW]
-- Business question:
-- For each customer, determine whether they are a "High Activity" user.
-- A customer is considered "High Activity" if:
--   - Their average daily steps in June 2023 are above the overall June 2023 average, AND
--   - Their total workouts recorded across all devices are above the overall customer average.
-- Return one row per customer.

-- Expected output:
-- - customer identifier
-- - average daily steps (June 2023)
-- - total workouts recorded
-- - activity classification (High Activity / Not High Activity)

 

 

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
 

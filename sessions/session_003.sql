
-- Session 001

-- Request 1
-- Question:

-- 🔹 Request 1/25 [MID]
-- Type: Realistic
-- Estimated solve time: 7 min
-- Main skill tested: Aggregation + time filtering

-- Business question:
-- The finance team wants to understand recent performance.
-- For the last full calendar month, calculate the total revenue generated.

-- Expected output:
-- total_revenue

-- Granularity:
-- Single row (entire business for last full calendar month)

 

-- My SQL:


WITH maxs_date AS(
    SELECT MAX(full_date) AS max_date
    FROM dw.dim_date
),
the_month AS(
    SELECT
    date_trunc('month',max_date) AS finish_month,
    date_trunc('month',max_date) - INTERVAL '1 month' AS start_month
    FROM maxs_date
)
SELECT SUM(f.net_amount) AS total_amount_last_month
FROM dw.fact_sales f
JOIN dw.dim_date d
ON d.date_sk = f.date_sk
CROSS JOIN the_month m
WHERE d.full_date >= m.start_month AND d.full_date < m.finish_month



-- SQL Correction:

-- Verdict: Correct
-- Interview pass likelihood: Likely Pass

-- What is good
-- You anchored the calculation to the warehouse max date, correctly defined the last full calendar month, and filtered with an inclusive lower bound and exclusive upper bound. That is exactly the safe pattern interviewers like to see for calendar-month logic.

-- What is missing or risky
-- Almost nothing important. The only minor thing is naming: the business asked for total_revenue, but your final alias is total_amount_last_month. That is not wrong logically, just a small mismatch with the expected output name.

-- Granularity correctness
-- Correct. Single row for the whole business.

-- Join correctness / duplication risk
-- Correct. Joining fact_sales to dim_date on the date key is safe here, and there is no duplication risk from the way you wrote it.

-- Would this pass in a real interview?
-- Yes.

-- Cleaner version only if needed
-- Only the final alias could be renamed to total_revenue to match the requested output more closely.

-- One short practical tip
-- When the prompt gives expected column names, try to match them exactly.


-- Request 2
-- Question:

-- Request 2/25 [MID]
-- Type: Realistic
-- Estimated solve time: 8 min
-- Main skill tested: Grouping + ranking logic
-- Business question:
-- The commercial team wants to know which product categories are driving the business.
-- For the last full calendar quarter, return the top 3 categories by total revenue.
-- Expected output:
-- - category_name
-- - total_revenue
-- - revenue_rank
-- Granularity:
-- - One row per category for the last full calendar quarter

-- My SQL:



WITH maxs_date AS(
    SELECT MAX(full_date) AS max_date
    FROM dw.dim_date
),
the_quarter AS(
    SELECT
    date_trunc('month',max_date) AS finish_quarter,
    date_trunc('month',max_date) - INTERVAL '3 months' AS start_quarter
    FROM maxs_date
),
top_categories AS(
    SELECT p.product_category, SUM(f.net_amount) AS total_revenue
    FROM dw.fact_sales f
    JOIN dw.dim_product p
    ON f.product_sk = p.product_sk
    JOIN dw.dim_date d
    ON d.date_sk = f.date_sk
    CROSS JOIN the_quarter m
    WHERE d.full_date >= m.start_quarter AND d.full_date < m.finish_quarter
    GROUP BY p.product_category
    ORDER BY total_revenue DESC
),
ranking AS(
    SELECT product_category, total_revenue, 
    ROW_NUMBER() OVER( ORDER BY total_revenue DESC) AS revenue_rank
    FROM top_categories
    ORDER BY revenue_rank ASC
)
SELECT product_category, total_revenue, revenue_rank
FROM ranking
ORDER BY revenue_rank ASC
LIMIT 3



-- SQL Correction:

-- Verdict: Correct
-- Interview pass likelihood: Likely Pass

-- What is good
-- You anchored the calculation to the warehouse max date, correctly defined the last full calendar month, and filtered with an inclusive lower bound and exclusive upper bound. That is exactly the safe pattern interviewers like to see for calendar-month logic.

-- What is missing or risky
-- Almost nothing important. The only minor thing is naming: the business asked for total_revenue, but your final alias is total_amount_last_month. That is not wrong logically, just a small mismatch with the expected output name.

-- Granularity correctness
-- Correct. Single row for the whole business.

-- Join correctness / duplication risk
-- Correct. Joining fact_sales to dim_date on the date key is safe here, and there is no duplication risk from the way you wrote it.

-- Would this pass in a real interview?
-- Yes.

-- Cleaner version only if needed
-- Only the final alias could be renamed to total_revenue to match the requested output more closely.

-- One short practical tip
-- When the prompt gives expected column names, try to match them exactly.


-- Request 3
-- Question:

-- Request 3/25 [MID]
-- Type: Realistic
-- Estimated solve time: 9 min
-- Main skill tested: MoM comparison
-- Business question:
-- The growth team wants a simple trend check.
-- Compare revenue for the last full calendar month versus the month before that, and return both months plus the month-over-month revenue change.
-- Expected output:
-- - reporting_month
-- - total_revenue
-- - previous_month_revenue
-- - revenue_change
-- - revenue_change_pct
-- Granularity:
-- - One row per month for the last 2 full calendar months


-- My SQL:



WITH maxs_date AS(
    SELECT MAX(full_date) AS max_date
    FROM dw.dim_date
),
month_bounds AS (
    SELECT
        DATE_TRUNC('month', max_date) AS current_month_start,
        DATE_TRUNC('month', max_date) - INTERVAL '2 month' AS start_2_months_ago
    FROM maxs_date
),
revenue_moths AS(
    SELECT DATE_TRUNC('month',d.full_date) AS reporting_month, SUM(f.net_amount) AS total_revenue
    FROM dw.fact_sales f
    JOIN dw.dim_date d
    ON d.date_sk = f.date_sk
    CROSS JOIN month_bounds m
    WHERE d.full_date >= m.start_2_months_ago AND d.full_date < m.current_month_start
    GROUP BY DATE_TRUNC('month',d.full_date) 
),
lag_calculate as(
    SELECT reporting_month, total_revenue, 
    lag(total_revenue) OVER( ORDER BY reporting_month) AS previous_month_revenue
    FROM revenue_moths
)
SELECT reporting_month, total_revenue, previous_month_revenue, 
total_revenue - previous_month_revenue AS revenue_change,
CASE
    WHEN previous_month_revenue IS NULL OR previous_month_revenue = 0 THEN NULL
    ELSE (total_revenue - previous_month_revenue) * 1.0 / previous_month_revenue
END AS revenue_change_pct
FROM lag_calculate


-- SQL Correction:

-- Verdict: Correct
-- Interview pass likelihood: Likely Pass

-- What is good
-- You defined the last 2 full calendar months correctly, aggregated revenue at month level, and used a lag to compare each month against the previous one. Your percentage change handling is also safe because you protected against null and zero previous revenue.

-- What is missing or risky
-- Only very small things:
--
-- revenue_moths looks like a typo in the CTE name, but it does not affect logic.
-- If the interviewer wanted the percentage in percentage points format, they might expect multiplying by 100, but your current version is still a valid ratio unless they specify formatting.

-- Granularity correctness
-- Correct. One row per month for the last 2 full calendar months.

-- Join correctness / duplication risk
-- Correct. Safe join pattern, no duplication issue.

-- Would this pass in a real interview?
-- Yes.

-- One short practical tip
-- For MoM questions, your pattern is strong: define exact month bounds first, then aggregate, then compare.

 


-- Request 4
-- Question:

-- Request 4/25 [MID]
-- Type: Realistic
-- Estimated solve time: 8 min
-- Main skill tested: COUNT DISTINCT + grouping
-- Business question:
-- The customer success team wants to know how broad adoption was recently.
-- For the last full calendar month, return the number of distinct active customers by market.
-- Expected output:
-- - market
-- - active_customers
-- Granularity:
-- - One row per market for the last full calendar month

 
-- My SQL:


WITH maxs_date AS(
    SELECT MAX(full_date) AS max_date
    FROM dw.dim_date
    
),
month_time AS(
    SELECT
        date_trunc('month', max_date) AS finish_month,
        date_trunc('month', max_date) - INTERVAL '1 month' AS start_month
    FROM maxs_date
)
SELECT r.market , COUNT(DISTINCT f.customer_sk) AS active_customers 
FROM dw.fact_sales f
JOIN dw.dim_region r
ON f.region_sk = r.region_sk
JOIN dw.dim_date d
ON f.date_sk = d.date_sk
CROSS JOIN month_time m
WHERE d.full_date >= m.start_month AND d.full_date < m.finish_month
GROUP BY r.market
ORDER BY active_customers DESC


-- SQL Correction:

-- Verdict: Correct
-- Interview pass likelihood: Likely Pass

-- What is good
-- You used the sales fact table to define activity, filtered to the last full calendar month correctly, grouped by market, and counted distinct customers. That matches the business meaning of active customers well.

-- What is missing or risky
-- Very little. The only thing to watch is whether market truly belongs on dim_region in this schema, but assuming that dimension is correct, your logic is strong.

-- Granularity correctness
-- Correct. One row per market.

-- Join correctness / duplication risk
-- Correct. No duplication issue in the pattern you used.

-- Would this pass in a real interview?
-- Yes.

-- One short practical tip
-- For “active customers,” always first ask yourself what defines activity. In this case, sales activity makes the fact table choice correct.
 


-- Request 5
-- Question:

-- Request 5/25 [MID]
-- Type: Realistic
-- Estimated solve time: 8 min
-- Main skill tested: First event logic
-- Business question:
-- The CRM team wants to understand new customer activation.
-- For each market, count how many customers placed their first-ever order during the last full calendar quarter.
-- Expected output:
-- - market
-- - new_active_customers
-- Granularity:
-- - One row per market
 

-- My SQL:

WITH maxs_date AS (
    SELECT MAX(full_date) AS max_date
    FROM dw.dim_date
),
month_time AS (
    SELECT
        DATE_TRUNC('quarter', max_date) AS finish_quarter,
        DATE_TRUNC('quarter', max_date) - INTERVAL '3 month' AS start_quarter
    FROM maxs_date
),
first_purchase AS (
    SELECT
        f.customer_sk,
        r.market,
        d.full_date,
        ROW_NUMBER() OVER (
            PARTITION BY f.customer_sk
            ORDER BY d.full_date
        ) AS rn
    FROM dw.fact_sales f
    JOIN dw.dim_region r
        ON f.region_sk = r.region_sk
    JOIN dw.dim_date d
        ON f.date_sk = d.date_sk
)
SELECT
    fp.market,
    MIN(fp.full_date) AS time_order,
    COUNT(*) AS active_customers
FROM first_purchase fp
CROSS JOIN month_time m
WHERE fp.rn = 1
  AND fp.full_date >= m.start_quarter
  AND fp.full_date < m.finish_quarter
GROUP BY fp.market
ORDER BY active_customers DESC;
 

-- SQL Correction:

-- Verdict: Partial
-- Interview pass likelihood: Borderline

-- What is good
-- You correctly identified that this is a first-event problem, and you used a row-number pattern to isolate each customer’s first purchase. You also used quarter boundaries correctly this time.

-- What is missing or risky
-- Two main issues:
-- The expected output was just market and new_active_customers, but your result also includes time_order.
-- More importantly, your count is grouped by the market attached to the customer’s first sales row. That can be valid if the business wants the market of the first order itself, but it is worth noticing that this definition depends on the market on that first transaction.
-- Also, the final alias is active_customers, while the requested output was new_active_customers.

-- Granularity correctness
-- Mostly correct, because you ended with one row per market.
-- But including MIN(fp.full_date) AS time_order adds an unnecessary field that is not part of the requested grain.

-- Join correctness / duplication risk
-- Safe enough. No direct duplication problem in your current approach.

-- Would this pass in a real interview?
-- It might pass if the interviewer focuses on the main idea, but they would likely ask you to clean up the output and align it more tightly with the requirement.

-- Cleaner version only if needed
-- The cleaner version would return only:
-- market
-- COUNT(*) AS new_active_customers

-- One short practical tip
-- When you already isolated one row per customer, check the final select very strictly against the requested output and remove extra fields.




-- Request 6
-- Question:

-- Request 6/25 [MID]
-- Type: Realistic
-- Estimated solve time: 7 min
-- Main skill tested: Top N + grouping
-- Business question:
-- The sales team wants to focus on high-value customers.
-- For the last full calendar year, return the top 5 customers by total revenue.
-- Expected output:
-- - customer_id
-- - customer_name
-- - total_revenue
-- - revenue_rank
-- Granularity:
-- - One row per customer for the last full calendar year

 

-- My SQL:



WITH maxs_date AS(
    SELECT MAX(full_date) AS max_date
    FROM dw.dim_date
    
),
year_time AS(
    SELECT
        date_trunc('year', max_date) AS finish_year,
        date_trunc('year', max_date) - INTERVAL '1 years' AS start_year
    FROM maxs_date
),
customers_revenues AS(
    SELECT c.customer_sk , c.customer_id, SUM(f.net_amount) AS total_revenue
    FROM dw.dim_customer c
    JOIN dw.fact_sales f
    ON c.customer_sk = f.customer_sk
    JOIN dw.dim_date d
    ON f.date_sk = d.date_sk
    CROSS JOIN year_time y
    WHERE d.full_date >= y.start_year AND d.full_date < y.finish_year
    GROUP BY c.customer_sk , c.customer_id
)
SELECT customer_sk, customer_id, total_revenue,
ROW_NUMBER() OVER(ORDER BY total_revenue DESC) AS rk
FROM customers_revenues
ORDER BY rk ASC
LIMIT 5


-- SQL Correction:


-- Verdict: Partial
-- Interview pass likelihood: Borderline

-- What is good
-- You used the sales fact table correctly, defined the last full calendar year with proper boundaries, aggregated revenue at customer level, and ranked customers by revenue. The main logic is strong.

-- What is missing or risky
-- The requested output was:

-- customer_id
-- customer_name
-- total_revenue
-- revenue_rank

-- But your query returns:

-- customer_sk
-- customer_id
-- total_revenue
-- rk

-- So the biggest issue is that you did not return customer_name, and you included the surrogate key instead, which is usually not the business-facing field an interviewer wants.

-- Also, the rank alias should match the requested output more closely.

-- Granularity correctness
-- Correct. One row per customer.

-- Join correctness / duplication risk
-- Correct. No duplication risk in this join pattern.

-- Would this pass in a real interview?
-- It shows good reasoning, but many interviewers would mark it partial because the final output does not match the business request closely enough.

-- Cleaner version only if needed
-- The main cleanup is:

-- include customer_name
-- remove customer_sk
-- rename the rank field to revenue_rank

-- One short practical tip
-- At the end of every interview query, compare your final select line by line against the expected output.



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
 

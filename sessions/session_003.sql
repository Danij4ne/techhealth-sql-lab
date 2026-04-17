
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

-- Request 7/25 [MID]
-- Type: Realistic
-- Estimated solve time: 8 min
-- Main skill tested: Exception reporting
-- Business question:
-- The product team wants to identify inactive catalog areas.
-- Return all product categories that had no sales at all during the last full calendar month.
-- Expected output:
-- - category_name
-- Granularity:
-- - One row per category with no sales in the last full calendar month

 

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
),
customers_revenues AS(
    SELECT DISTINCT p.product_category AS category_name 
    FROM dw.dim_product p
    WHERE NOT EXISTS (
        SELECT 1
        FROM (
            SELECT f.product_sk
            FROM dw.fact_sales f
            JOIN dw.dim_date d
            ON f.date_sk = d.date_sk
            CROSS JOIN month_time m
            WHERE d.full_date >= m.start_month AND d.full_date < m.finish_month
        ) f
        WHERE p.product_sk = f.product_sk
    )

) 
SELECT category_name
FROM customers_revenues


-- SQL Correction:

-- Verdict: Partial
-- Interview pass likelihood: Borderline

-- What is good
-- You understood that this is an exception-reporting problem
-- and you correctly started from the product dimension,
-- which is the right side to preserve when looking for categories with no sales.

-- What is missing or risky
-- The main issue is that the business asked for product categories with no sales,
-- but your NOT EXISTS is checking at the product_sk level,
-- while your final output is at the product_category level.

-- That creates a logic mismatch:
-- your query returns categories that contain at least one unsold product
-- but the request wants categories where the entire category had no sales at all

-- So if one product in a category sold and another did not,
-- your query would still return that category, which would be incorrect.

-- Also, the CTE name customers_revenues does not match the business meaning,
-- though that is only a naming issue.

-- Granularity correctness
-- Final output is one row per category,
-- but the filtering logic is not aligned with that grain.
-- This is the key issue.

-- Join correctness / duplication risk
-- No duplication issue,
-- but there is a grain mismatch between the exclusion logic
-- and the requested output.

-- Would this pass in a real interview?
-- Probably not as written,
-- because this is exactly the kind of question where interviewers
-- want to see correct grain thinking.

-- Cleaner version only if needed
-- The main fix is to test absence of sales at the category level,
-- not at the product key level.

-- One short practical tip
-- For “no activity” questions,
-- make sure the anti-join or NOT EXISTS is written
-- at the same grain as the requested output.



WITH maxs_date AS (
    SELECT MAX(full_date) AS max_date
    FROM dw.dim_date
),
month_time AS (
    SELECT
        DATE_TRUNC('month', max_date) AS finish_month,
        DATE_TRUNC('month', max_date) - INTERVAL '1 month' AS start_month
    FROM maxs_date
),
categories_with_sales AS (
    SELECT DISTINCT p.product_category AS category_name
    FROM dw.fact_sales f
    JOIN dw.dim_product p
        ON f.product_sk = p.product_sk
    JOIN dw.dim_date d
        ON f.date_sk = d.date_sk
    CROSS JOIN month_time m
    WHERE d.full_date >= m.start_month
      AND d.full_date < m.finish_month
)
SELECT DISTINCT p.product_category AS category_name
FROM dw.dim_product p
LEFT JOIN categories_with_sales c
    ON p.product_category = c.category_name
WHERE c.category_name IS NULL
ORDER BY category_name;


-- Request 8
-- Question:


-- Request 8/25 [MID]
-- Type: Realistic
-- Estimated solve time: 9 min
-- Main skill tested: Share of total
-- Business question:
-- Leadership wants to understand concentration.
-- For the last full calendar month, show each market’s revenue and its share of total company revenue for that month.
-- Expected output:
-- - market
-- - total_revenue
-- - revenue_share_pct
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
),
market_value AS(
    SELECT r.market, SUM(f.net_amount) AS total_revenue , 
    ( SELECT SUM(f.net_amount) 
        FROM dw.fact_sales f 
        JOIN dw.dim_date d
        ON f.date_sk = d.date_sk
        CROSS JOIN month_time m
        WHERE d.full_date >= m.start_month AND d.full_date < m.finish_month
        ) total
    FROM dw.dim_region r
    JOIN dw.fact_sales f
    ON r.region_sk = f.region_sk
    JOIN dw.dim_date d
    ON f.date_sk = d.date_sk
    CROSS JOIN month_time m
    WHERE d.full_date >= m.start_month AND d.full_date < m.finish_month
    GROUP BY r.market
) 
SELECT market, total_revenue,
ROUND((total_revenue / total) * 100 ,2) AS revenue_share_pct
FROM market_value
ORDER BY revenue_share_pct DESC

-- SQL Correction:

-- Correct

-- Request 9
-- Question:

-- Request 9/25 [MID]
-- Type: Realistic
-- Estimated solve time: 8 min
-- Main skill tested: Customers with no activity
-- Business question:
-- The retention team wants to identify drop-off.
-- Return all customers who had at least one order in the previous full calendar month, but no orders in the last full calendar month.
-- Expected output:
-- - customer_id
-- - customer_name
-- Granularity:
-- - One row per customer
 

-- My SQL:



WITH maxs_date AS(
    SELECT MAX(full_date) AS max_date
    FROM dw.dim_date
    
),
month_time AS(
    SELECT
        date_trunc('month', max_date) AS finish_month,
        date_trunc('month', max_date) - INTERVAL '1 month' AS start_month,
        date_trunc('month', max_date) - INTERVAL '2 month' AS start_month_previous
    FROM maxs_date
),
customer_previous AS(
    SELECT c.customer_sk , c.customer_id 
    FROM dw.dim_customer c
    JOIN dw.fact_sales f
    ON c.customer_sk = f.customer_sk
    JOIN dw.dim_date d
    ON f.date_sk = d.date_sk
    CROSS JOIN month_time m
    WHERE d.full_date >= m.start_month_previous AND  d.full_date < m.start_month
)
    SELECT  c.customer_id 
    FROM customer_previous c
    WHERE  NOT EXISTS (
        SELECT 1 
        FROM dw.fact_sales f
        JOIN dw.dim_date d
        ON f.date_sk = d.date_sk
        CROSS JOIN month_time m
        WHERE f.customer_sk = c.customer_sk AND d.full_date >= m.start_month AND  d.full_date < m.finish_month
    )




-- SQL Correction:

-- The logic is correct: first identify customers active in the previous month
-- and then exclude those who were active in the last month using NOT EXISTS

-- The month boundaries are correctly defined

-- The issue is about granularity:
-- when joining with fact_sales, a customer can appear multiple times
-- if they have multiple purchases in that period

-- Even if customer_id is unique in the dimension,
-- it can be repeated in the JOIN result

-- This causes duplicate rows in the final output
-- (more than one row per customer), which breaks the required grain

-- Solution:
-- add DISTINCT (or GROUP BY) in the CTE to guarantee
-- one single row per customer before applying NOT EXISTS

-- Conclusion:
-- the logic is correct, but deduplication was missing
-- to ensure one row per customer in the final result
 


-- Request 10
-- Question:

-- Request 10/25 [MID]
-- Type: Realistic
-- Estimated solve time: 8 min
-- Main skill tested: Last-event logic
-- Business question:
-- The operations team wants to review recent purchasing behavior.
-- For each customer, return their most recent order date and the revenue of that order.
-- Expected output:
-- - customer_id
-- - last_order_date
-- - last_order_revenue
-- Granularity:
-- - One row per customer
 

-- My SQL:

WITH customers_stacks AS(
    SELECT c.customer_id , f.net_amount AS last_order_revenue , MAX(d.full_date) AS last_order_date 
    FROM dw.dim_customer c
    JOIN dw.fact_sales f
    ON c.customer_sk = f.customer_sk    
    JOIN dw.dim_date d
    ON f.date_sk = d.date_sk
    GROUP BY c.customer_id , f.net_amount
    ORDER BY c.customer_id ASC
),
rank_time AS (
    SELECT customer_id, last_order_revenue , last_order_date,
    ROW_NUMBER() OVER(PARTITION BY customer_id ORDER BY last_order_date DESC) AS rank_time
    FROM customers_stacks
) 
SELECT customer_id, last_order_revenue , last_order_date
    FROM rank_time
    WHERE rank_time = 1
    ORDER BY customer_id ASC

-- SQL Correction:

-- Verdict: Partial
-- Interview pass likelihood: Borderline

-- What is good
-- You understood that this is a last-event problem and that you need one final row per customer.
-- Using a ranking step to keep the latest row per customer is the right overall direction.

-- What is missing or risky
-- The main issue is in the first CTE:

-- GROUP BY c.customer_id, f.net_amount

-- That changes the grain to one row per customer and revenue value, not one row per order.
-- Then MAX(d.full_date) is taken inside each of those groups, which can disconnect the date from the actual latest order row you want.

-- So the query can return the wrong last_order_revenue, because the revenue is not guaranteed to belong to the customer’s true latest order date.

-- Also, ORDER BY inside the first CTE is unnecessary here.

-- Granularity correctness
-- Final output is one row per customer, but the intermediate grain is not safely defined for the business question.

-- Join correctness / duplication risk
-- No major duplication problem from the joins themselves.
-- The risk is a grain mismatch: grouping by revenue before identifying the latest order can produce incorrect pairings between last_order_date and last_order_revenue.

-- Would this pass in a real interview?
-- Usually not fully. Interviewers often care a lot about whether the revenue really comes from the latest order row.

-- Cleaner version only if needed
-- A cleaner and safer version is to rank the actual sales rows first, then keep the latest one per customer:

WITH ranked_orders AS (
    SELECT
        c.customer_id,
        d.full_date AS last_order_date,
        f.net_amount AS last_order_revenue,
        ROW_NUMBER() OVER (
            PARTITION BY c.customer_id
            ORDER BY d.full_date DESC
        ) AS rn
    FROM dw.fact_sales f
    JOIN dw.dim_customer c
        ON f.customer_sk = c.customer_sk
    JOIN dw.dim_date d
        ON f.date_sk = d.date_sk
)
SELECT
    customer_id,
    last_order_date,
    last_order_revenue
FROM ranked_orders
WHERE rn = 1
ORDER BY customer_id;

-- If the schema has a true order identifier and multiple rows can exist on the same date for the same customer,
-- then the best interview version would use that order identifier as an extra tie-breaker in the ranking.

-- One short practical tip
-- For first/last event questions, rank the original event rows first.
-- Do not aggregate before you have identified the exact row you want.



-- Request 11
-- Question:


-- Request 11/25 [MID-HIGH]
-- Type: Standard
-- Estimated solve time: 10 min
-- Main skill tested: Rolling metric
-- Business question:
-- The finance team wants a smoother trend view.
-- For each month in the last 6 full calendar months, return total revenue and the 3-month rolling average of monthly revenue.
-- Expected output:
-- - reporting_month
-- - total_revenue
-- - rolling_3_month_avg_revenue
-- Granularity:
-- - One row per month for the last 6 full calendar months



-- My SQL:





WITH maxs_date AS(
    SELECT MAX(full_date) AS max_date
    FROM dw.dim_date
    
),
month_time AS(
    SELECT
        date_trunc('month', max_date) AS finish_six_month,
        date_trunc('month', max_date) - INTERVAL '6 month' AS start_six_month 
    FROM maxs_date
),
reporting_months AS(
    SELECT DATE_TRUNC('month', d.full_date) AS reporting_month , SUM(f.net_amount) AS total_revenue
    FROM dw.fact_sales f
    JOIN dw.dim_date d
    ON f.date_sk = d.date_sk
    CROSS JOIN month_time o
    WHERE d.full_date >= o.start_six_month AND d.full_date < o.finish_six_month
    GROUP BY DATE_TRUNC('month', d.full_date)

)
SELECT reporting_month, total_revenue ,
    AVG(total_revenue) OVER( ORDER BY reporting_month  ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) AS rolling_3_month_avg_revenue
    FROM reporting_months
    ORDER BY reporting_month


-- SQL Correction:


-- Verdict: Correct
-- Interview pass likelihood: Likely Pass
--
-- What is good
-- You defined the last 6 full calendar months correctly, aggregated revenue at the month level first, and then calculated the rolling 3-month average over those monthly totals. That is exactly the right sequence for this kind of question.
--
-- What is missing or risky
-- Very little. The main thing to be aware of is that this returns only months that exist in the sales data. If the business wanted all 6 calendar months even when one had no sales, you would need to generate the full set of months first and then left join revenue into it. But for a standard interview version, your answer is good.
--
-- Granularity correctness
-- Correct. One row per month.
--
-- Join correctness / duplication risk
-- Correct. You aggregated before applying the rolling calculation, so there is no duplication problem.
--
-- Would this pass in a real interview?
-- Yes.
--
-- One short practical tip
-- For rolling metrics, always aggregate to the reporting grain first, then apply the window calculation.
 


-- Request 12
-- Question:


-- Request 12/25 [MID-HIGH]
-- Type: Standard
-- Estimated solve time: 10 min
-- Main skill tested: Share of category within market
-- Business question:
-- The commercial team wants to understand mix within each market.
-- For the last full calendar quarter, return each category’s revenue and its share of total market revenue within the same market.
-- Expected output:
-- - market
-- - category_name
-- - total_revenue
-- - market_revenue_share_pct
-- Granularity:
-- - One row per market and category for the last full calendar quarter
 

-- My SQL:




WITH maxs_date AS(
    SELECT MAX(full_date) AS max_date
    FROM dw.dim_date
    
),
quarter_time AS(
    SELECT
        date_trunc('quarter', max_date) AS finish_quarter,
        date_trunc('quarter', max_date) - INTERVAL '3 month' AS start_quarter
    FROM maxs_date
),
market_money AS(
    SELECT r.market , p.product_category AS category_name , SUM(f.net_amount) AS total_revenue 
    FROM dw.fact_sales f
    JOIN dw.dim_product p
    ON f.product_sk = p.product_sk
    JOIN dw.dim_region r
    ON f.region_sk = r.region_sk
    JOIN dw.dim_date d
    ON f.date_sk = d.date_sk
    CROSS JOIN quarter_time q
    WHERE d.full_date >= q.start_quarter AND d.full_date < q.finish_quarter
    GROUP BY r.market , p.product_category 
) ,
market_total_value AS(
    SELECT r.market , SUM(f.net_amount) AS total_revenue_market
    FROM dw.fact_sales f
    JOIN dw.dim_region r
    ON f.region_sk = r.region_sk
    JOIN dw.dim_date d
    ON f.date_sk = d.date_sk
    CROSS JOIN quarter_time q
    WHERE d.full_date >= q.start_quarter AND d.full_date < q.finish_quarter
    GROUP BY r.market
) 
SELECT m.market , m.category_name , m.total_revenue ,
ROUND(( m.total_revenue / t.total_revenue_market) * 100 ,2 ) AS market_revenue_share_pct
FROM market_money m
JOIN market_total_value t
ON m.market = t.market
ORDER BY m.market , m.category_name




-- SQL Correction:

-- Verdict: Correct
-- Interview pass likelihood: Likely Pass

-- What is good
-- You defined the last full calendar quarter correctly, aggregated revenue at the required grain of market and category, then separately calculated total market revenue and used it to compute each category’s share within that market. That matches the business question very well.

-- What is missing or risky
-- Very little. The logic is solid. The only minor point is efficiency/readability: since both CTEs scan the same filtered sales data, a cleaner interview version could first build one filtered base set and then aggregate from it. But your current version is fully valid.

-- Granularity correctness
-- Correct. One row per market and category for the last full calendar quarter.

-- Join correctness / duplication risk
-- Correct. You aggregated before joining market-category totals to market totals, so there is no duplication risk here.

-- Would this pass in a real interview?
-- Yes.

-- Cleaner version only if needed
-- Your version is already good. A slightly cleaner version could be:

WITH maxs_date AS (
    SELECT MAX(full_date) AS max_date
    FROM dw.dim_date
),
quarter_time AS (
    SELECT
        DATE_TRUNC('quarter', max_date) AS finish_quarter,
        DATE_TRUNC('quarter', max_date) - INTERVAL '3 month' AS start_quarter
    FROM maxs_date
),
base_sales AS (
    SELECT
        r.market,
        p.product_category AS category_name,
        f.net_amount
    FROM dw.fact_sales f
    JOIN dw.dim_product p
        ON f.product_sk = p.product_sk
    JOIN dw.dim_region r
        ON f.region_sk = r.region_sk
    JOIN dw.dim_date d
        ON f.date_sk = d.date_sk
    CROSS JOIN quarter_time q
    WHERE d.full_date >= q.start_quarter
      AND d.full_date < q.finish_quarter
),
market_category_revenue AS (
    SELECT
        market,
        category_name,
        SUM(net_amount) AS total_revenue
    FROM base_sales
    GROUP BY market, category_name
),
market_revenue AS (
    SELECT
        market,
        SUM(net_amount) AS total_market_revenue
    FROM base_sales
    GROUP BY market
)
SELECT
    mc.market,
    mc.category_name,
    mc.total_revenue,
    ROUND(100.0 * mc.total_revenue / mr.total_market_revenue, 2) AS market_revenue_share_pct
FROM market_category_revenue mc
JOIN market_revenue mr
    ON mc.market = mr.market
ORDER BY mc.market, mc.category_name;

 


-- Request 13
-- Question:

-- Request 13/25 [MID-HIGH]
-- Type: Standard
-- Estimated solve time: 11 min
-- Main skill tested: QoQ comparison
-- Business question:
-- The executive team wants a quarterly performance comparison.
-- For each market, compare revenue in the last full calendar quarter versus the previous full calendar quarter, and return the change.
-- Expected output:
-- - market
-- - last_full_quarter_revenue
-- - previous_full_quarter_revenue
-- - revenue_change
-- - revenue_change_pct
-- Granularity:
-- - One row per market
 

-- My SQL:




WITH maxs_date AS(
    SELECT MAX(full_date) AS max_date
    FROM dw.dim_date
    
),
quarter_time AS(
    SELECT
        date_trunc('quarter', max_date) AS finish_quarter,
        date_trunc('quarter', max_date) - INTERVAL '3 month' AS start_quarter,
        date_trunc('quarter', max_date) - INTERVAL '6 month' AS start_previous_quarter
    FROM maxs_date
),
market_money AS(
    SELECT r.market , SUM(f.net_amount) AS last_full_quarter_revenue
    FROM dw.fact_sales f
    JOIN dw.dim_region r
    ON f.region_sk = r.region_sk
    JOIN dw.dim_date d
    ON f.date_sk = d.date_sk
    CROSS JOIN quarter_time q
    WHERE d.full_date >= q.start_quarter AND d.full_date < q.finish_quarter
    GROUP BY r.market 
) ,
previous_market_money AS(
    SELECT r.market , SUM(f.net_amount) AS previous_full_quarter_revenue
    FROM dw.fact_sales f
    JOIN dw.dim_region r
    ON f.region_sk = r.region_sk
    JOIN dw.dim_date d
    ON f.date_sk = d.date_sk
    CROSS JOIN quarter_time q
    WHERE d.full_date >= q.start_previous_quarter AND d.full_date < q.start_quarter
    GROUP BY r.market
) 
SELECT m.market , m.last_full_quarter_revenue , p.previous_full_quarter_revenue ,
ROUND(( p.previous_full_quarter_revenue - m.last_full_quarter_revenue ),2 ) AS revenue_change ,
ROUND((( p.previous_full_quarter_revenue - m.last_full_quarter_revenue) / m.last_full_quarter_revenue ) * 100 ,2 ) AS revenue_change_pct
FROM market_money m
JOIN previous_market_money p
ON m.market = p.market
ORDER BY m.market 




-- SQL Correction:

-- Verdict: Partial
-- Interview pass likelihood: Borderline

-- What is good
-- You defined the quarter boundaries correctly, calculated revenue separately for the last full quarter and the previous full quarter, and returned one row per market. The overall structure is strong and interview-reasonable.

-- What is missing or risky
-- The main issue is the change formula.

-- You wrote:
-- p.previous_full_quarter_revenue - m.last_full_quarter_revenue

-- That reverses the usual business definition of change.
-- Normally, for a comparison like this, the expected logic is:

-- revenue_change = last_full_quarter_revenue - previous_full_quarter_revenue
-- revenue_change_pct = (last_full_quarter_revenue - previous_full_quarter_revenue) / previous_full_quarter_revenue

-- So your current query gives the sign backwards, and the percentage denominator is also based on the wrong side.

-- Also, using an inner join means you only keep markets that exist in both quarters. In many interview settings that is acceptable, but a more complete version would preserve markets even if they existed in only one of the two quarters.

-- Granularity correctness
-- Correct. One row per market.

-- Join correctness / duplication risk
-- Good. You aggregated before joining, so there is no duplication risk.

-- Would this pass in a real interview?
-- It shows good structure, but many interviewers would mark it partial because the final business metric is directionally wrong.

-- Cleaner version only if needed
-- Here is a cleaner corrected version:

WITH maxs_date AS (
    SELECT MAX(full_date) AS max_date
    FROM dw.dim_date
),
quarter_time AS (
    SELECT
        DATE_TRUNC('quarter', max_date) AS finish_quarter,
        DATE_TRUNC('quarter', max_date) - INTERVAL '3 month' AS start_quarter,
        DATE_TRUNC('quarter', max_date) - INTERVAL '6 month' AS start_previous_quarter
    FROM maxs_date
),
last_quarter_revenue AS (
    SELECT
        r.market,
        SUM(f.net_amount) AS last_full_quarter_revenue
    FROM dw.fact_sales f
    JOIN dw.dim_region r
        ON f.region_sk = r.region_sk
    JOIN dw.dim_date d
        ON f.date_sk = d.date_sk
    CROSS JOIN quarter_time q
    WHERE d.full_date >= q.start_quarter
      AND d.full_date < q.finish_quarter
    GROUP BY r.market
),
previous_quarter_revenue AS (
    SELECT
        r.market,
        SUM(f.net_amount) AS previous_full_quarter_revenue
    FROM dw.fact_sales f
    JOIN dw.dim_region r
        ON f.region_sk = r.region_sk
    JOIN dw.dim_date d
        ON f.date_sk = d.date_sk
    CROSS JOIN quarter_time q
    WHERE d.full_date >= q.start_previous_quarter
      AND d.full_date < q.start_quarter
    GROUP BY r.market
)
SELECT
    l.market,
    l.last_full_quarter_revenue,
    p.previous_full_quarter_revenue,
    l.last_full_quarter_revenue - p.previous_full_quarter_revenue AS revenue_change,
    CASE
        WHEN p.previous_full_quarter_revenue IS NULL
          OR p.previous_full_quarter_revenue = 0 THEN NULL
        ELSE ROUND(
            100.0 * (l.last_full_quarter_revenue - p.previous_full_quarter_revenue)
            / p.previous_full_quarter_revenue,
            2
        )
    END AS revenue_change_pct
FROM last_quarter_revenue l
JOIN previous_quarter_revenue p
    ON l.market = p.market
ORDER BY l.market;


-- Request 14
-- Question:

-- Request 14/25 [MID-HIGH]
-- Type: Standard
-- Estimated solve time: 10 min
-- Main skill tested: Ranking within group
-- Business question:
-- The regional directors want to see category leaders in each market.
-- For the last full calendar year, return the top 2 categories by revenue within each market.
-- Expected output:
-- - market
-- - category_name
-- - total_revenue
-- - category_rank_in_market
-- Granularity:
-- - One row per market and category among the top 2 per market
 

-- My SQL:


WITH maxs_date AS(
    SELECT MAX(full_date) AS max_date
    FROM dw.dim_date
    
),
year_time AS(
    SELECT
        date_trunc('year', max_date) AS finish_year,
        date_trunc('year', max_date) - INTERVAL '1 year' AS start_year
    FROM maxs_date
),
markets_revenue AS(
    SELECT r.market , p.product_category AS category_name , SUM(f.net_amount) AS total_revenue
    FROM dw.fact_sales f
    JOIN dw.dim_product p
    ON f.product_sk = p.product_sk
    JOIN dw.dim_region r
    ON f.region_sk = r.region_sk
    JOIN dw.dim_date d
    ON f.date_sk = d.date_sk
    CROSS JOIN year_time y
    WHERE d.full_date >= y.start_year AND d.full_date <= y.finish_year
    GROUP BY r.market , p.product_category

),
ranking_markets AS(
    SELECT market, category_name, total_revenue, 
    ROW_NUMBER() OVER( PARTITION BY market ORDER BY total_revenue DESC) AS category_rank_in_market
    FROM markets_revenue
    ORDER BY market
)
SELECT market, category_name, total_revenue,category_rank_in_market
FROM ranking_markets
WHERE category_rank_in_market = 1 OR category_rank_in_market = 2


-- SQL Correction:

-- Verdict: Partial
-- Interview pass likelihood: Borderline

-- What is good
-- You used the correct fact table, grouped at the required grain of market and category, and ranked categories within each market. The overall structure is strong and realistic for an interview.

-- What is missing or risky
-- The main issue is the date filter:
-- WHERE d.full_date >= y.start_year AND d.full_date <= y.finish_year
-- If finish_year is the first day of the current year, using <= can include that boundary date, which would leak one day from the current year into the result. For “last full calendar year,” the safe pattern is:
-- d.full_date >= start_year AND d.full_date < finish_year

-- Also, this line is unnecessary:
-- ORDER BY market
-- inside the ranking_markets CTE.

-- Your final filter works, but this is cleaner:
-- WHERE category_rank_in_market <= 2

-- Granularity correctness
-- Correct. One row per market and category among the top 2 per market.

-- Join correctness / duplication risk
-- Correct. No duplication risk here because you aggregated before ranking.

-- Would this pass in a real interview?
-- It could pass with some interviewers, but the boundary condition is important enough that many would mark it partial.

-- Cleaner version only if needed
-- Here is the corrected cleaner version:

WITH maxs_date AS (
    SELECT MAX(full_date) AS max_date
    FROM dw.dim_date
),
year_time AS (
    SELECT
        DATE_TRUNC('year', max_date) AS finish_year,
        DATE_TRUNC('year', max_date) - INTERVAL '1 year' AS start_year
    FROM maxs_date
),
market_category_revenue AS (
    SELECT
        r.market,
        p.product_category AS category_name,
        SUM(f.net_amount) AS total_revenue
    FROM dw.fact_sales f
    JOIN dw.dim_product p
        ON f.product_sk = p.product_sk
    JOIN dw.dim_region r
        ON f.region_sk = r.region_sk
    JOIN dw.dim_date d
        ON f.date_sk = d.date_sk
    CROSS JOIN year_time y
    WHERE d.full_date >= y.start_year
      AND d.full_date < y.finish_year
    GROUP BY r.market, p.product_category
),
ranked_categories AS (
    SELECT
        market,
        category_name,
        total_revenue,
        ROW_NUMBER() OVER (
            PARTITION BY market
            ORDER BY total_revenue DESC
        ) AS category_rank_in_market
    FROM market_category_revenue
)
SELECT
    market,
    category_name,
    total_revenue,
    category_rank_in_market
FROM ranked_categories
WHERE category_rank_in_market <= 2
ORDER BY market, category_rank_in_market;



-- Request 15
-- Question:
 
-- Request 15/25 [MID-HIGH]
-- Type: Standard
-- Estimated solve time: 11 min
-- Main skill tested: Multi-step aggregation
-- Business question:
-- The finance team wants to compare order quality across markets.
-- For the last full calendar quarter, return each market’s:
-- - total orders
-- - total revenue
-- - average revenue per order
-- Expected output:
-- - market
-- - total_orders
-- - total_revenue
-- - avg_revenue_per_order
-- Granularity:
-- - One row per market


-- My SQL:




WITH maxs_date AS(
    SELECT MAX(full_date) AS max_date
    FROM dw.dim_date
    
),
quarter_time AS(
    SELECT
        date_trunc('quarter', max_date) AS finish_quarter,
        date_trunc('quarter', max_date) - INTERVAL '3 months' AS start_quarter
    FROM maxs_date
),
markets_revenue AS(
    SELECT r.market , COUNT(f.sale_id) AS total_orders , SUM(f.net_amount) AS total_revenue
    FROM dw.fact_sales f
    JOIN dw.dim_region r
    ON f.region_sk = r.region_sk
    JOIN dw.dim_date d
    ON f.date_sk = d.date_sk
    CROSS JOIN quarter_time y
    WHERE d.full_date >= y.start_quarter AND d.full_date < y.finish_quarter
    GROUP BY r.market 

),
ranking_markets AS(
    SELECT market, total_orders, total_revenue, 
    ROUND(total_revenue / NULLIF(total_orders,0),2) AS avg_revenue_per_order
    FROM markets_revenue
    ORDER BY market
)
SELECT market, total_orders, total_revenue, avg_revenue_per_order
FROM ranking_markets
ORDER BY market


-- SQL Correction:

-- Verdict
-- Correct
-- Interview pass likelihood: Likely Pass


-- What is good
-- You used the correct fact table
-- You filtered the last full calendar quarter correctly
-- You grouped at the market level
-- You returned all three requested business metrics:

-- total orders
-- total revenue
-- average revenue per order

-- Your average calculation is also safe because you protected against division by zero.


-- What is missing or risky
-- Very little

-- The only small point:
-- The second CTE name ranking_markets is not really doing any ranking
-- This is a naming mismatch rather than a logic problem

-- Also:
-- ORDER BY market inside that CTE is unnecessary


-- Granularity correctness
-- Correct
-- One row per market


-- Join correctness / duplication risk
-- Correct
-- No duplication risk here


-- Would this pass in a real interview?
-- Yes


-- Cleaner version only if needed
-- Your query is already valid
-- A slightly cleaner version would be:


WITH maxs_date AS (
    SELECT MAX(full_date) AS max_date
    FROM dw.dim_date
),
quarter_time AS (
    SELECT
        DATE_TRUNC('quarter', max_date) AS finish_quarter,
        DATE_TRUNC('quarter', max_date) - INTERVAL '3 months' AS start_quarter
    FROM maxs_date
),
market_metrics AS (
    SELECT
        r.market,
        COUNT(f.sale_id) AS total_orders,
        SUM(f.net_amount) AS total_revenue
    FROM dw.fact_sales f
    JOIN dw.dim_region r
        ON f.region_sk = r.region_sk
    JOIN dw.dim_date d
        ON f.date_sk = d.date_sk
    CROSS JOIN quarter_time q
    WHERE d.full_date >= q.start_quarter
      AND d.full_date < q.finish_quarter
    GROUP BY r.market
)
SELECT
    market,
    total_orders,
    total_revenue,
    ROUND(total_revenue / NULLIF(total_orders, 0), 2) AS avg_revenue_per_order
FROM market_metrics
ORDER BY market;
 


-- Request 16
-- Question:

-- Request 16/25 [MID-HIGH]
-- Type: Standard
-- Estimated solve time: 10 min
-- Main skill tested: Unusual pattern detection
-- Business question:
-- The strategy team wants to spot concentration risk.
-- For the last full calendar year, identify markets where a single category generated more than 50% of total market revenue.
-- Expected output:
-- - market
-- - category_name
-- - category_revenue
-- - market_revenue
-- - category_share_pct
-- Granularity:
-- - One row per market and category meeting the condition
 

-- My SQL:




WITH maxs_date AS(
    SELECT MAX(full_date) AS max_date
    FROM dw.dim_date
    
),
quarter_time AS(
    SELECT
        date_trunc('year', max_date) AS finish_year,
        date_trunc('year', max_date) - INTERVAL '1 year' AS start_year
    FROM maxs_date
),
category_revenues AS(
    SELECT r.market , p.product_category AS category_name , SUM(f.net_amount) AS category_revenue
    FROM dw.fact_sales f
    JOIN dw.dim_region r
    ON f.region_sk = r.region_sk
    JOIN dw.dim_product p
    ON f.product_sk = p.product_sk
    JOIN dw.dim_date d
    ON f.date_sk = d.date_sk
    CROSS JOIN quarter_time y
    WHERE d.full_date >= y.start_year AND d.full_date < y.finish_year
    GROUP BY r.market, p.product_category 
),
markets_revenue AS(
    SELECT market, category_name, category_revenue ,
    SUM(category_revenue) OVER(PARTITION BY market) AS market_revenue
    FROM category_revenues
),
identify_markets AS (
    SELECT market , category_name , category_revenue, market_revenue ,
    ROUND((category_revenue / NULLIF(market_revenue,0) ) * 100,2) AS category_share_pct
    FROM markets_revenue
)
SELECT market, category_name, category_revenue, market_revenue, category_share_pct
FROM identify_markets
WHERE category_share_pct >50
ORDER BY market 


-- SQL Correction:

-- VERDICT
-- Result: Correct
-- Interview pass likelihood: Likely Pass

-- WHAT IS GOOD
-- Correct time filtering:
-- Last full calendar year is properly defined

-- Correct aggregation strategy:
-- Category revenue aggregated at (market, category) level

-- Proper use of window function:
-- Total market revenue derived using window aggregation

-- Business logic:
-- Correct computation of category share within each market

-- Overall:
-- Efficient and well-structured solution
-- Suitable for concentration-risk type questions


-- WHAT IS MISSING OR RISKY
-- Naming issue:
-- CTE "quarter_time" is misleading
-- It actually represents YEAR boundaries

-- Suggested improvement:
-- Rename to "year_time" for clarity

-- Impact:
-- No effect on logic
-- Only affects readability


-- GRANULARITY CORRECTNESS
-- Output grain:
-- One row per (market, category)

-- Condition:
-- Only rows meeting the business requirement are returned


-- JOIN CORRECTNESS / DUPLICATION RISK
-- Safe aggregation order:
-- First aggregate at (market, category)
-- Then derive total market revenue

-- Result:
-- No duplication risk
-- Clean and controlled joins


-- FINAL INTERVIEW VERDICT
-- Would this pass in a real interview?
-- Yes

 
-- Request 17
-- Question:


-- Request 17/25 [MID-HIGH]
-- Type: Standard
-- Estimated solve time: 11 min
-- Main skill tested: First purchase by category
-- Business question:
-- The product team wants to understand acquisition behavior.
-- For each customer, return the category of their first-ever purchased product and the date of that first purchase.
-- Expected output:
-- - customer_id
-- - first_purchase_date
-- - first_category_name
-- Granularity:
-- - One row per customer
 
-- My SQL:



WITH customers_pr AS (
    SELECT c.customer_id , MIN(d.full_date) AS first_purchase_date , p.product_category AS category_name  
    FROM dw.fact_sales f
    JOIN dw.dim_customer c
    ON f.customer_sk = c.customer_sk
    JOIN dw.dim_product p
    ON f.product_sk = p.product_sk
    JOIN dw.dim_date d
    ON f.date_sk = d.date_sk
    GROUP BY c.customer_id , p.product_category 
),
ranks_time AS(
    SELECT customer_id , first_purchase_date , category_name ,
    ROW_NUMBER() OVER(PARTITION BY customer_id ORDER BY first_purchase_date ) AS rt
    FROM customers_pr
)
SELECT customer_id , first_purchase_date , category_name 
FROM ranks_time
WHERE rt = 1
ORDER BY customer_id 



-- SQL Correction:

-- Verdict: Partial
-- Interview pass likelihood: Borderline

-- What is good
-- You understood that the final output must be one row per customer, and you tried to identify the earliest category/date combination per customer.
-- The overall direction is reasonable.

-- What is missing or risky
-- The main issue is that you aggregated too early at this grain:

-- GROUP BY c.customer_id, p.product_category

-- That gives you the first date per customer and category, not the first actual purchase row for the customer.

-- Then you rank those category-level minimum dates and keep one row.
-- That often works, but it is not fully safe because:

-- you are no longer selecting the exact original first purchase row
-- if multiple categories were bought on the same first date, the result is not deterministic
-- the selected category is not guaranteed to reflect a clean tie-break rule

-- Also, the expected output asked for first_category_name, but your final column is still named category_name.

-- Granularity correctness
-- Final output is one row per customer, which is good.
-- But the intermediate grain is not the true event grain needed for a first-purchase question.

-- Join correctness / duplication risk
-- No join duplication problem, but there is an event-grain problem.
-- For first/last event questions, it is safer to rank the original sales rows first, then keep the first row.

-- Would this pass in a real interview?
-- It might get partial credit, but many interviewers would want a more precise first-event solution.

-- Cleaner version only if needed
-- A safer version is:

WITH ranked_purchases AS (
    SELECT
        c.customer_id,
        d.full_date AS first_purchase_date,
        p.product_category AS first_category_name,
        ROW_NUMBER() OVER (
            PARTITION BY c.customer_id
            ORDER BY d.full_date ASC
        ) AS rn
    FROM dw.fact_sales f
    JOIN dw.dim_customer c
        ON f.customer_sk = c.customer_sk
    JOIN dw.dim_product p
        ON f.product_sk = p.product_sk
    JOIN dw.dim_date d
        ON f.date_sk = d.date_sk
)
SELECT
    customer_id,
    first_purchase_date,
    first_category_name
FROM ranked_purchases
WHERE rn = 1
ORDER BY customer_id;

 

-- Request 18
-- Question:

-- Request 18/25 [GRANULARITY]
-- Type: Granularity
-- Estimated solve time: 12 min
-- Main skill tested: Aggregating before joining fact-related logic
-- Business question:
-- The leadership team wants to compare customer reach and revenue by market for the last full calendar quarter.
-- Return, for each market:
-- - total revenue
-- - distinct active customers
-- - average revenue per active customer
-- Expected output:
-- - market
-- - total_revenue
-- - active_customers
-- - avg_revenue_per_active_customer
-- Granularity:
-- - One row per market
 

-- My SQL:

WITH maxs_date AS(
    SELECT MAX(full_date) AS max_date
    FROM dw.dim_date
    
),
quarter_time AS(
    SELECT
        date_trunc('quarter', max_date) AS finish_quarter,
        date_trunc('quarter', max_date) - INTERVAL '3 months' AS start_quarter
    FROM maxs_date
),
market_revenues AS(
    SELECT r.market , COUNT(DISTINCT c.customer_id) AS active_customers , SUM(f.net_amount) AS market_revenue
    FROM dw.fact_sales f
    JOIN dw.dim_customer c
    ON f.customer_sk = c.customer_sk
    JOIN dw.dim_product p
    ON f.product_sk = p.product_sk
    JOIN dw.dim_region r
    ON f.region_sk = r.region_sk
    JOIN dw.dim_date d
    ON f.date_sk = d.date_sk
    CROSS JOIN quarter_time y
    WHERE d.full_date >= y.start_quarter AND d.full_date < y.finish_quarter
    GROUP BY r.market 
),
revenue_customer AS(
    SELECT market, active_customers, market_revenue ,
    ROUND(market_revenue / NULLIF(active_customers,0),2) AS avg_revenue_per_active_customer
    FROM market_revenues
)
    SELECT market , active_customers , market_revenue, avg_revenue_per_active_customer 
    FROM revenue_customer
    ORDER BY avg_revenue_per_active_customer DESC

-- SQL Correction:

--Verdict: Correct
--Interview pass likelihood: Likely Pass



-- Request 19
-- Question:

-- Request 19/25 [GRANULARITY]
-- Type: Granularity
-- Estimated solve time: 12 min
-- Main skill tested: Preserving missing combinations
-- Business question:
-- The category management team wants full market coverage.
-- For the last full calendar month, return every combination of:
-- - market
-- - category
-- including combinations with zero revenue, and show the revenue for each combination.
-- Expected output:
-- - market
-- - category_name
-- - total_revenue
-- Granularity:
-- - One row per market-category combination for the last full calendar month, including zero-revenue combinations
 

-- My SQL:

WITH maxs_date AS (
    SELECT MAX(full_date) AS max_date
    FROM dw.dim_date
),
month_time AS (
    SELECT
        date_trunc('month', max_date) AS finish_month,
        date_trunc('month', max_date) - INTERVAL '1 month' AS start_month
    FROM maxs_date
),
markets AS (
    SELECT DISTINCT market
    FROM dw.dim_region
),
categories AS (
    SELECT DISTINCT product_category AS category_name
    FROM dw.dim_product
),
all_combinations AS (
    SELECT
        m.market,
        c.category_name
    FROM markets m
    CROSS JOIN categories c
),
monthly_revenue AS (
    SELECT
        r.market,
        p.product_category AS category_name,
        SUM(f.net_amount) AS total_revenue
    FROM dw.fact_sales f
    JOIN dw.dim_region r
        ON r.region_sk = f.region_sk
    JOIN dw.dim_product p
        ON p.product_sk = f.product_sk
    JOIN dw.dim_date d
        ON d.date_sk = f.date_sk
    CROSS JOIN month_time mt
    WHERE d.full_date >= mt.start_month
      AND d.full_date < mt.finish_month
    GROUP BY
        r.market,
        p.product_category
)
SELECT
    ac.market,
    ac.category_name,
    COALESCE(mr.total_revenue, 0) AS total_revenue
FROM all_combinations ac
LEFT JOIN monthly_revenue mr
    ON ac.market = mr.market
   AND ac.category_name = mr.category_name
ORDER BY
    ac.market,
    ac.category_name;

 
-- SQL Correction:

--Verdict: Correct
--Interview pass likelihood: Likely Pass


-- Request 20
-- Question:

-- Request 20/25 [GRANULARITY]
-- Type: Granularity
-- Estimated solve time: 12 min
-- Main skill tested: Correct output grain and anti-join logic
-- Business question:
-- The merchandising team wants to identify underperforming areas.
-- Return all market-category combinations that had no sales at all in the last full calendar quarter.
-- Expected output:
-- - market
-- - category_name
-- Granularity:
-- - One row per market-category combination with no sales in the last full calendar quarter

 
-- My SQL:



 WITH maxs_date AS (
    SELECT MAX(full_date) AS max_date
    FROM dw.dim_date
),
quarter_time AS (
    SELECT
        date_trunc('quarter', max_date) AS finish_quarter,
        date_trunc('quarter', max_date) - INTERVAL '3 months' AS start_quarter
    FROM maxs_date
),
markets AS (
    SELECT DISTINCT market
    FROM dw.dim_region
),
categories AS (
    SELECT DISTINCT product_category AS category_name
    FROM dw.dim_product
),
all_market_category AS (
    SELECT
        m.market,
        c.category_name
    FROM markets m
    CROSS JOIN categories c
),
sold_market_category_last_quarter AS (
    SELECT DISTINCT
        r.market,
        p.product_category AS category_name ,
        f.net_amount
    FROM dw.fact_sales f
    JOIN dw.dim_region r
        ON f.region_sk = r.region_sk
    JOIN dw.dim_product p
        ON f.product_sk = p.product_sk
    JOIN dw.dim_date d
        ON f.date_sk = d.date_sk
    CROSS JOIN quarter_time q
    WHERE d.full_date >= q.start_quarter
      AND d.full_date < q.finish_quarter
)
SELECT
    amc.market,
    amc.category_name
FROM all_market_category amc
LEFT JOIN sold_market_category_last_quarter s
    ON amc.market = s.market
   AND amc.category_name = s.category_name
WHERE s.market IS NULL
ORDER BY amc.market, amc.category_name;


-- SQL Correction:
 
--Verdict: Correct
--Interview pass likelihood: Likely Pass

-- Request 21
-- Question:

-- Request 21/25 [GRANULARITY]
-- Type: Granularity
-- Estimated solve time: 12 min
-- Main skill tested: Aggregate before joining to preserve correct grain
-- Business question:
-- The finance team wants a market summary with category breadth.
-- For the last full calendar year, return for each market:
-- - total revenue
-- - number of distinct categories sold
-- Expected output:
-- - market
-- - total_revenue
-- - distinct_categories_sold
-- Granularity:
-- - One row per market


-- My SQL:




WITH maxs_date AS(
    SELECT MAX(full_date) AS max_date
    FROM dw.dim_date
    
),
year_time AS(
    SELECT
        date_trunc('year', max_date) AS finish_year,
        date_trunc('year', max_date) - INTERVAL '1 year' AS start_year
    FROM maxs_date
),
market_revenues AS(
    SELECT r.market , SUM(f.net_amount) AS total_revenue ,  COUNT(DISTINCT p.product_category) AS distinct_categories_sold
    FROM dw.fact_sales f
    JOIN dw.dim_product p
    ON f.product_sk = p.product_sk
    JOIN dw.dim_region r
    ON f.region_sk = r.region_sk
    JOIN dw.dim_date d
    ON f.date_sk = d.date_sk
    CROSS JOIN year_time y
    WHERE d.full_date >= y.start_year AND d.full_date < y.finish_year
    GROUP BY r.market 
)
SELECT market , total_revenue , distinct_categories_sold
FROM market_revenues
ORDER BY total_revenue DESC 

-- SQL Correction:

-- Verdict: Correct
--Interview pass likelihood: Likely Pass
 

-- Request 22
-- Question:

-- Request 22/25 [GRANULARITY]
-- Type: Granularity
-- Estimated solve time: 12 min
-- Main skill tested: Avoiding unsafe joins and defining correct output grain
-- Business question:
-- The commercial team wants to know, for the last full calendar quarter, which markets had more distinct active customers than distinct products sold.
-- Expected output:
-- - market
-- - active_customers
-- - distinct_products_sold
-- Granularity:
-- - One row per market meeting the condition
 

-- My SQL:


WITH max_dates AS(
    SELECT MAX(full_date) AS max_date
    FROM dw.dim_date
),
quarter_time AS(
    SELECT 
    DATE_TRUNC('quarter',max_date) AS finish_quarter,
    DATE_TRUNC('quarter',max_date) - INTERVAL '3 months' AS start_quarter 
    FROM max_dates
),
markets AS(
    SELECT r.market , COUNT(DISTINCT f.customer_sk ) AS active_customers , COUNT(DISTINCT f.product_sk) AS distinct_products_sold
    FROM dw.fact_sales f  
    JOIN dw.dim_region r  
    ON f.region_sk = r.region_sk
    JOIN dw.dim_date d  
    ON f.date_sk = d.date_sk
    CROSS JOIN quarter_time q
    WHERE d.full_date >= q.start_quarter AND d.full_date < q.finish_quarter 
    GROUP BY r.market 
    HAVING COUNT(DISTINCT f.customer_sk ) > COUNT(DISTINCT f.product_sk)
    
) 
SELECT market , active_customers , distinct_products_sold
FROM markets
ORDER BY active_customers DESC

-- SQL Correction:

--Verdict: Correct
--Interview pass likelihood: Likely Pass
 

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
 

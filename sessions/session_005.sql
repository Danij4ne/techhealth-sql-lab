
-- Session 005

-- Request 1
-- Question:
 
 -- Request 1/25 [MID]
-- Type: Realistic
-- Estimated solve time: 8 min
-- Main skill tested: Aggregation + CTE + ranking
--
-- Business question:
-- The sales leadership team wants to identify the best-performing products during the last full calendar month.
--
-- Return the top 5 products by total revenue generated during the last full month.
--
-- Expected output:
-- - product_id
-- - product_name
-- - category_name
-- - total_revenue
-- - product_rank
--
-- The ranking should be based on revenue, from highest to lowest.
--
-- Granularity:
-- One row per product.

-- My SQL:



WITH max_dates AS (
    SELECT MAX(full_date) AS max_date
    FROM dw.dim_date 
) ,
month_date AS(
    SELECT 
    DATE_TRUNC('month',max_date) AS finish_month,
    DATE_TRUNC('month',max_date) - INTERVAL '1 month' AS start_month
    FROM max_dates

),
product_stats AS(
    SELECT p.product_id , p.product_name , p.product_category AS category_name , SUM(f.net_amount) AS total_revenue
    FROM dw.fact_sales f
    JOIN dw.dim_product p
    ON f.product_sk = p.product_sk
    JOIN dw.dim_date d
    ON f.date_sk = d.date_sk
    CROSS JOIN month_date m
    WHERE d.full_date >= m.start_month AND d.full_date <m.finish_month
    GROUP BY p.product_id , p.product_name , p.product_category
)
SELECT product_id , product_name , category_name , total_revenue ,
ROW_NUMBER() OVER(ORDER BY total_revenue DESC) AS product_rank
FROM product_stats
ORDER BY product_rank ASC


-- SQL Correction:
 
 -- Verdict: Partial
-- Interview pass likelihood: Borderline
--
-- What is good
--
-- Correct use of CTEs.
-- Correct last full month logic.
-- Correct joins to product and date dimensions.
-- Correct aggregation grain: one row per product.
--
-- What is missing or risky
--
-- You forgot to limit the result to top 5.
-- ROW_NUMBER() is acceptable, but if two products have the same revenue, RANK() or DENSE_RANK() may be more business-friendly.
--
-- Granularity correctness: Good.
-- Join correctness / duplication risk: Good. No risky fact-to-fact join.
--
-- Would this pass in a real interview?
-- Almost, but missing LIMIT 5 is important because it changes the expected output.

--Cleaner version:

WITH max_dates AS (
    SELECT MAX(full_date) AS max_date
    FROM dw.dim_date 
),
month_date AS (
    SELECT 
        DATE_TRUNC('month', max_date) AS finish_month,
        DATE_TRUNC('month', max_date) - INTERVAL '1 month' AS start_month
    FROM max_dates
),
product_stats AS (
    SELECT 
        p.product_id,
        p.product_name,
        p.product_category AS category_name,
        SUM(f.net_amount) AS total_revenue
    FROM dw.fact_sales f
    JOIN dw.dim_product p
        ON f.product_sk = p.product_sk
    JOIN dw.dim_date d
        ON f.date_sk = d.date_sk
    CROSS JOIN month_date m
    WHERE d.full_date >= m.start_month 
      AND d.full_date < m.finish_month
    GROUP BY 
        p.product_id,
        p.product_name,
        p.product_category
)
SELECT 
    product_id,
    product_name,
    category_name,
    total_revenue,
    ROW_NUMBER() OVER (ORDER BY total_revenue DESC) AS product_rank
FROM product_stats
ORDER BY product_rank
LIMIT 5;


-- Request 2
-- Question:
 

-- My SQL:


-- SQL Correction:
 


-- Request 3
-- Question:
 

-- My SQL:


-- SQL Correction:
 


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
 

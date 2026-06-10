
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

-- Request 2/25 [MID]
-- Type: Realistic
-- Estimated solve time: 10 min
-- Main skill tested: Monthly aggregation + period-over-period comparison
--
-- Business question:
-- The finance team wants to compare revenue performance between the last full month and the month before that.
--
-- Return total revenue for each of those two months, plus the absolute revenue difference compared with the previous month.
--
-- Expected output:
-- - month_start
-- - total_revenue
-- - previous_month_revenue
-- - revenue_difference
--
-- Only include the last two full months available in the data.
--
-- Granularity:
-- One row per month.


-- My SQL:




WITH max_dates AS (
    SELECT MAX(full_date) AS max_date
    FROM dw.dim_date 
) ,
month_date AS(
    SELECT 
    DATE_TRUNC('month',max_date) AS finish_month,
    DATE_TRUNC('month',max_date) - INTERVAL '1 month' AS start_month,
    DATE_TRUNC('month',max_date) - INTERVAL '2 month' AS previous_month
    FROM max_dates
),
month_revenue AS (
    SELECT DATE_TRUNC('month', d.full_date) AS month_start , SUM(f.net_amount) AS total_revenue 
    FROM dw.fact_sales f
    JOIN dw.dim_date d
    ON f.date_sk = d.date_sk
    CROSS JOIN month_date m
    WHERE  d.full_date >= m.previous_month AND d.full_date < m.finish_month
    GROUP BY DATE_TRUNC('month', d.full_date)
),
previous_month AS(
    SELECT r.month_start , r.total_revenue , 
    LAG(r.total_revenue) OVER(ORDER BY r.month_start) AS previous_month_revenue
    FROM month_revenue r
)
SELECT month_start , total_revenue , previous_month_revenue,
total_revenue - previous_month_revenue AS revenue_difference
FROM  previous_month


-- SQL Correction:
 
--Verdict: Correct
--Interview pass likelihood: Likely Pass

-- Request 3
-- Question:

-- Request 3/25 [MID]
-- Type: Realistic
-- Estimated solve time: 8 min
-- Main skill tested: Aggregation + customer segmentation with CASE WHEN
--
-- Business question:
-- The customer success team wants to classify customers based on their total revenue in the last full quarter.
--
-- Create a customer revenue segment for each customer who made at least one purchase during the last full quarter.
--
-- Use these segments:
--
-- - `High Value` if total revenue is 1000 or more
-- - `Medium Value` if total revenue is at least 300 but less than 1000
-- - `Low Value` if total revenue is less than 300
--
-- Expected output:
-- - customer_id
-- - total_revenue
-- - revenue_segment
--
-- Granularity:
-- One row per customer.


-- My SQL:



WITH max_dates AS (
    SELECT MAX(full_date) AS max_date
    FROM dw.dim_date 
) ,
quarter_date AS(
    SELECT 
    DATE_TRUNC('month',max_date) AS finish_quarter,
    DATE_TRUNC('month',max_date) - INTERVAL '3 month' AS start_quarter
    FROM max_dates
),
customer_stats AS (
    SELECT  c.customer_id , SUM(f.net_amount) AS total_revenue 
    FROM dw.fact_sales f
    JOIN dw.dim_customer c
    ON f.customer_sk = c.customer_sk 
    JOIN dw.dim_date d 
    ON f.date_sk = d.date_sk
    CROSS JOIN quarter_date m
    WHERE  d.full_date >= m.start_quarter AND d.full_date < m.finish_quarter
    GROUP BY c.customer_id
),
customer_segment AS(
    SELECT customer_id , total_revenue ,
    CASE 
    WHEN total_revenue >= 1000 THEN 'High Value'
    WHEN  total_revenue >= 300 AND total_revenue <= 1000 THEN 'Medium Value'
    WHEN total_revenue < 300 THEN 'Low Value'
    END AS revenue_segment
    FROM customer_stats
)
SELECT customer_id , total_revenue, revenue_segment
FROM customer_segment
ORDER BY customer_id


-- SQL Correction:

-- Verdict: Partial
-- Interview pass likelihood: Borderline

-- What is good

-- Correct aggregation by customer.
-- Correct use of CASE WHEN.
-- Correct join between fact sales, customer, and date.
-- Good that you noticed customer_name does not exist.

-- What is missing or risky

-- The question asked for the last full quarter, but your logic uses the last 3 full months, not the previous calendar quarter.

-- This condition has overlap:

WHEN total_revenue >= 1000 THEN 'High Value'
WHEN total_revenue >= 300 AND total_revenue <= 1000 THEN 'Medium Value'

-- 1000 technically fits both, although SQL will classify it as High Value because it checks the first match.

-- Better:

WHEN total_revenue >= 300 AND total_revenue < 1000 THEN 'Medium Value'

-- Granularity correctness: Good.
-- Join correctness / duplication risk: Good.

-- Would this pass in a real interview?

-- Probably partial.
-- The main issue is quarter logic.

-- Cleaner quarter logic:

WITH max_dates AS (
    SELECT MAX(full_date) AS max_date
    FROM dw.dim_date
),
quarter_date AS (
    SELECT
        DATE_TRUNC('quarter', max_date) AS finish_quarter,
        DATE_TRUNC('quarter', max_date) - INTERVAL '3 months' AS start_quarter
    FROM max_dates
),
customer_stats AS (
    SELECT  
        c.customer_id,
        SUM(f.net_amount) AS total_revenue 
    FROM dw.fact_sales f
    JOIN dw.dim_customer c
        ON f.customer_sk = c.customer_sk 
    JOIN dw.dim_date d 
        ON f.date_sk = d.date_sk
    CROSS JOIN quarter_date q
    WHERE d.full_date >= q.start_quarter 
      AND d.full_date < q.finish_quarter
    GROUP BY c.customer_id
)
SELECT 
    customer_id,
    total_revenue,
    CASE 
        WHEN total_revenue >= 1000 THEN 'High Value'
        WHEN total_revenue >= 300 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS revenue_segment
FROM customer_stats
ORDER BY customer_id;

-- Request 4
-- Question:

-- Request 4/25 [MID]
-- Type: Realistic
-- Estimated solve time: 10 min
--
-- Business question:
-- The marketing team wants to find customers who joined but have not purchased anything yet.
--
-- Return all customers with no sales activity at all.
--
-- Expected output:
-- - customer_id
-- - total_orders
-- - total_revenue
-- - customer_status
--
-- total_orders should be 0.
-- total_revenue should be 0.
-- customer_status should be 'No Purchases'.
--
-- Granularity:
-- One row per customer.
 
-- My SQL:


WITH customers_stats AS(
    SELECT c.customer_id , COUNT(f.sale_id) AS total_orders , SUM(f.net_amount) AS total_revenue
    FROM dw.fact_sales f 
    RIGHT JOIN dw.dim_customer c
    ON f.customer_sk = c.customer_sk 
    GROUP BY c.customer_id 
),
customer_purchase AS(
SELECT customer_id , total_orders , total_revenue, 
CASE WHEN total_orders = 0 AND total_revenue = NULL THEN 'No Purchases' END AS customer_status
FROM customers_stats
)
SELECT customer_id , total_orders , total_revenue , customer_status
FROM customer_purchase
WHERE customer_status = 'No Purchases'


-- SQL Correction:

-- Verdict: Wrong
-- Interview pass likelihood: Likely Fail

-- What is good

-- You understood that customers without sales must still appear.
-- The grain is intended correctly: one row per customer.

-- What is missing or risky

-- total_revenue = NULL is never true. You need IS NULL.
-- The expected output says total_revenue should be 0, not NULL.
-- RIGHT JOIN works logically, but in interviews it is usually cleaner to start from customers and keep all customers.
-- Your final result will likely return no rows because of the NULL comparison.

-- Granularity correctness: Good intention.
-- Join correctness / duplication risk: Mostly okay, but less clean than needed.

-- Would this pass in a real interview?

-- No, because the NULL logic breaks the result.

-- Cleaner version:

WITH customers_stats AS (
    SELECT 
        c.customer_id,
        COUNT(f.sale_id) AS total_orders,
        COALESCE(SUM(f.net_amount), 0) AS total_revenue
    FROM dw.dim_customer c
    LEFT JOIN dw.fact_sales f 
        ON c.customer_sk = f.customer_sk 
    GROUP BY c.customer_id
)
SELECT 
    customer_id,
    total_orders,
    total_revenue,
    'No Purchases' AS customer_status
FROM customers_stats
WHERE total_orders = 0;
 


-- Request 5
-- Question:

-- Request 5/25 [MID]
-- Type: Realistic
-- Estimated solve time: 10 min
--
-- Business question:
-- The product team wants to understand which product categories are contributing the most to revenue in the current year available in the data.
--
-- Return each product category’s revenue and its percentage contribution to total revenue for that year.
--
-- Expected output:
-- - category_name
-- - category_revenue
-- - revenue_share_pct
--
-- Sort from highest revenue share to lowest.
--
-- Granularity:
-- One row per product category.
 

-- My SQL:

WITH max_dates AS(
    SELECT MAX(full_date) AS max_date
    FROM dw.dim_date
),
year_date AS(
    SELECT
        DATE_TRUNC('year', max_date) AS start_year,
        DATE_TRUNC('year', max_date) + INTERVAL '1 year' AS finish_year
    FROM max_dates
),
products_stats AS(
    SELECT p.product_category AS category_name , SUM(f.net_amount) AS category_revenue
    FROM dw.fact_sales f
    JOIN dw.dim_product p
    ON f.product_sk = p.product_sk
    JOIN dw.dim_date d
    ON f.date_sk = d.date_sk
    CROSS JOIN year_date y
    WHERE d.full_date >= y.start_year AND d.full_date < y.finish_year
    GROUP BY p.product_category
),
global_revenue AS(
SELECT category_name , category_revenue ,
SUM(category_revenue) OVER() AS total
FROM products_stats
)
SELECT  category_name , category_revenue , 
ROUND(category_revenue / NULLIF(total,0) * 100.0,2) AS revenue_share_pct
FROM global_revenue
ORDER BY revenue_share_pct DESC
 

-- SQL Correction:

--Verdict: Correct

--Interview pass likelihood: Likely Pass


-- Request 6
-- Question:

-- Request 6/25 [MID]
-- Type: Realistic
-- Estimated solve time: 10 min
--
-- Business question:
-- The regional managers want to know the top-selling product in each region during the last full year available in the data.
--
-- Return only the best-selling product for every region based on total revenue.
--
-- Expected output:
-- - region_name
-- - product_id
-- - product_name
-- - total_revenue
--
-- Granularity:
-- One row per region.
 

-- My SQL:


WITH max_dates AS(
    SELECT MAX(full_date) AS max_date
    FROM dw.dim_date
),
year_date AS(
    SELECT
        DATE_TRUNC('year', max_date) AS finish_year,
        DATE_TRUNC('year', max_date) - INTERVAL '1 year' AS start_year
    FROM max_dates
),
region_stats AS(
    SELECT r.region_name , p.product_id, p.product_name , SUM(f.net_amount) AS total_revenue
    FROM dw.fact_sales f
    JOIN dw.dim_product p
    ON f.product_sk = p.product_sk
    JOIN dw.dim_region r
    ON f.region_sk = r.region_sk
    JOIN dw.dim_date d
    ON f.date_sk = d.date_sk
    CROSS JOIN year_date y
    WHERE d.full_date >= y.start_year AND d.full_date < y.finish_year
    GROUP BY r.region_name , p.product_id, p.product_name 
),
ranking AS(
SELECT region_name , product_id , product_name, total_revenue, 
DENSE_RANK() OVER(PARTITION BY region_name ORDER BY total_revenue DESC ) AS rank
FROM region_stats
)
SELECT  region_name , product_id , product_name , total_revenue
FROM ranking
WHERE rank = 1
ORDER BY region_name 
 

-- SQL Correction:

-- VERDICT

-- Interview pass likelihood: Borderline

-- What is good

-- Correct aggregation by region and product.
-- Correct use of ranking per region.
-- Correct joins to product, region, and date.
-- Correct final grain in normal cases.

-- What is missing or risky

-- The question says one row per region.
-- With DENSE_RANK(), if two products tie for first place in a region,
-- you return multiple rows for that region.

-- For strict "one row per region", ROW_NUMBER() is safer.

-- Your year logic is correct for last full year,
-- not current year.

-- Granularity correctness:
-- Almost correct, but ties can break the required grain.

-- Join correctness / duplication risk:
-- Correct.

-- Would this pass in a real interview?

-- Probably partial because of the tie issue.

-- Cleaner version:

WITH max_dates AS (
    SELECT MAX(full_date) AS max_date
    FROM dw.dim_date
),
year_date AS (
    SELECT
        DATE_TRUNC('year', max_date) AS finish_year,
        DATE_TRUNC('year', max_date) - INTERVAL '1 year' AS start_year
    FROM max_dates
),
region_stats AS (
    SELECT 
        r.region_name,
        p.product_id,
        p.product_name,
        SUM(f.net_amount) AS total_revenue
    FROM dw.fact_sales f
    JOIN dw.dim_product p
        ON f.product_sk = p.product_sk
    JOIN dw.dim_region r
        ON f.region_sk = r.region_sk
    JOIN dw.dim_date d
        ON f.date_sk = d.date_sk
    CROSS JOIN year_date y
    WHERE d.full_date >= y.start_year 
      AND d.full_date < y.finish_year
    GROUP BY 
        r.region_name,
        p.product_id,
        p.product_name
),
ranking AS (
    SELECT 
        region_name,
        product_id,
        product_name,
        total_revenue,
        ROW_NUMBER() OVER (
            PARTITION BY region_name 
            ORDER BY total_revenue DESC, product_id
        ) AS rn
    FROM region_stats
)
SELECT  
    region_name,
    product_id,
    product_name,
    total_revenue
FROM ranking
WHERE rn = 1
ORDER BY region_name;


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
 

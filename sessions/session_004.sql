
-- Session 004

-- Request 1
-- Question:

-- Request 1/25 [MID]
-- Type: Realistic
-- Estimated solve time: 8–10 min
-- Main skill tested: Window functions + % of total
--
-- Business question:
-- For each market, calculate the percentage contribution of each product to the total revenue of that market during the last full year.
--
-- Expected output:
-- - market
-- - product_name
-- - product_revenue
-- - market_total_revenue
-- - pct_of_market_revenue
--
-- Granularity:
-- One row per market + product
 

-- My SQL:

WITH maxs_date AS (
    SELECT MAX(full_date) AS max_date
    FROM dw.dim_date
),
year_time AS (
    SELECT
        date_trunc('year', max_date) AS finish_year,
        date_trunc('year', max_date) - INTERVAL '1 year' AS start_year
    FROM maxs_date
),
info_market AS (
    SELECT 
        r.market,
        p.product_name,
        f.net_amount
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
),
market_revenue AS (
    SELECT 
        market,
        SUM(net_amount) AS revenue_by_market
    FROM info_market
    GROUP BY market
),
market_product_revenue AS (
    SELECT 
        market,
        product_name,
        SUM(net_amount) AS revenue_by_market_product
    FROM info_market
    GROUP BY market, product_name
)
SELECT 
    p.market,
    p.product_name,
    p.revenue_by_market_product AS product_revenue,
    m.revenue_by_market AS market_total_revenue,
    ROUND(
        (p.revenue_by_market_product * 100.0) 
        / NULLIF(m.revenue_by_market, 0),
        2
    ) AS pct_of_market_revenue
FROM market_product_revenue p
JOIN market_revenue m
    ON p.market = m.market
ORDER BY p.market, pct_of_market_revenue DESC;


-- SQL Correction:


--Verdict: Correct
--Interview pass likelihood: Likely Pass


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
 

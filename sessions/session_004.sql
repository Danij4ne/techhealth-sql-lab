
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

-- Request 2/25 [MID]
-- Type: Realistic
-- Estimated solve time: 10–12 min
-- Main skill tested: Month-over-month comparison + pct change
--
-- Business question:
-- For each market, compare total revenue in the last full month against the previous full month. Show the absolute revenue change and the percentage change.
--
-- Expected output:
-- - market
-- - last_full_month_revenue
-- - previous_full_month_revenue
-- - revenue_change
-- - pct_revenue_change
--
-- Granularity:
-- One row per market

 

-- My SQL:


WITH maxs_date AS (
    SELECT MAX(full_date) AS max_date
    FROM dw.dim_date
),
month_time AS (
    SELECT
        DATE_TRUNC('month', max_date) AS current_month_start,
        DATE_TRUNC('month', max_date) - INTERVAL '1 month' AS last_full_month_start,
        DATE_TRUNC('month', max_date) - INTERVAL '2 months' AS previous_full_month_start
    FROM maxs_date
),
market_month_revenue AS (
    SELECT
        r.market,
        DATE_TRUNC('month', d.full_date) AS month_start,
        SUM(f.net_amount) AS revenue
    FROM dw.fact_sales f
    JOIN dw.dim_region r
        ON f.region_sk = r.region_sk
    JOIN dw.dim_date d
        ON f.date_sk = d.date_sk
    CROSS JOIN month_time mt
    WHERE d.full_date >= mt.previous_full_month_start
      AND d.full_date < mt.current_month_start
    GROUP BY
        r.market,
        DATE_TRUNC('month', d.full_date)
)
SELECT
    market,
    SUM(CASE WHEN month_start = mt.last_full_month_start THEN revenue ELSE 0 END) AS last_full_month_revenue,
    SUM(CASE WHEN month_start = mt.previous_full_month_start THEN revenue ELSE 0 END) AS previous_full_month_revenue,
    SUM(CASE WHEN month_start = mt.last_full_month_start THEN revenue ELSE 0 END)
        - SUM(CASE WHEN month_start = mt.previous_full_month_start THEN revenue ELSE 0 END) AS revenue_change,
    ROUND(
        (
            SUM(CASE WHEN month_start = mt.last_full_month_start THEN revenue ELSE 0 END)
            - SUM(CASE WHEN month_start = mt.previous_full_month_start THEN revenue ELSE 0 END)
        ) * 100.0
        / NULLIF(SUM(CASE WHEN month_start = mt.previous_full_month_start THEN revenue ELSE 0 END), 0),
        2
    ) AS pct_revenue_change
FROM market_month_revenue
CROSS JOIN month_time mt
GROUP BY market
ORDER BY market;


-- SQL Correction:

--Verdict: Correct
--Interview pass likelihood: Likely Pass
 

-- Request 3
-- Question:

-- Request 3/25 [MID]
-- Type: Realistic
-- Estimated solve time: 10–12 min
-- Main skill tested: Ranking + window functions + pct of market revenue
--
-- Business question:
-- For the last full quarter, find the top 3 products by revenue within each market. Also show each product’s percentage contribution to that market’s total revenue for the quarter.
--
-- Expected output:
-- - market
-- - product_name
-- - product_revenue
-- - market_total_revenue
-- - pct_of_market_revenue
-- - product_rank
--
-- Granularity:
-- One row per market + product, only top 3 products per market.


-- My SQL:

WITH max_dates AS(
    SELECT MAX(full_date) AS max_date
    FROM dw.dim_date
),
quarter_dates AS(
    SELECT 
    DATE_TRUNC('month', max_date) AS finish_quarter,
    DATE_TRUNC('month', max_date) - INTERVAL '3 months' AS start_quarter
    FROM max_dates
) ,
market_product_revenue AS (
    SELECT  r.market , p.product_name , SUM(f.net_amount) AS product_revenue
    FROM dw.fact_sales f
    JOIN dw.dim_region r
    ON f.region_sk = r.region_sk
    JOIN dw.dim_product p
    ON f.product_sk = p.product_sk
    JOIN dw.dim_date d
    ON f.date_sk = d.date_sk
    CROSS JOIN quarter_dates q
    WHERE d.full_date >= q.start_quarter AND d.full_date < q.finish_quarter
    GROUP BY r.market , p.product_name
) ,
market_total AS(
    SELECT market , SUM(product_revenue) AS market_total_revenue
    FROM market_product_revenue
    GROUP BY market
) ,
pct_market AS(
    SELECT r.market , r.product_name , r.product_revenue , t.market_total_revenue,
    ROUND(r.product_revenue * 100 / NULLIF(t.market_total_revenue ,0),2) AS pct_of_market_revenue
    FROM market_product_revenue r
    JOIN market_total t
    ON r.market = t.market
) ,
Ranking AS (
SELECT market , product_name , product_revenue , market_total_revenue , pct_of_market_revenue ,
ROW_NUMBER() OVER(PARTITION BY market ORDER BY pct_of_market_revenue DESC) AS product_rank
FROM pct_market
)
SELECT market , product_name , product_revenue , market_total_revenue , pct_of_market_revenue , product_rank
FROM Ranking
WHERE product_rank = 1 OR  product_rank = 2  OR product_rank = 3 

-- SQL Correction:

-- Verdict: Partial
-- Interview pass likelihood: Borderline / Likely Pass if you explain the quarter issue

-- What is good:
-- Correct joins.
-- Correct output grain: market + product.
-- Correct ranking idea.
-- No duplication risk.
-- Correct top 3 filter.

-- What is missing or risky:

-- Main issue:
-- your “quarter” logic is actually last 3 full months, not last full quarter.
-- DATE_TRUNC('month', max_date) should be DATE_TRUNC('quarter', max_date).

-- Division:
-- Use 100.0, not 100, to avoid integer division risk.

-- Improvement:
-- You could use SUM(product_revenue) OVER (PARTITION BY market)
-- instead of joining market_total.

-- Practical tip:
-- last full quarter = DATE_TRUNC('quarter', max_date) - interval '3 months'
--  to DATE_TRUNC('quarter', max_date)

WITH max_dates AS (
    SELECT MAX(full_date) AS max_date
    FROM dw.dim_date
),
quarter_dates AS (
    SELECT
        DATE_TRUNC('quarter', max_date) AS finish_quarter,
        DATE_TRUNC('quarter', max_date) - INTERVAL '3 months' AS start_quarter
    FROM max_dates
),
market_product_revenue AS (
    SELECT
        r.market,
        p.product_name,
        SUM(f.net_amount) AS product_revenue
    FROM dw.fact_sales f
    JOIN dw.dim_region r
        ON f.region_sk = r.region_sk
    JOIN dw.dim_product p
        ON f.product_sk = p.product_sk
    JOIN dw.dim_date d
        ON f.date_sk = d.date_sk
    CROSS JOIN quarter_dates q
    WHERE d.full_date >= q.start_quarter
      AND d.full_date < q.finish_quarter
    GROUP BY r.market, p.product_name
),
ranked AS (
    SELECT
        market,
        product_name,
        product_revenue,
        SUM(product_revenue) OVER (PARTITION BY market) AS market_total_revenue,
        ROUND(
            product_revenue * 100.0
            / NULLIF(SUM(product_revenue) OVER (PARTITION BY market), 0),
            2
        ) AS pct_of_market_revenue,
        ROW_NUMBER() OVER (
            PARTITION BY market
            ORDER BY product_revenue DESC
        ) AS product_rank
    FROM market_product_revenue
)
SELECT
    market,
    product_name,
    product_revenue,
    market_total_revenue,
    pct_of_market_revenue,
    product_rank
FROM ranked
WHERE product_rank <= 3
ORDER BY market, product_rank;


-- Request 4
-- Question:

-- Request 4/25 [MID]
-- Type: Realistic
-- Estimated solve time: 10–12 min
-- Main skill tested: Window functions + month-over-month pct change
--
-- Business question:
-- For each market, show monthly revenue for the last 6 full months and compare each month against the previous month. Include the absolute revenue change and percentage revenue change.
--
-- Expected output:
-- - market
-- - month_start
-- - monthly_revenue
-- - previous_month_revenue
-- - revenue_change
-- - pct_revenue_change
--
-- Granularity:
-- One row per market + month
 
-- My SQL:


WITH max_dates AS (
    SELECT MAX(full_date) AS max_date
    FROM dw.dim_date
),
month_dates AS (
    SELECT 
        DATE_TRUNC('month', max_date) AS finish_month,
        DATE_TRUNC('month', max_date) - INTERVAL '6 months' AS start_month
    FROM max_dates
),
market_month AS (
    SELECT 
        r.market,
        DATE_TRUNC('month', d.full_date) AS month_start,
        SUM(f.net_amount) AS monthly_revenue
    FROM dw.fact_sales f
    JOIN dw.dim_region r
        ON f.region_sk = r.region_sk
    JOIN dw.dim_date d
        ON f.date_sk = d.date_sk
    CROSS JOIN month_dates md
    WHERE d.full_date >= md.start_month
      AND d.full_date < md.finish_month
    GROUP BY 
        r.market,
        DATE_TRUNC('month', d.full_date)
),
with_previous AS (
    SELECT
        market,
        month_start,
        monthly_revenue,
        LAG(monthly_revenue) OVER (
            PARTITION BY market
            ORDER BY month_start
        ) AS previous_month_revenue
    FROM market_month
)
SELECT
    market,
    month_start,
    monthly_revenue,
    previous_month_revenue,
    monthly_revenue - previous_month_revenue AS revenue_change,
    ROUND(
        (monthly_revenue - previous_month_revenue) * 100.0 
        / NULLIF(previous_month_revenue, 0),
        2
    ) AS pct_revenue_change
FROM with_previous
ORDER BY market, month_start;


-- SQL Correction:


--Verdict: Correct
--Interview pass likelihood: Likely Pass

 
-- Request 5
-- Question:
-- Request 5/25 [MID]
-- Type: Realistic
-- Estimated solve time: 10–12 min
-- Main skill tested: Ranking + percentage difference vs leader
--
-- Business question:
-- For the last full month, rank products by revenue within each market. Show each product’s revenue, the top product revenue in that market, and how far each product is below the market leader as a percentage.
--
-- Expected output:
-- - market
-- - product_name
-- - product_revenue
-- - market_leader_revenue
-- - pct_below_market_leader
-- - product_rank
--
-- Granularity:
-- One row per market + product
 

-- My SQL:



WITH max_dates AS (
    SELECT MAX(full_date) AS max_date
    FROM dw.dim_date
),
month_dates AS (
    SELECT 
        DATE_TRUNC('month', max_date) AS finish_month,
        DATE_TRUNC('month', max_date) - INTERVAL '1 month' AS start_month
    FROM max_dates
),
market_month AS (
    SELECT 
        r.market,
        p.product_name ,
        SUM(f.net_amount) AS product_revenue
    FROM dw.fact_sales f
    JOIN dw.dim_product p
        ON f.product_sk = p.product_sk
    JOIN dw.dim_region r
        ON f.region_sk = r.region_sk
    JOIN dw.dim_date d
        ON f.date_sk = d.date_sk
    CROSS JOIN month_dates md
    WHERE d.full_date >= md.start_month
      AND d.full_date < md.finish_month
    GROUP BY 
        r.market,
        p.product_name
),
product_rank AS (
    SELECT market , product_name, product_revenue,
    ROW_NUMBER() OVER(PARTITION BY market  ORDER BY product_revenue DESC) AS product_rank
    FROM market_month
),
leader_revenue AS (
    SELECT 
        market,
        product_revenue AS market_leader_revenue
    FROM product_rank
    WHERE product_rank = 1
)  
SELECT p.market , p.product_name, p.product_revenue, 
ROUND(
        (l.market_leader_revenue - p.product_revenue) * 100.0 
        / NULLIF(l.market_leader_revenue, 0),
        2
    ) AS pct_below_market_leader, l.market_leader_revenue , p.product_rank
FROM product_rank p
JOIN leader_revenue l
ON p.market= l.market



-- SQL Correction:

-- Verdict: Partial
-- Interview pass likelihood: Borderline / Likely Pass
--
-- What is good:
--
-- Correct last full month range.
-- Correct ranking logic.
-- Correct formula for % below leader.
-- Correct grain: market + product.
-- No duplication risk.
--
-- What is missing or risky:
--
-- Output order does not match the expected output: market_leader_revenue should come before pct_below_market_leader.
-- You could get the leader revenue more cleanly with MAX(...) OVER.
-- Add ORDER BY market, product_rank.
--
-- Cleaner version:

WITH max_dates AS (
    SELECT MAX(full_date) AS max_date
    FROM dw.dim_date
),
month_dates AS (
    SELECT 
        DATE_TRUNC('month', max_date) AS finish_month,
        DATE_TRUNC('month', max_date) - INTERVAL '1 month' AS start_month
    FROM max_dates
),
market_product AS (
    SELECT 
        r.market,
        p.product_name,
        SUM(f.net_amount) AS product_revenue
    FROM dw.fact_sales f
    JOIN dw.dim_product p
        ON f.product_sk = p.product_sk
    JOIN dw.dim_region r
        ON f.region_sk = r.region_sk
    JOIN dw.dim_date d
        ON f.date_sk = d.date_sk
    CROSS JOIN month_dates md
    WHERE d.full_date >= md.start_month
      AND d.full_date < md.finish_month
    GROUP BY r.market, p.product_name
),
ranked AS (
    SELECT
        market,
        product_name,
        product_revenue,
        MAX(product_revenue) OVER (
            PARTITION BY market
        ) AS market_leader_revenue,
        ROW_NUMBER() OVER (
            PARTITION BY market
            ORDER BY product_revenue DESC
        ) AS product_rank
    FROM market_product
)
SELECT
    market,
    product_name,
    product_revenue,
    market_leader_revenue,
    ROUND(
        (market_leader_revenue - product_revenue) * 100.0
        / NULLIF(market_leader_revenue, 0),
        2
    ) AS pct_below_market_leader,
    product_rank
FROM ranked
ORDER BY market, product_rank;



-- Request 6
-- Question:

-- Request 6/25 [MID]
-- Type: Realistic
-- Estimated solve time: 10–12 min
-- Main skill tested: Rolling metrics + window functions
--
-- Business question:
-- For each market, show monthly revenue for the last 6 full months and include a 3-month rolling average revenue.
--
-- Expected output:
-- - market
-- - month_start
-- - monthly_revenue
-- - rolling_3_month_avg_revenue
--
-- Granularity:
-- One row per market + month
 

-- My SQL:


WITH max_dates AS (
    SELECT MAX(full_date) AS max_date
    FROM dw.dim_date
),
month_dates AS (
    SELECT 
        DATE_TRUNC('month', max_date) AS finish_month,
        DATE_TRUNC('month', max_date) - INTERVAL '6 months' AS start_month
    FROM max_dates
),
market_month AS(
    SELECT r.market , DATE_TRUNC('month', d.full_date) AS month_start , SUM(f.net_amount) AS monthly_revenue
    FROM dw.fact_sales f
    JOIN dw.dim_region r
    ON f.region_sk = r.region_sk 
    JOIN dw.dim_date d
    ON f.date_sk = d.date_sk
    CROSS JOIN month_dates m
    WHERE d.full_date >= m.start_month AND d.full_date < m.finish_month
    GROUP BY r.market , DATE_TRUNC('month', d.full_date)
) 
SELECT market , month_start , monthly_revenue ,
ROUND(AVG(monthly_revenue) OVER( PARTITION BY market ORDER BY month_start ROWS BETWEEN 2 PRECEDING AND CURRENT ROW ) ,2)AS rolling_3_month_avg_revenue
FROM market_month
ORDER BY market DESC


-- SQL Correction:

-- Verdict: Correct
-- Interview pass likelihood: Likely Pass

-- What is good:

-- Correct 6 full months filter.
-- Correct monthly aggregation first.
-- Correct rolling window frame.
-- Correct grain: market + month.
-- No join duplication risk.

-- What is missing or risky:

-- ORDER BY market DESC is not wrong, but better use ORDER BY market, month_start.
-- First two months use partial rolling averages. That is usually acceptable unless the business asks for only complete 3-month windows.


-- Request 7
-- Question:

-- Request 7/25 [MID]
-- Type: Realistic
-- Estimated solve time: 10–12 min
-- Main skill tested: Percent of total + ranking with window functions
--
-- Business question:
-- For the last full month, identify each market’s share of total company revenue and rank markets from highest to lowest revenue.
--
-- Expected output:
-- - market
-- - market_revenue
-- - company_total_revenue
-- - pct_of_company_revenue
-- - market_rank
--
-- Granularity:
-- One row per market 
 

-- My SQL:



WITH max_dates AS(
    SELECT MAX(full_date) AS max_date
    FROM dw.dim_date
) ,
month_time AS(
    SELECT 
    DATE_TRUNC('month',max_date) AS finish_month ,
    DATE_TRUNC('month',max_date) - INTERVAL '1 month' AS start_month
    FROM max_dates
) ,
market_revenue AS (
    SELECT r.market , SUM(f.net_amount) AS market_revenue , SUM(SUM(f.net_amount)) OVER() AS company_total_revenue
    FROM dw.fact_sales f
    JOIN dw.dim_region r
    ON f.region_sk = r.region_sk
    JOIN dw.dim_date d
    ON f.date_sk = d.date_sk 
    CROSS JOIN month_time m
    WHERE d.full_date >= m.start_month AND d.full_date < m.finish_month
    GROUP BY r.market
) 
SELECT market, market_revenue , company_total_revenue,
ROUND(market_revenue / NULLIF(company_total_revenue,0) * 100 ,2) AS pct_of_company_revenue ,
ROW_NUMBER() OVER(PARTITION BY market ORDER BY market_revenue DESC) AS market_rank
FROM market_revenue
ORDER BY pct_of_company_revenue DESC
 

-- SQL Correction:

-- Verdict: Partial
-- Interview pass likelihood: Borderline
--
-- What is good:
--
-- Correct last full month filter.
-- Correct market-level aggregation.
-- Correct company total logic with SUM(SUM(...)) OVER ().
-- Correct pct denominator.
--
-- What is missing or risky:
--
-- ROW_NUMBER() OVER(PARTITION BY market...) is wrong here. Since each market has one row, every rank becomes 1.
-- Ranking should be across all markets, so no PARTITION BY.
-- Use 100.0, not 100.
--
-- Corrected version:

WITH max_dates AS (
    SELECT MAX(full_date) AS max_date
    FROM dw.dim_date
),
month_time AS (
    SELECT 
        DATE_TRUNC('month', max_date) AS finish_month,
        DATE_TRUNC('month', max_date) - INTERVAL '1 month' AS start_month
    FROM max_dates
),
market_revenue AS (
    SELECT
        r.market,
        SUM(f.net_amount) AS market_revenue
    FROM dw.fact_sales f
    JOIN dw.dim_region r
        ON f.region_sk = r.region_sk
    JOIN dw.dim_date d
        ON f.date_sk = d.date_sk 
    CROSS JOIN month_time m
    WHERE d.full_date >= m.start_month
      AND d.full_date < m.finish_month
    GROUP BY r.market
)
SELECT
    market,
    market_revenue,
    SUM(market_revenue) OVER () AS company_total_revenue,
    ROUND(
        market_revenue * 100.0 / NULLIF(SUM(market_revenue) OVER (), 0),
        2
    ) AS pct_of_company_revenue,
    ROW_NUMBER() OVER (ORDER BY market_revenue DESC) AS market_rank
FROM market_revenue
ORDER BY market_rank;


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
 

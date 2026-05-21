
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
-- Request 8/25 [MID-HIGH]
-- Type: Standard
-- Estimated solve time: 12–15 min
-- Main skill tested: QoQ comparison + percentage change + window functions
--
-- Business question:
-- For each market, compare revenue in the last full quarter against the previous full quarter. Show the absolute revenue change and percentage revenue change.
--
-- Expected output:
-- - market
-- - last_full_quarter_revenue
-- - previous_full_quarter_revenue
-- - revenue_change
-- - pct_revenue_change
--
-- Granularity:
-- One row per market
 

-- My SQL:
 
 WITH max_dates AS (
    SELECT MAX(full_date) AS max_date
    FROM dw.dim_date
),
quarter_time AS (
    SELECT
        DATE_TRUNC('quarter', max_date) AS finish_quarter,
        DATE_TRUNC('quarter', max_date) - INTERVAL '3 months' AS last_quarter,
        DATE_TRUNC('quarter', max_date) - INTERVAL '6 months' AS previous_quarter
    FROM max_dates 
),
markets_revenue AS (
    SELECT 
        r.market,
        DATE_TRUNC('quarter', d.full_date) AS date_revenue,
        SUM(f.net_amount) AS revenue
    FROM dw.fact_sales f
    JOIN dw.dim_region r
        ON f.region_sk = r.region_sk 
    JOIN dw.dim_date d
        ON f.date_sk = d.date_sk
    CROSS JOIN quarter_time q
    WHERE d.full_date >= q.previous_quarter 
      AND d.full_date < q.finish_quarter
    GROUP BY r.market, DATE_TRUNC('quarter', d.full_date)
),
last_previous_revenues AS (
    SELECT 
        m.market,

        SUM(CASE 
            WHEN m.date_revenue = q.previous_quarter 
            THEN m.revenue 
        END) AS previous_full_quarter_revenue,

        SUM(CASE 
            WHEN m.date_revenue = q.last_quarter 
            THEN m.revenue 
        END) AS last_full_quarter_revenue

    FROM markets_revenue m
    CROSS JOIN quarter_time q
    GROUP BY m.market
)
SELECT 
    market,
    previous_full_quarter_revenue,
    last_full_quarter_revenue,
    ROUND(last_full_quarter_revenue - previous_full_quarter_revenue, 2) AS revenue_change,
    ROUND(
        (last_full_quarter_revenue - previous_full_quarter_revenue) 
        / NULLIF(previous_full_quarter_revenue, 0) * 100,
        2
    ) AS pct_revenue_change
FROM last_previous_revenues;


-- SQL Correction:

-- Verdict: Partial
-- Interview pass likelihood: Borderline / Likely Pass

-- What is good:

-- Correct quarter date logic.
-- Correct filter for previous + last full quarter.
-- Correct pct change formula.
-- Correct grain: one row per market.
-- No duplication risk.

-- What is missing or risky:

-- Expected output order asked for last_full_quarter_revenue before previous_full_quarter_revenue.
-- Use 100.0, not 100.
-- The question focuses on window functions, but you solved it with conditional aggregation. Correct, but less ideal for this practice.

-- Cleaner window version:

WITH max_dates AS (
    SELECT MAX(full_date) AS max_date
    FROM dw.dim_date
),
quarter_time AS (
    SELECT
        DATE_TRUNC('quarter', max_date) AS finish_quarter,
        DATE_TRUNC('quarter', max_date) - INTERVAL '6 months' AS start_quarter
    FROM max_dates
),
quarterly_revenue AS (
    SELECT
        r.market,
        DATE_TRUNC('quarter', d.full_date) AS quarter_start,
        SUM(f.net_amount) AS quarter_revenue
    FROM dw.fact_sales f
    JOIN dw.dim_region r
        ON f.region_sk = r.region_sk
    JOIN dw.dim_date d
        ON f.date_sk = d.date_sk
    CROSS JOIN quarter_time q
    WHERE d.full_date >= q.start_quarter
      AND d.full_date < q.finish_quarter
    GROUP BY r.market, DATE_TRUNC('quarter', d.full_date)
),
with_previous AS (
    SELECT
        market,
        quarter_start,
        quarter_revenue,
        LAG(quarter_revenue) OVER (
            PARTITION BY market
            ORDER BY quarter_start
        ) AS previous_quarter_revenue
    FROM quarterly_revenue
)
SELECT
    market,
    quarter_revenue AS last_full_quarter_revenue,
    previous_quarter_revenue AS previous_full_quarter_revenue,
    quarter_revenue - previous_quarter_revenue AS revenue_change,
    ROUND(
        (quarter_revenue - previous_quarter_revenue) * 100.0
        / NULLIF(previous_quarter_revenue, 0),
        2
    ) AS pct_revenue_change
FROM with_previous
WHERE quarter_start = (
    SELECT finish_quarter - INTERVAL '3 months'
    FROM quarter_time
)
ORDER BY market;


-- Request 9
-- Question:

-- Request 9/25 [MID-HIGH]
-- Type: Standard
-- Estimated solve time: 12–15 min
-- Main skill tested: Window functions + share of total + ranking
--
-- Business question:
-- For the last full quarter, calculate each product category’s revenue share within each market and rank categories by revenue inside each market.
--
-- Expected output:
-- - market
-- - category
-- - category_revenue
-- - market_total_revenue
-- - pct_of_market_revenue
-- - category_rank
--
-- Granularity:
-- One row per market + category
 

-- My SQL:


WITH max_dates AS(
    SELECT MAX(full_date) AS max_date
    FROM dw.dim_date 
),
quarter_date AS(
    SELECT
    DATE_TRUNC('quarter', max_date) AS  finish_quarter,
    DATE_TRUNC('quarter', max_date) - INTERVAL '3 months' AS start_quarter
    FROM max_dates
),
market_and_category AS(
    SELECT r.market , p.product_category AS category , SUM(f.net_amount) AS category_revenue , SUM(SUM(f.net_amount)) OVER(PARTITION BY r.market) AS market_total_revenue
    FROM dw.fact_sales f
    JOIN dw.dim_product p
    ON f.product_sk = p.product_sk
    JOIN dw.dim_date d
    ON f.date_sk = d.date_sk
    JOIN dw.dim_region r
    ON f.region_sk = r.region_sk
    CROSS JOIN quarter_date q
    WHERE d.full_date >= q.start_quarter AND  d.full_date < q.finish_quarter
    GROUP BY r.market , p.product_category 
) 
SELECT market , category , category_revenue , market_total_revenue ,
ROUND((category_revenue / NULLIF(market_total_revenue ,0))* 100.0 ,2) AS pct_of_market_revenue ,
ROW_NUMBER() OVER(PARTITION BY market ORDER BY category_revenue DESC ) AS category_rank
FROM market_and_category
ORDER BY market


-- SQL Correction:

--Verdict: Correct
--Interview pass likelihood: Likely Pass
 

-- Request 10
-- Question:

-- Request 10/25 [MID-HIGH]
-- Type: Standard
-- Estimated solve time: 12–15 min
-- Main skill tested: Window functions + YoY percentage change
--
-- Business question:
-- For each market, compare revenue in the last full year against the previous full year. Show the absolute revenue change and percentage revenue change.
--
-- Expected output:
-- - market
-- - last_full_year_revenue
-- - previous_full_year_revenue
-- - revenue_change
-- - pct_revenue_change
--
-- Granularity:
-- One row per market
 
-- My SQL:



WITH max_dates AS(
    SELECT MAX(full_date) AS max_date
    FROM dw.dim_date 
),
year_date AS(
    SELECT
    DATE_TRUNC('year', max_date) AS  finish_year,
    DATE_TRUNC('year', max_date) - INTERVAL '1 years' AS last_year,
    DATE_TRUNC('year', max_date) - INTERVAL '2 years' AS start_previous_year
    FROM max_dates
),
market_and_year AS(
    SELECT r.market , DATE_TRUNC('year', d.full_date) AS year_date, SUM(f.net_amount) AS revenue 
    FROM dw.fact_sales f
    JOIN dw.dim_date d
    ON f.date_sk = d.date_sk
    JOIN dw.dim_region r
    ON f.region_sk = r.region_sk
    CROSS JOIN year_date y
    WHERE d.full_date >= y.start_previous_year AND  d.full_date < y.finish_year
    GROUP BY r.market , DATE_TRUNC('year', d.full_date) 
),
market_previous AS(
    SELECT market , year_date , revenue , 
    LAG(revenue) OVER (PARTITION BY market ORDER BY year_date) AS previous_full_year_revenue
    FROM market_and_year
) 
SELECT m.market , m.year_date , m.revenue AS last_full_year_revenue  , m.previous_full_year_revenue,
ROUND(m.revenue - m.previous_full_year_revenue ,2)AS revenue_change ,
    ROUND(
        (m.revenue - m.previous_full_year_revenue) * 100.0 
        / NULLIF(m.previous_full_year_revenue, 0),
        2
    ) AS pct_revenue_change
FROM market_previous m
CROSS JOIN year_date y
WHERE m.year_date = y.last_year
ORDER BY m.market


-- SQL Correction:

--Verdict: Correct
--Interview pass likelihood: Likely Pass
 


-- Request 11
-- Question:

-- Request 11/25 [MID-HIGH]
-- Type: Standard
-- Estimated solve time: 12–15 min
-- Main skill tested: Window functions + first/last month comparison + pct change
--
-- Business question:
-- For each market, compare revenue in the most recent full month against the earliest month in the last 6 full months. Show the absolute change and percentage change.
--
-- Expected output:
-- - market
-- - earliest_month_revenue
-- - latest_month_revenue
-- - revenue_change
-- - pct_revenue_change
--
-- Granularity:
-- One row per market
 

-- My SQL:

WITH max_dates AS (
    SELECT MAX(full_date) AS max_date
    FROM dw.dim_date
),
month_time AS (
    SELECT
        DATE_TRUNC('month', max_date) AS finish_month,
        DATE_TRUNC('month', max_date) - INTERVAL '6 months' AS start_month
    FROM max_dates
),
market_and_month AS (
    SELECT 
        r.market,
        DATE_TRUNC('month', d.full_date) AS month_date,
        SUM(f.net_amount) AS revenue
    FROM dw.fact_sales f
    JOIN dw.dim_date d
        ON f.date_sk = d.date_sk
    JOIN dw.dim_region r
        ON f.region_sk = r.region_sk
    CROSS JOIN month_time mt
    WHERE d.full_date >= mt.start_month
      AND d.full_date < mt.finish_month
    GROUP BY r.market, DATE_TRUNC('month', d.full_date)
),
market_window AS (
    SELECT
        market,
        FIRST_VALUE(revenue) OVER (
            PARTITION BY market
            ORDER BY month_date
        ) AS earliest_month_revenue,
        LAST_VALUE(revenue) OVER (
            PARTITION BY market
            ORDER BY month_date
            ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING
        ) AS latest_month_revenue,
        ROW_NUMBER() OVER (
            PARTITION BY market
            ORDER BY month_date DESC
        ) AS rn
    FROM market_and_month
)
SELECT
    market,
    earliest_month_revenue,
    latest_month_revenue,
    ROUND(latest_month_revenue - earliest_month_revenue, 2) AS revenue_change,
    ROUND(
        (latest_month_revenue - earliest_month_revenue) * 100.0
        / NULLIF(earliest_month_revenue, 0),
        2
    ) AS pct_revenue_change
FROM market_window
WHERE rn = 1
ORDER BY market;


-- SQL Correction:
 
--Verdict: Correct
--Interview pass likelihood: Likely Pass


-- Request 12
-- Question:

-- Request 12/25 [MID-HIGH]
-- Type: Standard
-- Estimated solve time: 12–15 min
--
-- Business question:
-- For the last full month, rank products by revenue within each market and show how much revenue each product is above or below the product ranked immediately before it.
--
-- Expected output:
-- - market
-- - product_name
-- - product_revenue
-- - previous_rank_product_revenue
-- - revenue_difference_vs_previous_rank
-- - pct_difference_vs_previous_rank
-- - product_rank
--
-- Granularity:
-- One row per market + product


-- My SQL:


WITH max_dates AS(
    SELECT max(full_date) AS max_date
    FROM dw.dim_date
),
month_time AS(
    SELECT 
    DATE_TRUNC('month', max_date) AS finish_month,
    DATE_TRUNC('month', max_date) - INTERVAL '1 month' AS start_month
    FROM max_dates
),
market_revenue AS(
    SELECT r.market , p.product_name , SUM(f.net_amount) AS product_revenue
    FROM dw.fact_sales f
    JOIN dw.dim_region r
    ON f.region_sk = r.region_sk
    JOIN dw.dim_product p
    ON f.product_sk = p.product_sk
    JOIN dw.dim_date d
    ON f.date_sk = d.date_sk
    CROSS JOIN month_time m
    WHERE d.full_date >= m.start_month AND d.full_date < m.finish_month
    GROUP BY r.market , p.product_name 
) ,
previous_rank AS(
    SELECT market, product_name, product_revenue , 
    LAG(product_revenue) OVER(PARTITION BY market ORDER BY product_revenue DESC) AS previous_rank_product_revenue
    FROM market_revenue
) 
    SELECT market , product_name , product_revenue , previous_rank_product_revenue,
    ROUND(product_revenue - previous_rank_product_revenue ,2) AS revenue_difference_vs_previous_rank ,
    ROUND(product_revenue * 100.0 / NULLIF(previous_rank_product_revenue,0),2) AS pct_difference_vs_previous_rank,
    ROW_NUMBER() OVER(PARTITION BY market ORDER BY product_revenue DESC) AS product_rank
    FROM previous_rank
    ORDER BY market , product_revenue DESC




-- SQL Correction:
 -- Verdict: Partial
-- Interview pass likelihood: Borderline

-- What is good:

-- Correct last full month filter.
-- Correct grain: market + product.
-- Correct previous-ranked product logic.
-- No duplication risk.

-- What is missing or risky:

-- The percentage formula is wrong for “difference vs previous rank”.
-- You calculated product_revenue / previous_rank_product_revenue.
-- It should calculate the difference divided by the previous rank revenue.

-- Correct pct formula:

ROUND(
    (product_revenue - previous_rank_product_revenue) * 100.0
    / NULLIF(previous_rank_product_revenue, 0),
    2
) AS pct_difference_vs_previous_rank


-- Request 13
-- Question:

-- Request 13/25 [MID-HIGH]
-- Type: Standard
-- Estimated solve time: 12–15 min
--
-- Business question:
-- For each market, show monthly revenue for the last 6 full months and the cumulative revenue from the first month in that period through each month.
--
-- Expected output:
-- - market
-- - month_start
-- - monthly_revenue
-- - cumulative_revenue
--
-- Granularity:
-- One row per market + month
 

-- My SQL:


WITH max_dates AS (
    SELECT MAX(full_date) AS max_date 
    FROM dw.dim_date 
) ,
month_time AS(
    SELECT
    DATE_TRUNC('month', max_date) AS last_month ,
    DATE_TRUNC('month', max_date) - INTERVAL '6 months' AS start_month 
    FROM max_dates
) ,
market_revenue AS(
    SELECT  r.market , DATE_TRUNC('month', d.full_date) AS month_start , SUM(f.net_amount) AS monthly_revenue
    FROM dw.fact_sales f
    JOIN dw.dim_region r
    ON f.region_sk = r.region_sk
    JOIN dw.dim_date d
    ON f.date_sk = d.date_sk
    CROSS JOIN month_time m
    WHERE d.full_date >= m.start_month OR d.full_date < m.last_month 
    GROUP BY r.market , DATE_TRUNC('month', d.full_date) 
) 
    SELECT market , month_start , monthly_revenue ,
    SUM(monthly_revenue) OVER( ORDER BY month_start) cumulative_revenue
    FROM market_revenue
    ORDER BY market , cumulative_revenue ASC



-- SQL Correction:

-- Verdict: Wrong
-- Interview pass likelihood: Likely Fail
--
-- What is good:
--
-- You aggregated first at market + month, which is correct.
-- You used a window sum idea, which is the right direction.
--
-- What is missing or risky:
--
-- Your date filter uses OR; it should be AND.
-- Your cumulative sum is missing PARTITION BY market, so it mixes all markets together.
-- Your cumulative order should be by month_start, not final cumulative_revenue.
-- Better to use an explicit frame.
--
-- Corrected version:

WITH max_dates AS (
    SELECT MAX(full_date) AS max_date 
    FROM dw.dim_date 
),
month_time AS (
    SELECT
        DATE_TRUNC('month', max_date) AS finish_month,
        DATE_TRUNC('month', max_date) - INTERVAL '6 months' AS start_month 
    FROM max_dates
),
market_revenue AS (
    SELECT
        r.market,
        DATE_TRUNC('month', d.full_date) AS month_start,
        SUM(f.net_amount) AS monthly_revenue
    FROM dw.fact_sales f
    JOIN dw.dim_region r
        ON f.region_sk = r.region_sk
    JOIN dw.dim_date d
        ON f.date_sk = d.date_sk
    CROSS JOIN month_time m
    WHERE d.full_date >= m.start_month
      AND d.full_date < m.finish_month
    GROUP BY r.market, DATE_TRUNC('month', d.full_date)
)
SELECT
    market,
    month_start,
    monthly_revenue,
    SUM(monthly_revenue) OVER (
        PARTITION BY market
        ORDER BY month_start
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
    ) AS cumulative_revenue
FROM market_revenue
ORDER BY market, month_start;
 


-- Request 14
-- Question:

-- Request 14/25 [MID]
-- Type: Realistic
-- Estimated solve time: 8–10 min
--
-- Business question:
-- Identify the 10 products that generate the highest total revenue. The commercial team wants to prioritize inventory planning.
--
-- Expected output:
-- - product_name
-- - total_revenue
-- - total_orders
-- - total_units_sold
--
-- Granularity:
-- One row per product


-- My SQL:


SELECT p.product_name , SUM(f.net_amount) AS total_revenue , 
COUNT(f.sale_id) AS total_orders , SUM(f.quantity) AS total_units_sold
FROM dw.fact_sales f
JOIN dw.dim_product p
ON f.product_sk = p.product_sk
GROUP BY p.product_name
ORDER BY SUM(f.net_amount) DESC
LIMIT 10


-- SQL Correction:
 


-- Request 15
-- Question:
 
 -- Verdict: Partial
-- Interview pass likelihood: Borderline

-- What is good:

-- Correct fact table.
-- Correct join.
-- Correct grain: one row per product.
-- Correct revenue and units aggregation.

-- What is missing or risky:

-- COUNT(f.sale_id) may overcount if a sale has multiple product rows.
-- Better use:
-- COUNT(DISTINCT f.sale_id)

-- My SQL:

SELECT p.product_name , SUM(f.net_amount) AS total_revenue , 
COUNT(f.sale_id) AS total_orders , SUM(f.quantity) AS total_units_sold
FROM dw.fact_sales f
JOIN dw.dim_product p
ON f.product_sk = p.product_sk
GROUP BY p.product_name
ORDER BY SUM(f.net_amount) DESC
LIMIT 10



-- SQL Correction:

SELECT
    p.product_name,
    SUM(f.net_amount) AS total_revenue,
    COUNT(DISTINCT f.sale_id) AS total_orders,
    SUM(f.quantity) AS total_units_sold
FROM dw.fact_sales f
JOIN dw.dim_product p
    ON f.product_sk = p.product_sk
GROUP BY p.product_name
ORDER BY total_revenue DESC
LIMIT 10;

-- Request 16
-- Question:
 
 -- Request 16/25 [MID-HIGH]
-- Type: Realistic
-- Estimated solve time: 12–15 min
--
-- Business question:
-- Calculate total revenue by month and the percentage variation compared to the previous month. Identify trends and unusual months.
--
-- Expected output:
-- - month_start
-- - monthly_revenue
-- - previous_month_revenue
-- - revenue_change
-- - pct_revenue_change
--
-- Granularity:
-- One row per month

-- My SQL:

WITH month_revenue AS(
    SELECT DATE_TRUNC('month', d.full_date) AS month_start, SUM(f.net_amount) AS monthly_revenue
    FROM dw.fact_sales f
    JOIN dw.dim_date d
    ON f.date_sk = d.date_sk
    GROUP BY DATE_TRUNC('month', d.full_date)
) ,
month_and_previous_month AS(
    SELECT month_start , monthly_revenue , 
    LAG(monthly_revenue) OVER(ORDER BY month_start) AS previous_month_revenue
    FROM month_revenue
) 
SELECT month_start , monthly_revenue , previous_month_revenue , 
ROUND(monthly_revenue - previous_month_revenue,2) AS revenue_change ,
ROUND((monthly_revenue - previous_month_revenue)/ NULLIF(previous_month_revenue,0) * 100.0,2) AS pct_revenue_change
FROM month_and_previous_month
ORDER BY month_start 



-- SQL Correction:

--Verdict: Correct
--Interview pass likelihood: Likely Pass
 

-- Request 17
-- Question:

-- Request 17/25 [MID]
-- Type: Realistic
-- Estimated solve time: 8–10 min
--
-- Business question:
-- Generate a ranking of customers based on their total accumulated spend. The business wants to identify the most valuable customers.
--
-- Expected output:
-- - customer_id
-- - gender
-- - country
-- - subscription_type
-- - total_revenue
-- - customer_rank
--
-- Granularity:
-- One row per customer

 
-- My SQL:

WITH customers_rv AS(
    SELECT c.customer_id , c.gender , c.country , c.subscription_type , SUM(f.net_amount) AS total_revenue
    FROM dw.fact_sales f
    JOIN dw.dim_customer c
    ON  f.customer_sk = c.customer_sk
    GROUP BY c.customer_id , c.gender , c.country , c.subscription_type 
) 
SELECT customer_id , gender , country , subscription_type , total_revenue ,
ROW_NUMBER()OVER(ORDER BY total_revenue DESC) AS customer_rank
FROM customers_rv
ORDER BY customer_rank ASC


-- SQL Correction:

--Verdict: Correct
--Interview pass likelihood: Likely Pass
 


-- Request 18
-- Question:

-- Request 18/25 [MID]
-- Type: Realistic
-- Estimated solve time: 10–12 min
--
-- Business question:
-- For each product category, calculate what percentage of total company revenue it represents.
--
-- Expected output:
-- - product_category
-- - category_revenue
-- - company_total_revenue
-- - pct_of_company_revenue
--
-- Granularity:
-- One row per product category
 

-- My SQL:


WITH categories AS(
    SELECT p.product_category , SUM(f.net_amount) AS category_revenue , SUM(SUM(f.net_amount)) OVER() AS company_total_revenue
    FROM dw.fact_sales f
    JOIN dw.dim_product p
    ON f.product_sk = p.product_sk
    GROUP BY p.product_category
    
) 
SELECT product_category , category_revenue , company_total_revenue ,
ROUND((category_revenue * 100) / NULLIF(company_total_revenue,0),2)
FROM categories
ORDER BY category_revenue DESC


-- SQL Correction:

--Verdict: Correct
--Interview pass likelihood: Likely Pass
 

-- Request 19
-- Question:

-- Request 19/25 [MID-HIGH]
-- Type: Realistic
-- Estimated solve time: 12–15 min
--
-- Business question:
-- Identify the top 3 customers by revenue within each subscription type.
-- The business wants to understand which customers are most valuable inside each subscription segment.
--
-- Expected output:
-- - subscription_type
-- - customer_id
-- - country
-- - total_revenue
-- - customer_rank
--
-- Granularity:
-- One row per subscription type + customer, only top 3 customers per subscription type.
 

-- My SQL:

With suscription_custom AS(
    SELECT c.subscription_type , c.customer_id , r.country , SUM(f.net_amount) AS total_revenue
    FROM dw.fact_sales f
    JOIN dw.dim_region r
    ON f.region_sk = r.region_sk
    JOIN dw.dim_customer c
    ON f.customer_sk = c.customer_sk
    GROUP BY c.subscription_type , c.customer_id , r.country 
    
),
ranking_type AS(
    SELECT subscription_type , customer_id , country , total_revenue , 
    ROW_NUMBER() OVER( PARTITION BY subscription_type  ORDER BY total_revenue DESC ) AS customer_rank
    FROM suscription_custom
    
)
SELECT subscription_type , customer_id , country, total_revenue , customer_rank
FROM ranking_type
WHERE  customer_rank <= 3
ORDER BY subscription_type 

 
-- SQL Correction:

-- Verdict: Partial
-- Interview pass likelihood: Borderline / Likely Pass

-- What is good:

-- Correct use of CTEs.
-- Correct ranking by subscription type.
-- Correct top 3 filter.
-- Correct final grain idea: subscription type + customer.

-- What is missing or risky:

-- You selected r.country from dim_region, but the expected output wants customer country. Use c.country.
-- Grouping by r.country could split the same customer if they bought in different regions.
-- Better final order: subscription_type, customer_rank.

-- Corrected version:

WITH subscription_customer AS (
    SELECT
        c.subscription_type,
        c.customer_id,
        c.country,
        SUM(f.net_amount) AS total_revenue
    FROM dw.fact_sales f
    JOIN dw.dim_customer c
        ON f.customer_sk = c.customer_sk
    GROUP BY
        c.subscription_type,
        c.customer_id,
        c.country
),
ranking_type AS (
    SELECT
        subscription_type,
        customer_id,
        country,
        total_revenue,
        ROW_NUMBER() OVER (
            PARTITION BY subscription_type
            ORDER BY total_revenue DESC
        ) AS customer_rank
    FROM subscription_customer
)
SELECT
    subscription_type,
    customer_id,
    country,
    total_revenue,
    customer_rank
FROM ranking_type
WHERE customer_rank <= 3
ORDER BY subscription_type, customer_rank;


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
 

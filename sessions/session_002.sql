
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
 

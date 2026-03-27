
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
 

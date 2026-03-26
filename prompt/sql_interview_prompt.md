# SQL Interview Practice Prompt

You are my SQL interviewer for Data Analyst / Analytics Engineer / Data
Engineer interviews.

I will use the TechHealth star schema below.

Your goal is to run a realistic SQL interview session with exactly 25
questions.

------------------------------------------------------------------------

## SESSION DISTRIBUTION

The 25 questions must be distributed as follows:

1)  10 questions → Highly realistic mid-level interview questions
    -   solvable in 5--12 minutes\
    -   very common patterns in real interviews
2)  8 questions → Standard mid-level questions
    -   5--15 minutes\
    -   slightly more reasoning or combinations
3)  5 questions → Granularity & join-critical questions
    -   focused on:
        -   correct fact table usage
        -   avoiding duplicate rows
        -   safe joins
        -   aggregating before joining
        -   preserving missing data
4)  2 questions → High-level questions
    -   more complex reasoning\
    -   possibly multi-step or cross-domain\
    -   still realistic (not absurdly long)

------------------------------------------------------------------------

## REALISM RULES

1.  Most questions must feel like real live interview questions.\
2.  Most must be solvable in 5--15 minutes.\
3.  Only 2--3 questions can be longer.\
4.  Do NOT create mostly long or overloaded report-style queries.\
5.  Prefer one main idea per question (or two combined max).\
6.  Some questions can feel like follow-ups, but keep them realistic.\
7.  Focus on SQL reasoning, not endurance.

------------------------------------------------------------------------

## SKILLS TO COVER

Across the session, include:

-   joins (correct usage)
-   aggregation
-   GROUP BY logic
-   COUNT DISTINCT
-   time filtering
-   last full month / quarter / year
-   MoM / QoQ comparisons
-   ranking and top N
-   window functions
-   first / last events
-   customers/products with no activity
-   exception reports
-   share of total
-   rolling metrics
-   cross-domain logic (carefully)
-   identifying unusual patterns
-   avoiding duplication
-   choosing correct granularity

------------------------------------------------------------------------

## GRANULARITY FOCUS (VERY IMPORTANT)

At least 5 questions must explicitly force me to think about:

-   which fact table to use\
-   when to aggregate before joining\
-   when NOT to join fact tables directly\
-   how to preserve missing combinations\
-   how to define correct output grain

------------------------------------------------------------------------

## QUESTION STYLE

For each question:

-   Write in business language\
-   Do NOT mention SQL functions\
-   Do NOT give hints\
-   Do NOT give solutions\
-   Include expected output\
-   Include required granularity when relevant\
-   Keep wording clear and realistic

------------------------------------------------------------------------

## FORMAT

For each question:

Request X/25 \[MID\] / \[MID-HIGH\] / \[HIGH\]

-   Type: (Realistic / Standard / Granularity / High-level)\
-   Estimated solve time: X min\
-   Main skill tested: ...\
-   Business question:\
    ...\
-   Expected output:
    -   ...\
    -   ...\
    -   ...\
-   Granularity:\
    ...

------------------------------------------------------------------------

## AFTER I ANSWER

Evaluate like a real interviewer:

1.  Verdict: Correct / Partial / Wrong\
2.  Interview pass likelihood: Likely Pass / Borderline / Likely Fail\
3.  What is good\
4.  What is missing or risky\
5.  Granularity correctness\
6.  Join correctness / duplication risk\
7.  Would this pass in a real interview?\
8.  Cleaner version only if needed\
9.  One short practical tip

Then immediately ask the next question.

------------------------------------------------------------------------

## END OF SESSION

After all 25:

1.  Identify the 10 most realistic questions\
2.  Identify the 5 best granularity questions\
3.  Identify the 2 hardest questions\
4.  List the 3 most common interview patterns tested\
5.  Give a short evaluation of my readiness for mid-level SQL interviews

------------------------------------------------------------------------

## IMPORTANT

I want realistic interview preparation, not oversized SQL marathons.

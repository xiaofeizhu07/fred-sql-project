-- ============================================================
-- My SQL queries on FRED data (SQLite)
-- Tables: unemployment(obs_date, unemployment_rate),
--         cpi(obs_date, cpi_index),
--         fed_funds_rate(obs_date, fed_funds_rate)
-- ============================================================


-- ============================================================
-- Query 1: Year-over-year CPI inflation (self-join)
-- Join cpi to itself so each month (c1) lines up with the same month
-- one year earlier (c2). Matching on the date, not on row position,
-- handles the missing October 2025 correctly (LAG(cpi_index, 12) does not).
-- ============================================================
SELECT
    c1.obs_date,
    ROUND(100 * (c1.cpi_index - c2.cpi_index) / c2.cpi_index, 2) AS inflation
FROM cpi c1
JOIN cpi c2
    ON c1.obs_date = date(c2.obs_date, '+1 year')
ORDER BY c1.obs_date DESC;


-- ============================================================
-- Query 2: Unemployment + YoY inflation + fed funds, 2019 onward
-- The Query 1 logic is reused as a CTE called yoy.
-- Unemployment is the main table; LEFT JOINs keep every month even
-- when CPI or fed funds has no row (fed funds is sampled, so most
-- months are NULL).
-- ============================================================
WITH yoy AS (
    SELECT
        c1.obs_date,
        ROUND(100 * (c1.cpi_index - c2.cpi_index) / c2.cpi_index, 2) AS inflation
    FROM cpi c1
    JOIN cpi c2
        ON c1.obs_date = date(c2.obs_date, '+1 year')
)
SELECT
    u.obs_date,
    u.unemployment_rate,
    yoy.inflation,
    f.fed_funds_rate
FROM unemployment u
LEFT JOIN yoy
    ON u.obs_date = yoy.obs_date
LEFT JOIN fed_funds_rate f
    ON u.obs_date = f.obs_date
WHERE u.obs_date >= '2019-01-01'
ORDER BY u.obs_date;


-- ============================================================
-- Query 3: Top 10 unemployment months
-- ROW_NUMBER ranks months by unemployment (highest first). The
-- tiebreaker (earlier date wins) goes INSIDE the OVER clause so that
-- exactly 10 rows come back. Apr 1983 and Jul 2020 tie at 10.2%.
-- ============================================================
WITH ranking AS (
    SELECT
        obs_date,
        unemployment_rate,
        ROW_NUMBER() OVER (ORDER BY unemployment_rate DESC, obs_date) AS rank_num
    FROM unemployment
)
SELECT
    r.obs_date,
    r.unemployment_rate,
    c.cpi_index,
    f.fed_funds_rate
FROM ranking r
LEFT JOIN cpi c
    ON c.obs_date = r.obs_date
LEFT JOIN fed_funds_rate f
    ON f.obs_date = r.obs_date
WHERE r.rank_num <= 10
ORDER BY r.rank_num;


-- ============================================================
-- Query 4: Average unemployment by decade
-- Dividing the year by 10 and multiplying by 10 rounds down to the
-- decade (SQLite does integer division). num_months shows which
-- decades are partial: 1940s (1948-49 only) and 2020s (so far).
-- ============================================================
SELECT
    (strftime('%Y', obs_date) / 10 * 10) AS decade,
    ROUND(AVG(unemployment_rate), 2) AS avg_unemployment,
    COUNT(*) AS num_months
FROM unemployment
GROUP BY decade
ORDER BY decade;


-- ============================================================
-- Query 5: Fed funds increases of 0.5+ points, and unemployment
-- at that time and 6 months later.
-- LAG gets the previous fed funds observation. fed_funds_rate is
-- sampled, so "previous" is usually about 6 months earlier, not
-- 1 month. Each row is a cumulative change over that gap.
-- ============================================================
WITH changes AS (
    SELECT
        obs_date,
        fed_funds_rate,
        LAG(obs_date, 1) OVER (ORDER BY obs_date) AS prev_date,
        LAG(fed_funds_rate, 1) OVER (ORDER BY obs_date) AS prev_rate
    FROM fed_funds_rate
)
SELECT
    prev_date,
    changes.obs_date,
    prev_rate,
    fed_funds_rate,
    ROUND(fed_funds_rate - prev_rate, 2) AS rate_change,
    u_now.unemployment_rate AS unemp_at_hike,
    u_after.unemployment_rate AS unemp_6mo_later,
    ROUND(u_after.unemployment_rate - u_now.unemployment_rate, 1) AS unemp_change
FROM changes
LEFT JOIN unemployment u_now
    ON u_now.obs_date = changes.obs_date
LEFT JOIN unemployment u_after
    ON u_after.obs_date = date(changes.obs_date, '+6 months')
WHERE fed_funds_rate - prev_rate >= 0.5
ORDER BY changes.obs_date;

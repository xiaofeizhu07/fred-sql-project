-- ============================================================
-- Query 1: Year-over-year CPI inflation rate
-- Joins CPI to itself, offset by 12 months, to compute YoY % change.
-- A self-join on the date is used instead of LAG(cpi_index, 12) because
-- LAG counts 12 ROWS back, not 12 MONTHS. October 2025 is missing from
-- the data, so LAG would be off by one month from Nov 2025 onward
-- (e.g. Jul 2026: self-join 3.30% vs LAG 3.54%).
-- ============================================================
SELECT
    curr.obs_date,
    curr.cpi_index AS cpi_current,
    prev.cpi_index AS cpi_year_ago,
    ROUND(((curr.cpi_index - prev.cpi_index) / prev.cpi_index) * 100, 2) AS yoy_inflation_pct
FROM cpi curr
JOIN cpi prev
    ON prev.obs_date = strftime('%Y-%m-01', date(curr.obs_date, '-12 months'))
ORDER BY curr.obs_date DESC
LIMIT 24;


-- ============================================================
-- Query 2: Unemployment, YoY inflation, and fed funds since 2019
-- Query 1 is reused as a CTE. Unemployment is the "spine" of the
-- result; both CPI-based inflation and fed funds are LEFT JOINed so
-- months without a match still appear (fed funds is sampled, and
-- CPI is missing for Oct 2025 and Aug 2026), with NULLs instead of
-- silently dropped rows.
-- ============================================================
WITH yoy AS (
    SELECT
        curr.obs_date,
        ROUND(((curr.cpi_index - prev.cpi_index) / prev.cpi_index) * 100, 2) AS yoy_inflation_pct
    FROM cpi curr
    JOIN cpi prev
        ON prev.obs_date = strftime('%Y-%m-01', date(curr.obs_date, '-12 months'))
)
SELECT
    u.obs_date,
    u.unemployment_rate,
    yoy.yoy_inflation_pct,
    f.fed_funds_rate
FROM unemployment u
LEFT JOIN yoy
    ON yoy.obs_date = u.obs_date
LEFT JOIN fed_funds_rate f
    ON f.obs_date = u.obs_date
WHERE u.obs_date >= '2019-01-01'
ORDER BY u.obs_date;


-- ============================================================
-- Query 3: Highest unemployment months on record, with CPI and the
-- fed funds rate alongside. Ties at the cutoff are kept (so this can
-- return 11 rows instead of silently cutting one off). Fed funds is
-- NULL for many rows because that table is sampled.
-- ============================================================
SELECT
    u.obs_date,
    u.unemployment_rate,
    c.cpi_index,
    f.fed_funds_rate
FROM unemployment u
LEFT JOIN cpi c ON c.obs_date = u.obs_date
LEFT JOIN fed_funds_rate f ON f.obs_date = u.obs_date
WHERE u.unemployment_rate >= (
    SELECT unemployment_rate
    FROM unemployment
    ORDER BY unemployment_rate DESC
    LIMIT 1 OFFSET 9
)
ORDER BY u.unemployment_rate DESC, u.obs_date;


-- ============================================================
-- Query 4: Average unemployment rate by decade
-- Aggregation using GROUP BY on a derived decade bucket.
-- num_months shows which decades are partial: the 1940s (1948-49
-- only) and the 2020s (through Aug 2026).
-- ============================================================
SELECT
    (CAST(strftime('%Y', obs_date) AS INTEGER) / 10) * 10 AS decade,
    ROUND(AVG(unemployment_rate), 2) AS avg_unemployment_rate,
    COUNT(*) AS num_months
FROM unemployment
GROUP BY decade
ORDER BY decade;


-- ============================================================
-- Query 5: Increases of 0.5+ points between consecutive fed funds
-- observations, and unemployment at that time and 6 months later.
--
-- NOTE: fed_funds_rate is sampled, so "consecutive observations" are
-- NOT consecutive months. Before 2019 they are mostly June and
-- December (about 6 months apart), so each row is the cumulative
-- change since the previous observation, not a single-meeting hike.
-- months_between makes the gap explicit. Rows are kept regardless of
-- gap size; filter on months_between if you want only tight windows.
-- ============================================================
WITH changes AS (
    SELECT
        obs_date,
        fed_funds_rate,
        LAG(obs_date) OVER (ORDER BY obs_date) AS prev_date,
        LAG(fed_funds_rate) OVER (ORDER BY obs_date) AS prev_rate
    FROM fed_funds_rate
)
SELECT
    ch.obs_date AS hike_date,
    ch.prev_date AS previous_obs_date,
    (CAST(strftime('%Y', ch.obs_date) AS INTEGER) - CAST(strftime('%Y', ch.prev_date) AS INTEGER)) * 12
      + CAST(strftime('%m', ch.obs_date) AS INTEGER) - CAST(strftime('%m', ch.prev_date) AS INTEGER)
        AS months_between,
    ch.prev_rate AS previous_rate,
    ch.fed_funds_rate,
    ROUND(ch.fed_funds_rate - ch.prev_rate, 2) AS rate_change,
    u_now.unemployment_rate AS unemployment_at_hike,
    u_after.unemployment_rate AS unemployment_6mo_later,
    ROUND(u_after.unemployment_rate - u_now.unemployment_rate, 1) AS unemployment_change
FROM changes ch
LEFT JOIN unemployment u_now
    ON u_now.obs_date = ch.obs_date
LEFT JOIN unemployment u_after
    ON u_after.obs_date = strftime('%Y-%m-01', date(ch.obs_date, '+6 months'))
WHERE ch.prev_rate IS NOT NULL
  AND ch.fed_funds_rate - ch.prev_rate >= 0.5
ORDER BY ch.obs_date;

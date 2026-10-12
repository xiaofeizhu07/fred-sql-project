-- Schema for economic_indicators.db
-- Source: FRED (Federal Reserve Economic Data), via govspending.org public export

CREATE TABLE unemployment (
    obs_date TEXT PRIMARY KEY,      -- YYYY-MM-01, monthly, 1948-01 to 2026-08 (Oct 2025 missing)
    unemployment_rate REAL          -- Percent, seasonally adjusted (UNRATE)
);

CREATE TABLE cpi (
    obs_date TEXT PRIMARY KEY,      -- YYYY-MM-01, monthly, 1947-01 to 2026-07 (Oct 2025 missing)
    cpi_index REAL                  -- Index, 1982-1984=100 (CPIAUCSL)
);

CREATE TABLE fed_funds_rate (
    obs_date TEXT PRIMARY KEY,      -- YYYY-MM-01, SAMPLED: not every month is present.
                                    -- Before 2019: June and December only (plus Jul 1954-Jan 1955).
                                    -- 2019 onward: a mix of monthly (early 2020) and roughly quarterly rows.
    fed_funds_rate REAL             -- Percent, effective rate (FEDFUNDS)
);

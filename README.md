# US Economic Indicators - SQL Analysis

A small SQL project analyzing the relationship between unemployment, inflation, and Federal Reserve interest rate policy, using real public data from FRED (Federal Reserve Economic Data).

## Data

Three time series, pulled from FRED via [govspending.org](https://govspending.org)'s public CSV export (original source: Federal Reserve Bank of St. Louis):

| Table | FRED series | Description | Rows | Coverage |
|---|---|---|---|---|
| `unemployment` | [UNRATE](https://fred.stlouisfed.org/series/UNRATE) | US unemployment rate, monthly, seasonally adjusted | 943 | Jan 1948 - Aug 2026 |
| `cpi` | [CPIAUCSL](https://fred.stlouisfed.org/series/CPIAUCSL) | Consumer Price Index, all urban consumers, monthly, seasonally adjusted | 954 | Jan 1947 - Jul 2026 |
| `fed_funds_rate` | [FEDFUNDS](https://fred.stlouisfed.org/series/FEDFUNDS) | Effective Federal Funds Rate, sampled (not every month) | 167 | Jul 1954 - Aug 2026 |

Schema: see `sql/schema.sql`. Queries: see `sql/queries_mine.sql`.

### Data limitations

- **Fed funds is sampled, not monthly.** Before 2019 the table holds almost only June and December observations, so any join to it needs a LEFT JOIN, and "previous observation" usually means about 6 months earlier.
- **October 2025 is missing** from both unemployment and CPI, which is why Query 1 uses a self-join on the date instead of LAG(cpi_index, 12).
- **The series end on different dates.** Unemployment and fed funds run through Aug 2026, but CPI ends at Jul 2026.
- **Partial decades.** The 1940s (1948-49 only) and the 2020s (so far) are incomplete in the decade averages.

## Setup

```bash
python3 build_db.py                                       # builds economic_indicators.db from the CSVs in data/
sqlite3 economic_indicators.db < sql/queries_mine.sql     # runs all five queries (needs the sqlite3 CLI)
```

If you don't have the `sqlite3` command-line tool, open `economic_indicators.db` in [DB Browser for SQLite](https://sqlitebrowser.org/) and paste in the queries.

## Findings

This project focuses on the Federal Reserve's dual mandate (stable prices and maximum employment), alongside the federal funds rate. Unemployment spikes come in clusters, not at random: 3 of the 10 highest months are from the 2020 pandemic (peaking at 14.8% in April 2020), and the other 7 fall between October 1982 and April 1983. Large rate increases showed no consistent link to unemployment 6 months later (higher in 15 cases, lower in 18, unchanged in 7), and even a link wouldn't show causation, since the Fed tends to hike when the economy is already strong. Inflation rose to 4.17% in May 2026 before easing to 3.3% by July.

## Why I built this

This was a self-directed project to build practical SQL skills - specifically writing multi-table joins, self-joins (for year-over-year comparisons), window functions for inflation comparisons, GROUP BY aggregations against real economic data, and CTEs for building queries in steps, complementing a Python/R-based statistical analysis project I built separately ([Player Spending Analysis](https://github.com/xiaofeizhu07/clash-royale-hero-analysis)).

## Tools

SQLite, Python (for data loading), SQL (joins, self-joins, window functions (ROW_NUMBER, LAG), aggregation, CTEs)

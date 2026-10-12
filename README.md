# US Economic Indicators — SQL Analysis

A small SQL project analyzing the relationship between unemployment, inflation, and Federal Reserve interest rate policy, using real public data from FRED (Federal Reserve Economic Data).

## Data

Three time series, pulled from FRED via [govspending.org](https://govspending.org)'s public CSV export (original source: Federal Reserve Bank of St. Louis):

| Table | FRED series | Description | Rows | Coverage |
|---|---|---|---|---|
| `unemployment` | [UNRATE](https://fred.stlouisfed.org/series/UNRATE) | US unemployment rate, monthly, seasonally adjusted | 943 | Jan 1948 – Aug 2026 |
| `cpi` | [CPIAUCSL](https://fred.stlouisfed.org/series/CPIAUCSL) | Consumer Price Index, all urban consumers, monthly, seasonally adjusted | 954 | Jan 1947 – Jul 2026 |
| `fed_funds_rate` | [FEDFUNDS](https://fred.stlouisfed.org/series/FEDFUNDS) | Effective Federal Funds Rate, **sampled** (see below) | 167 | Jul 1954 – Aug 2026 |

Schema: see `sql/schema.sql`. Queries: see `sql/queries.sql`.

### Data limitations

- **Fed funds is sampled, not monthly.** Most months have no row. Before 2019 the table holds almost only June and December observations (129 of 135 rows), plus Jul 1954 – Jan 1955. From 2019 on it is a mix of monthly rows (early 2020) and roughly quarterly ones. Any join to this table needs a `LEFT JOIN`, and "previous observation" usually means about 6 months earlier, not last month.
- **October 2025 is missing** from both unemployment and CPI. Window functions that count rows (`LAG(cpi_index, 12)`) are off by one month from Nov 2025 onward; joining on the date offset (as in Query 1) avoids this. For July 2026 the two methods give 3.30% and 3.54%.
- **The series end on different dates.** Unemployment and fed funds run through Aug 2026, but CPI ends at Jul 2026, so Aug 2026 has no inflation figure.
- **Partial decades.** The 1940s (1948–49 only, 24 months) and 2020s (79 months so far) are incomplete in the decade averages.
- **Sparse overlap with fed funds.** Many of the "top unemployment months" in Query 3 have no fed funds value because of the sampling.

## Setup

Put the three CSV files in `data/`, then build the database:

```bash
python3 build_db.py                                  # builds economic_indicators.db from data/*.csv
sqlite3 economic_indicators.db < sql/queries.sql     # runs all five queries (needs the sqlite3 CLI)
```

If you don't have the `sqlite3` command-line tool, open `economic_indicators.db` in [DB Browser for SQLite](https://sqlitebrowser.org/) and paste in the queries.

## Findings

**1. Inflation ran hot in spring 2026.** Year-over-year CPI inflation hit **4.17% in May 2026**, the highest reading of the past year, before easing to 3.3% by July. (Oct 2025 is missing from the data, so the trailing year has 11 YoY readings.)

**2. The 2020 unemployment spike dwarfs everything else in the series.** April 2020 recorded 14.8%, the highest in the 78-year dataset. The next two months were also far above any other period (13.2% in May, 11.0% in June). Outside the pandemic, the peak was 10.8% in late 1982.

**3. The 1980s had the worst average unemployment of any full decade** (7.27%), driven by the early-1980s recession. That is noticeably higher than the 1970s (6.22%), even though the 1970s are remembered for stagflation. The 2010s also averaged 6.22%, because of the long recovery from the 2008 crisis.

**4. Large fed funds increases show no consistent link to unemployment 6 months later.** Across the 40 observations where the fed funds rate rose by 0.5+ points since the previous observation, unemployment 6 months later was higher in 15 cases, lower in 18, and unchanged in 7, with an average change of about 0.0 points. That does not show that rate hikes have no effect: the Fed tends to raise rates when the economy is already strong, the comparison has no counterfactual, and the sampling means most of these "hikes" are cumulative changes over about 6 months rather than single moves.

## Why I built this

This was a self-directed project to build practical SQL skills — specifically writing multi-table joins, self-joins (for year-over-year comparisons), window functions, CTEs, and GROUP BY aggregations against real economic data, complementing a Python/R-based statistical analysis project I built separately ([Player Spending Analysis](https://github.com/xiaofeizhu07/clash-royale-hero-analysis)).

## Tools

SQLite, Python (for data loading), SQL (joins, self-joins, CTEs, window functions, aggregation)

# Notes

## Data quirks
- fed_funds_rate is sampled (mostly June and December before 2019), so joins to it need LEFT JOIN.
- October 2025 is missing from both CPI and unemployment.
- CPI ends Jul 2026; unemployment and fed funds run to Aug 2026.

## Query notes
Day 1 Query 1: CPI is missing October 2025, so LAG(cpi_index, 12) skips over it and compares each month from Nov 2025 to Jul 2026 against a base month that is 13 months back, not 12. That overstated inflation in those 9 months by 0.03 to 0.44 percentage points. The self-join matches on the actual date, so it’s the more reliable approach. 
Day 1 Query 2: A left join was needed because the fed funds table is sampled, so most months have no fed funds value. An inner join would have kept only the rows with a match in every table (about 32 of the 91 months). A left join keeps every unemployment month and fills in NULL where the other tables have no data.
Day 1 Query 3: Used a ranking window function to select the top 10 unemployment months, with LEFT JOINs to CPI and fed funds. The 10th and 11th highest months tie at 10.2% (Apr 1983 and Jul 2020), so I chose ROW_NUMBER with a tiebreaker(earlier date wins) because I prefer strictly 10 always. Fed funds is NULL for most of these months because the table is sampled.
Day 1 Query 4: Using / as a rounding down mechanism, I took the years of the dates and matched them with their corresponding decades. Months were included to track incomplete data. Data collection in FRED started in 1948 for unemployment, and at the time of writing there are still years to go before the 2020s are over. Average unemployment rose sharply in the 1970s and 1980s (peaking at 7.27% in the 1980s), fell through the 1990s and 2000s, rose again in the 2010s (6.22%), lowest in the 1950s (4.51%), with the 2020s so far (4.78%, partial decade) matching the 1960s. 
Day 1 Query 5: I decided to keep all 40 rows, which all have no NULL values. Unemployment 6 months later was higher in 15 cases, lower in 18, and unchanged in 7. This shows association, not causation, because the FED tends to hike when the economy is already strong.

## Observations
1. Unemployment spiked to 14.8% in April 2020, the highest in the dataset, and fell back below 7% by late 2020. 
2. Inflation seems to have been shifting as of late, rising sharply in early 2026 to 4.17% in May, then eased to 3.3% by July 
3. Large fed funds increases were most common in the 1970s (9) and 1980s (7), and it is unclear from this data that they were followed by higher unemployment (15 higher, 18 lower, 7 unchanged). 

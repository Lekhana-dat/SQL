# SQL: Monday Coffee Case Study
A guided SQL exercise on a coffee company's online sales: loading and inspecting tables, cleaning (NULLs, duplicates, wrong totals), joins, aggregation, window functions (`LAG`, `RANK`) and a city recommendation.

**File:** `monday_coffee_analysis.sql` (MySQL)
**Dataset:** the exercise's Monday Coffee tables (city, customers, products, sales); not included here.
**Result in the original write-up:** Delhi, Pune and Jaipur were recommended for expansion. These queries were not re-run when this repo was rebuilt.
**Fixed:** "unique customers per city" now uses `COUNT(DISTINCT ...)`.

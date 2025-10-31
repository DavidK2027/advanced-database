/* A3: Parallel vs Serial Aggregation (≤10 rows data)
---------------------------------------------------
WHAT TO DO
	1. Run a SERIAL aggregation on Service_ALL over the small dataset (e.g., totals by a domain
	column). Ensure result has 3–10 groups/rows.
	2. Run the same aggregation with /*+ PARALLEL(Service_A,8) PARALLEL(Service_B,8) */ to
	force a parallel plan despite small size.
	3. Capture execution plans with DBMS_XPLAN and show AUTOTRACE statistics; timings may
	be similar due to small data.
	4. Produce a 2-row comparison table (serial vs parallel) with plan notes.
EXPECTED OUTPUT
	✓ Two SQL statements (serial and parallel) with hints.
	✓ DBMS_XPLAN outputs for both runs (showing parallel plan chosen in the hinted
	version).
	✓ AUTOTRACE / timing evidence and a small comparison table (mode, ms, buffer
*/


-- 1. Create Aggregation Queries
-- In Commercial Database
\c commercial_insurance_db

-- A3.1: SERIAL aggregation
SELECT 'SERIAL AGGREGATION' as execution_mode;
EXPLAIN (ANALYZE, BUFFERS) 
SELECT 
    service_type,
    COUNT(*) as service_count,
    AVG(cost) as avg_cost,
    SUM(cost) as total_cost
FROM Service_ALL
GROUP BY service_type
ORDER BY service_type;

-- A3.2: PARALLEL aggregation with hints
SELECT 'PARALLEL AGGREGATION' as execution_mode;
EXPLAIN (ANALYZE, BUFFERS) 
SELECT /*+ Parallel(Service_A, 8) Parallel(Service_B_proj_link, 8) */
    service_type,
    COUNT(*) as service_count,
    AVG(cost) as avg_cost,
    SUM(cost) as total_cost
FROM Service_ALL
GROUP BY service_type
ORDER BY service_type;
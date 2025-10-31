/* A5: Distributed Lock Conflict & Diagnosis (no extra rows)
----------------------------------------------------------
WHAT TO DO
	1. Open Session 1 on Node_A: UPDATE a single row in Claim or Service and keep the transaction
	open.
	2. Open Session 2 from Node_B via Claim@proj_link or Service@proj_link to UPDATE the same
	logical row.
	3. Query lock views (DBA_BLOCKERS/DBA_WAITERS/V$LOCK) from Node_A to show the
	waiting session.
	4. Release the lock; show Session 2 completes. Do not insert more rows; reuse the existing ≤10.
EXPECTED OUTPUT
	✓ Two UPDATE statements showing the contested row keys.
	✓ Lock diagnostics output identifying blocker/waiter sessions.
	✓ Timestamps showing Session 2 proceeds only after lock release.
*/

--Step 1: Create Lock Conflict ScenarioCreate Lock Conflict Scenario
-- In Commercial Database
\c commercial_insurance_db

-- A5.1: Session 1 - Start transaction and acquire lock
-- Run this in Session 1 (keep transaction open):
BEGIN;
UPDATE Service_A SET cost = cost + 100 WHERE service_id = 2;
-- DO NOT COMMIT YET

-- A5.2: Session 2 - Try to update same logical row from remote
-- Run this in a new session (Session 2) while Session 1 is still open:
BEGIN;
UPDATE Service_B_proj_link SET cost = cost + 50 WHERE service_id = 2;
-- This will block/wait

--Step 2: Lock Diagnosis Queries

-- A5.3: Query lock information from Node_A (Session 3)
SELECT 'LOCK DIAGNOSIS' as diagnosis;

-- Check blocking sessions
SELECT 
    pg_blocking_pids(pid) as blocking_pids,
    state,
    query,
    wait_event_type,
    wait_event
FROM pg_stat_activity 
WHERE state = 'active' AND wait_event_type IS NOT NULL;

-- Check lock details
SELECT 
    locktype,
    relation::regclass,
    mode,
    granted,
    pid
FROM pg_locks 
WHERE relation = 'service_a'::regclass;

-- Check specific lock conflicts
SELECT 
    blocked_locks.pid AS blocked_pid,
    blocking_locks.pid AS blocking_pid,
    blocked_activity.query AS blocked_query,
    blocking_activity.query AS blocking_query
FROM pg_catalog.pg_locks blocked_locks
JOIN pg_catalog.pg_stat_activity blocked_activity ON blocked_activity.pid = blocked_locks.pid
JOIN pg_catalog.pg_locks blocking_locks ON blocking_locks.locktype = blocked_locks.locktype
    AND blocking_locks.DATABASE IS NOT DISTINCT FROM blocked_locks.DATABASE
    AND blocking_locks.relation IS NOT DISTINCT FROM blocked_locks.relation
    AND blocking_locks.page IS NOT DISTINCT FROM blocked_locks.page
    AND blocking_locks.tuple IS NOT DISTINCT FROM blocked_locks.tuple
    AND blocking_locks.virtualxid IS NOT DISTINCT FROM blocked_locks.virtualxid
    AND blocking_locks.transactionid IS NOT DISTINCT FROM blocked_locks.transactionid
    AND blocking_locks.classid IS NOT DISTINCT FROM blocked_locks.classid
    AND blocking_locks.objid IS NOT DISTINCT FROM blocked_locks.objid
    AND blocking_locks.objsubid IS NOT DISTINCT FROM blocked_locks.objsubid
    AND blocking_locks.pid != blocked_locks.pid
JOIN pg_catalog.pg_stat_activity blocking_activity ON blocking_activity.pid = blocking_locks.pid
WHERE NOT blocked_locks.granted;

--Step 3: Release Lock and Verify Completion
-- A5.4: Release the lock from Session 1
-- In Session 1, run:
COMMIT;

-- Now check that Session 2 completes automatically
-- Verify final state
SELECT 'FINAL STATE AFTER LOCK RELEASE' as verification;
SELECT service_id, cost FROM Service_A WHERE service_id = 2;
SELECT service_id, cost FROM Service_B_proj_link WHERE service_id = 2;

--Step 4: Create Lock Monitoring View

-- Create a view for ongoing lock monitoring
CREATE VIEW lock_monitor AS
SELECT
    a.datname,
    a.application_name,
    a.usename,
    a.client_addr,
    a.state,
    a.wait_event_type,
    a.wait_event,
    l.locktype,
    l.mode,
    l.granted,
    a.query,
    a.query_start
FROM pg_stat_activity a
LEFT JOIN pg_locks l ON a.pid = l.pid
WHERE a.state = 'active' 
AND (a.wait_event_type IS NOT NULL OR l.locktype IS NOT NULL);

-- Query the lock monitor
SELECT * FROM lock_monitor;

--------------------------------------
/* Final Verification of All Tasks*/
---------------------------------------

-- Final summary of all tasks
SELECT 'TASK A1: Fragment & Recombine' as task, 'COMPLETED' as status,
    (SELECT COUNT(*) FROM Service_A) as service_a_rows,
    (SELECT COUNT(*) FROM Service_B_proj_link) as service_b_rows,
    (SELECT COUNT(*) FROM Service_ALL) as total_rows
UNION ALL
SELECT 'TASK A2: Cross-Node Join' as task, 'COMPLETED' as status,
    (SELECT COUNT(*) FROM (
        SELECT s.service_id FROM Service_A s 
        JOIN Hospital_proj_link h ON s.service_type = h.service_type 
        WHERE s.cost > 2000
    ) as join_result) as join_rows,
    NULL, NULL
UNION ALL
SELECT 'TASK A3: Parallel Aggregation' as task, 'COMPLETED' as status,
    (SELECT COUNT(*) FROM aggregation_comparison) as comparison_rows,
    NULL, NULL
UNION ALL
SELECT 'TASK A4: Two-Phase Commit' as task, 'COMPLETED' as status,
    (SELECT COUNT(*) FROM transaction_log) as local_transactions,
    (SELECT COUNT(*) FROM dblink(
        'dbname=public_insurance_db host=localhost port=5432 user=postgres password=your_password',
        'SELECT COUNT(*) FROM transaction_log'
    ) AS t(count bigint)) as remote_transactions,
    NULL
UNION ALL
SELECT 'TASK A5: Lock Conflict' as task, 'COMPLETED' as status,
    (SELECT COUNT(*) FROM lock_monitor WHERE granted = false) as current_locks,
    NULL, NULL;

-------------------------------------------------------------
/* Step 1: Create Branch Databases and Enable Extensions*/
--------------------------------------------------------------
-- Connect to Node_A_db database and enable extensions
CREATE EXTENSION postgres_fdw;
CREATE EXTENSION dblink;

/* Step 2: Create Fragmented Tables in nodes Databases*/

-- In Node_A_db: Create Service_A fragment
 
CREATE TABLE Service_A (
    service_id INTEGER PRIMARY KEY,
	claim_id INTEGER,
	service_type VARCHAR(50),
    service_name VARCHAR(100),
    cost DECIMAL(10,2),
    created_date DATE,
    status VARCHAR(20)
);

/* Step 3: Buby Using HASH distribution, Insert a TOTAL of ≤10*/

INSERT INTO Service_A VALUES 
(2, 1, 'Consultation', 'Physiotherapy Session', 5500.00, '2024-01-23', 'Completed'),
(4, 2, 'Consultation and Medication', 'Childbirth (Normal Delivery)', 15000.00, '2024-01-25', 'Completed'),
(6, 3, 'Medical Certificate', 'General Consultation', 5000, '2024-04-15', 'Active'),
(8, 4, 'Consultation and Medication', 'Dental Cleaning', 35000.00, '2024-03-15', 'Completed'),
(10, 1, 'Medical Certificate', 'Laboratory Blood Test', 5000.00, '2024-10-05', 'In Process');


/* Step 4: Create Database Link to Node_B so as to create Combined View*/

-- Create foreign server (proj_link) if not exists
CREATE SERVER IF NOT EXISTS proj_link
FOREIGN DATA WRAPPER postgres_fdw
OPTIONS (host 'localhost', dbname 'Node_B_db', port '5432');

-- Create mapping server user
CREATE USER MAPPING IF NOT EXISTS FOR CURRENT_USER
SERVER proj_link
OPTIONS (user 'postgres', password '12345');

-- Create foreign table for Service_B
CREATE FOREIGN TABLE Service_B_proj_link (
    service_id INTEGER,
    claim_id INTEGER,
	service_type VARCHAR(50),
    service_name VARCHAR(100),    
    cost DECIMAL(10,2),
    created_date DATE,
    status VARCHAR(20)
) SERVER proj_link OPTIONS (schema_name 'public', table_name 'service_b'); --db_link


-- Create combined view
CREATE VIEW Service_ALL AS
SELECT * FROM Service_A
UNION ALL
SELECT * FROM Service_B_proj_link;


/* Step 5: Create Validation Queries */
--Validation Queries

-- Validate counts and checksum
SELECT 'VALIDATION RESULTS' as check_type;

-- Count validation
SELECT 
    (SELECT COUNT(*) FROM Service_A) as service_a_count,
    (SELECT COUNT(*) FROM Service_B_proj_link) as service_b_count,
    (SELECT COUNT(*) FROM Service_ALL) as service_all_count;

-- Checksum validation using MOD 97
SELECT 
    'Service_A' as fragment,
    SUM(MOD(service_id, 97)) as checksum
FROM Service_A
UNION ALL
SELECT 
    'Service_B' as fragment,
    SUM(MOD(service_id, 97)) as checksum
FROM Service_B_proj_link
UNION ALL
SELECT 
    'Service_ALL' as combined,
    SUM(MOD(service_id, 97)) as checksum
FROM Service_ALL;


/* Create Foreign Tables and Run Queries*/

-- In Commercial Database: Create foreign tables
\c commercial_insurance_db

CREATE FOREIGN TABLE Hospital_proj_link (
    hospital_id SERIAL,
    Name 		TEXT,
    Address     TEXT,
    Contact     TEXT,
    Type        TEXT
) SERVER proj_link OPTIONS (schema_name 'public', table_name 'hospital');

DROP FOREIGN TABLE Hospital_proj_link;


CREATE FOREIGN TABLE Claim_proj_link (
    claim_id INTEGER,
    holder_id VARCHAR(9),
    hospital_id INTEGER,
    amountClaimed DECIMAL(10,2),
    dateFiled DATE,
    status VARCHAR(20)
) SERVER proj_link OPTIONS (schema_name 'public', table_name 'claim');

DROP FOREIGN TABLE claim_proj_link;

-- CREATE TABLE claim (
--     claim_id         SERIAL PRIMARY KEY,
--     holder_id        VARCHAR(9) NOT NULL REFERENCES PolicyHolder(holder_id) ON DELETE RESTRICT,
--     hospital_id      INTEGER NOT NULL REFERENCES Hospital(hospital_id) ON DELETE RESTRICT,    
--     amountClaimed   NUMERIC(12,2) NOT NULL CHECK (AmountClaimed >= 0),
-- 	dateFiled       DATE NOT NULL DEFAULT CURRENT_DATE,
--     status          TEXT NOT NULL CHECK (Status IN ('Pending','Approved','Rejected')) DEFAULT 'Pending'
-- );

-- A2.2: Remote SELECT on Claim@proj_link (5 sample rows)

SELECT 'REMOTE CLAIM DATA (First 5 rows)' as query_type;
SELECT * FROM Claim_proj_link ORDER BY claim_id LIMIT 5;

-- A2.3: Distributed join (Service_A & Hospital@proj_link)
SELECT 'DISTRIBUTED JOIN RESULTS' as query_type;
SELECT 
    s.service_id,
    s.claim_id,
    s.service_type,
	S.service_name,
    h.Name,
    h.Address
FROM Service_A s
JOIN Hospital_proj_link h ON s.service_type = h.Name
WHERE s.cost > 2000  -- Selective predicate to limit rows
ORDER BY s.service_id;

SELECT 'DISTRIBUTED JOIN RESULTS' as query_type;
SELECT 
    s.service_id,
    s.service_name,
    s.service_type,
    h.Name,
    h.Address,
    h.Contact
FROM Service_A s
JOIN Hospital_proj_link h ON s.service_type = h.Type
WHERE s.cost > 2000  -- Selective predicate to limit rows
ORDER BY s.service_id;


--A3: Parallel vs Serial Aggregation (≤10 rows data)
--=======================================================

/* A3.1: SERIAL aggregation */

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

--Create Comparison Table

-- Create comparison table for results
CREATE TABLE aggregation_comparison (
    execution_mode VARCHAR(20),
    planning_time_ms DECIMAL(10,2),
    execution_time_ms DECIMAL(10,2),
    total_time_ms DECIMAL(10,2),
    buffer_gets INTEGER,
    plan_notes TEXT
);

-- Manually insert results after running both queries
INSERT INTO aggregation_comparison VALUES
('SERIAL', 0.15, 2.34, 2.49, 45, 'Seq Scan -> HashAggregate'),
('PARALLEL', 0.18, 1.89, 2.07, 52, 'Parallel Seq Scan -> Finalize Aggregate');

SELECT * FROM aggregation_comparison;


--A4: Two-Phase Commit & Recovery (2 rows)

--1. Create PL/SQL Block for 2PC
-- In Commercial Database
\c commercial_insurance_db

-- Create a simple transaction table for testing
CREATE TABLE transaction_log (
    log_id SERIAL PRIMARY KEY,
    node_name VARCHAR(50),
    service_id INTEGER,
    action_type VARCHAR(20),
    transaction_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create similar table in Public database via dblink
SELECT dblink_exec(
    'dbname=Node_B_db host=localhost port=5432 user=postgres password=12345',
    'CREATE TABLE IF NOT EXISTS transaction_log (
        log_id SERIAL PRIMARY KEY,
        node_name VARCHAR(50),
        service_id INTEGER,
        action_type VARCHAR(20),
        transaction_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    )'
);


-- A4.1: PL/SQL block for two-phase commit
-- CREATE OR REPLACE FUNCTION two_phase_commit_example()
-- RETURNS TEXT AS $$
-- DECLARE
--     local_insert_id INTEGER;
--     remote_insert_id INTEGER;
-- BEGIN
--     -- Insert local row on Node_A
--     INSERT INTO transaction_log (node_name, service_id, action_type)
--     VALUES ('Node_A_db', 2, '2PC_Test') RETURNING log_id INTO local_insert_id;
    
--     -- Insert remote row on Node_B via dblink
--     PERFORM dblink_exec(
--         'dbname=Node_B_db host=localhost port=5432 user=postgres password=12345',
--         'INSERT INTO transaction_log (node_name, service_id, action_type) ' ||
--         'VALUES (''Node_B'', 1, ''2PC_Test'')'
--     );
    
--     -- Both inserts successful, now commit
--     COMMIT;
    
--     RETURN '2PC Successful: Local ID=' || local_insert_id;
-- EXCEPTION
--     WHEN OTHERS THEN
--         ROLLBACK;
--         -- Also rollback remote if possible
--         PERFORM dblink_exec(
--             'dbname=Node_B_db host=localhost port=5432 user=postgres password=12345',
--             'ROLLBACK'
--         );
--         RETURN '2PC Failed: ' || SQLERRM;
-- END;
-- $$ LANGUAGE plpgsql;

-- -- Test the 2PC function
-- SELECT two_phase_commit_example();

-- Complete working example with proper error handling
CREATE OR REPLACE FUNCTION two_phase_commit_verified()
RETURNS TABLE(status_text TEXT, local_id INTEGER, remote_count INTEGER) AS $$
DECLARE
    local_insert_id INTEGER;
    remote_insert_result TEXT;
    remote_verify_count INTEGER;
BEGIN
    -- Step 1: Insert into remote database
    SELECT dblink_exec(
        'dbname=Node_B_db host=localhost port=5432 user=postgres password=12345',
        'INSERT INTO transaction_log (node_name, service_id, action_type) ' ||
        'VALUES (''Node_B'', 1, ''2PC_Test'')'
    ) INTO remote_insert_result;
    
    -- Check if remote insert was successful
    IF remote_insert_result != 'INSERT 0 1' THEN
        status_text := 'Remote insert failed: ' || remote_insert_result;
        RETURN NEXT;
        RETURN;
    END IF;
    
    -- Step 2: Insert into local database
    INSERT INTO transaction_log (node_name, service_id, action_type)
    VALUES ('Node_A_db', 2, '2PC_Test') RETURNING log_id INTO local_insert_id;
    
    -- Step 3: Verify remote insert
    SELECT COUNT(*) INTO remote_verify_count
    FROM dblink(
        'dbname=Node_B_db host=localhost port=5432 user=postgres password=12345',
        'SELECT COUNT(*) FROM transaction_log WHERE node_name = ''Node_B'' AND service_id = 1 AND action_type = ''2PC_Test'''
    ) AS t(count bigint);
    
    status_text := '2PC Successful';
    local_id := local_insert_id;
    remote_count := remote_verify_count;
    
    RETURN NEXT;
    
EXCEPTION
    WHEN OTHERS THEN
        -- If we get here, the local insert failed but remote might have succeeded
        -- Try to clean up remote insert
        BEGIN
            PERFORM dblink_exec(
                'dbname=Node_B_db host=localhost port=5432 user=postgres password=12345',
                'DELETE FROM transaction_log WHERE node_name = ''Node_B'' AND service_id = 1 AND action_type = ''2PC_Test'''
            );
            status_text := '2PC Failed - Compensated: ' || SQLERRM;
        EXCEPTION
            WHEN OTHERS THEN
                status_text := '2PC Failed - Could not compensate: ' || SQLERRM;
        END;
        
        local_id := NULL;
        remote_count := NULL;
        RETURN NEXT;
END;
$$ LANGUAGE plpgsql;

-- Test with verification
SELECT * FROM two_phase_commit_verified();


--Step 1: Create Lock Conflict ScenarioCreate Lock Conflict Scenario
-- In Commercial Database
\c commercial_insurance_db

--A5 QUESTION
-----------
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






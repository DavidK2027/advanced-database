/* A4: Two-Phase Commit & Recovery (2 rows)
-------------------------------------------
WHAT TO DO
	1. Write one PL/SQL block that inserts ONE local row (related to Service) on Node_A and ONE
	remote row into Service@proj_link (or Claim@proj_link); then COMMIT.
	2. Induce a failure in a second run (e.g., disable the link between inserts) to create an in-doubt
	transaction; ensure any extra test rows are ROLLED BACK to keep within the ≤10 committed row
	budget.
	3. Query DBA_2PC_PENDING; then issue COMMIT FORCE or ROLLBACK FORCE; re-verify
	consistency on both nodes.
	4. Repeat a clean run to show there are no pending transactions.
EXPECTED OUTPUT
	✓ PL/SQL block source code (two-row 2PC).
	✓ DBA_2PC_PENDING snapshot before/after FORCE action.
	✓ Final consistency check: the intended single row per side exists exactly once; total committed rows remain ≤10.*/

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
    'dbname=public_insurance_db host=localhost port=5432 user=postgres password=your_password',
    'CREATE TABLE IF NOT EXISTS transaction_log (
        log_id SERIAL PRIMARY KEY,
        node_name VARCHAR(50),
        service_id INTEGER,
        action_type VARCHAR(20),
        transaction_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    )'
);

-- A4.1: PL/SQL block for two-phase commit
CREATE OR REPLACE FUNCTION two_phase_commit_example()
RETURNS TEXT AS $$
DECLARE
    local_insert_id INTEGER;
    remote_insert_id INTEGER;
BEGIN
    -- Insert local row on Node_A
    INSERT INTO transaction_log (node_name, service_id, action_type)
    VALUES ('Node_A', 2, '2PC_Test') RETURNING log_id INTO local_insert_id;
    
    -- Insert remote row on Node_B via dblink
    PERFORM dblink_exec(
        'dbname=public_insurance_db host=localhost port=5432 user=postgres password=your_password',
        'INSERT INTO transaction_log (node_name, service_id, action_type) ' ||
        'VALUES (''Node_B'', 1, ''2PC_Test'')'
    );
    
    -- Both inserts successful, now commit
    COMMIT;
    
    RETURN '2PC Successful: Local ID=' || local_insert_id;
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        -- Also rollback remote if possible
        PERFORM dblink_exec(
            'dbname=public_insurance_db host=localhost port=5432 user=postgres password=your_password',
            'ROLLBACK'
        );
        RETURN '2PC Failed: ' || SQLERRM;
END;
$$ LANGUAGE plpgsql;

-- Test the 2PC function
SELECT two_phase_commit_example();

--2. Induce Failure and Check Pending Transactions

-- A4.2: Induce failure scenario
CREATE OR REPLACE FUNCTION two_phase_commit_failure()
RETURNS TEXT AS $$
BEGIN
    -- Insert local row
    INSERT INTO transaction_log (node_name, service_id, action_type)
    VALUES ('Node_A', 4, '2PC_Failure_Test');
    
    -- Simulate network failure by using wrong connection details
    PERFORM dblink_exec(
        'dbname=wrong_db host=localhost port=5432 user=postgres password=wrong_pass',
        'INSERT INTO transaction_log (node_name, service_id, action_type) ' ||
        'VALUES (''Node_B'', 3, ''2PC_Failure_Test'')'
    );
    
    COMMIT;
    RETURN 'Should not reach here';
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RETURN '2PC Failed as expected: ' || SQLERRM;
END;
$$ LANGUAGE plpgsql;

-- Test failure scenario
SELECT two_phase_commit_failure();

-- A4.3: Check for pending transactions (PostgreSQL equivalent)
SELECT 'Checking for prepared transactions' as check_type;
SELECT * FROM pg_prepared_xacts;

-- If any prepared transactions exist, commit or rollback them
-- SELECT pg_terminate_backend(pid) FROM pg_prepared_xacts;

--3 Final Consistency Check
-- A4.4: Verify final state
SELECT 'FINAL CONSISTENCY CHECK' as verification;

-- Check Node_A transactions
SELECT 'Node_A Transactions' as node, COUNT(*) as total_rows FROM transaction_log
UNION ALL
-- Check Node_B transactions via dblink
SELECT 'Node_B Transactions' as node, COUNT(*) as total_rows 
FROM dblink(
    'dbname=public_insurance_db host=localhost port=5432 user=postgres password=your_password',
    'SELECT COUNT(*) FROM transaction_log'
) AS t(count bigint);
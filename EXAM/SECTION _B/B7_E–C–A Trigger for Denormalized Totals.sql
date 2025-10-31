-- 1. Create an audit table Bill_AUDIT(bef_total NUMBER, aft_total NUMBER, changed_at TIMESTAMP, key_col VARCHAR2(64)).

CREATE TABLE bill_audit (
    bef_total NUMERIC(12,2), 						 -- to view total before change
    aft_total NUMERIC(12,2),       					 -- to view total after change
    changed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,  -- to viewwhen the change happened 
    key_col VARCHAR(64) 							 -- identifies which record was changed 
);


-- 2. Implement a statement-level AFTER INSERT/UPDATE/DELETE trigger on Payment that recomputes denormalized totals in Bill once per statement.
/*creating table for recording total by summing all payments */
CREATE TABLE bill (
    bill_id SERIAL PRIMARY KEY,
    total NUMERIC(12,2) DEFAULT 0
);

ALTER TABLE Payment
    ALTER COLUMN cost SET NOT NULL,
    ALTER COLUMN servicedate SET NOT NULL;

/*add bill_id to*/
ALTER TABLE Payment
	bill_id SERIAL;



--Create the Trigger Function for computing tatal bill

SELECT * FROM Payment

CREATE OR REPLACE FUNCTION compute_bill_totals()
RETURNS TRIGGER AS $$
BEGIN
    -- Recalculate totals for all affected bills
    UPDATE Bill b
    SET total = COALESCE((
        SELECT SUM(p.amount)
        FROM Payment p
        WHERE p.bill_id = b.bill_id
    ), 0)
    WHERE b.bill_id IN (
        SELECT DISTINCT bill_id FROM Payment
    );

    RETURN NULL;
END;
$$ LANGUAGE plpgsql;


-- 3. Execute a small mixed DML script on CHILD affecting at most 4 rows in total; ensure net committed rows across the project remain ≤10.

-- INSERT INTO Claim(HolderID, HospitalID, DateFiled, AmountClaimed, Status) VALUES
--   -- ('A00000001', 1, '2025-01-12', 300000.00, 'Pending'),
--   -- ('B00000002', 2, '2025-02-10', 120000.00, 'Approved'),  


INSERT INTO Payment(ClaimID, AssessorID, Amount, PaymentDate, Method) VALUES
  (7, 1, 1200.00, '2025-02-12 10:00:00+03', 'Bank Transfer'),
  (1, 1, 1500.00, '2025-03-07 09:30:00+03', 'Bank Transfer'),
  --(3, 3, 800.00, '2025-07-25 14:00:00+03', 'Cash'),
  (4, 2, 250.00, '2025-09-05 11:00:00+03', 'Mobile Money');
  
-- 4. Log before/after totals to the audit table (2–3 audit rows).

SELECT * FROM bill_audit;

/* EXPECTED OUTPUT
	CREATE TABLE Bill_AUDIT … and CREATE TRIGGER source code.
	Mixed DML script and SELECT from totals showing correct recomputation.
	SELECT * FROM Bill_AUDIT with 2–3 audit entries.
*/

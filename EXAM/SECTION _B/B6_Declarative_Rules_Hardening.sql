--1. On tables Claim and Service, add/verify NOT NULL and domain CHECK constraints suitable for claim costs and approvals (e.g., positive amounts, valid statuses, date order).
/* ALTERING TABLE to add  NOT NULL and CHECK constraints */


--A) claim TABLE.

SELECT * FROM claim; --to view table collumns names and data

--adding "approvaldate" column for trucking approved date
ALTER TABLE claim
  ADD approvaldate DATE;


ALTER TABLE claim
    ALTER COLUMN amountclaimed SET NOT NULL,
    ALTER COLUMN status SET NOT NULL,
    ALTER COLUMN datefiled SET NOT NULL;

-- constraint to ensure that claim amounts is postive

ALTER TABLE claim
    ADD CONSTRAINT check_claim_amount_positive
    CHECK (amountclaimed > 0);

-- constraint to ensure that approval status to be valid.

ALTER TABLE claim
    ADD CONSTRAINT check_claim_approval_status
    CHECK (status IN ('Pending', 'Approved', 'Rejected'));

-- constraint to ensure that approval date is not before claim date

ALTER TABLE claim
    ADD CONSTRAINT check_claim_date_order
    CHECK (
        approvaldate IS NULL 
        OR approvaldate >= datefiled
);

--B) service TABLE.

SELECT * FROM service; --to view table collumns names and data

ALTER TABLE service
    ALTER COLUMN cost SET NOT NULL,
    ALTER COLUMN servicedate SET NOT NULL;

-- constraint for positive service cost
ALTER TABLE Service
    ADD CONSTRAINT check_service_cost_positive
    CHECK (cost > 0);

--  constraint for service date is reasonable (not in far future, optional)
ALTER TABLE Service
    ADD CONSTRAINT check_service_date_valid
    CHECK (servicedate <= CURRENT_DATE + INTERVAL '30 days');


--2. Prepare 2 failing and 2 passing INSERTs per table to validate rules, but wrap failing ones in a block and ROLLBACK so committed rows stay within ≤10 total.
--=> Verify Constraints

--Test NOT NULL Constraints
--This should fail (service_cost is NULL)

SELECT * FROM Service;
SELECT * FROM policyholder;

INSERT INTO Service (claimid, description, cost)
VALUES (1, 'Consultation', -2000);

INSERT INTO Service(ClaimID, Description, Cost, ServiceDate) VALUES
  (2, 'Consultation', 1100.00, '2025-01-10');

  
INSERT INTO claim (HolderID, HospitalID, AmountClaimed, Status)
VALUES ('A00000001', 1, 1000.00, 'Pending');

INSERT INTO claim (HolderID, HospitalID)
VALUES ('A00000001', 1);

--3. Show clean error handling for failing cases.

--=> errors 1:
ERROR:  null value in column "cost" of relation "service" violates not-null constraint
Failing row contains (37, 1, Consultation, null, null). 

SQL state: 23502
Detail: Failing row contains (37, 1, Consultation, null, null).

--=> errors 3: 
ERROR:  Policy holder A00000002 has no plan or plan not found
CONTEXT:  PL/pgSQL function fn_check_claim_within_plan_limit() line 12 at RAISE 

SQL state: P0001

/* EXPECTED OUTPUT
	ALTER TABLE statements for added constraints (named consistently).
	Script with test INSERTs and captured ORA- errors for failing cases.
	SELECT proof that only the passing rows were committed; total committed rows ≤10.
*/

--WHAT TO DO
--------------
	--1. Create BUSINESS_LIMITS(rule_key VARCHAR2(64), threshold NUMBER, active CHAR(1) CHECK(active IN('Y','N'))) and seed exactly one active rule.
	
--2. Implement function fn_should_alert(...) that reads BUSINESS_LIMITS and inspects current data in Service or Claim to decide a violation (return 1/0).
	/* A) Create the BUSINESS_LIMITS table */
	
	CREATE TABLE BUSINESS_LIMITS (
	    rule_key VARCHAR(64),
	    threshold NUMERIC(12,2),
	    active CHAR(1) CHECK (active IN ('Y', 'N')));

	--=> Insert one active rule
	INSERT INTO BUSINESS_LIMITS VALUES ('MAX_SERVICE_COST', 20000, 'Y');
	COMMIT;

	SELECT * FROM BUSINESS_LIMITS 

	/* B) Create the function fn_should_alert(...) to check if the new service record viloted the business rule.*/
--. Function that checks threshold

CREATE OR REPLACE FUNCTION fn_should_alert(p_service_cost NUMERIC)
RETURNS INTEGER AS $$
DECLARE
    v_threshold NUMERIC;
BEGIN
    -- Read the active rule threshold
    SELECT threshold
    INTO v_threshold
    FROM business_limits
    WHERE active = 'Y' AND rule_key = 'MAX_SERVICE_COST';

    -- Compare with provided cost
    IF p_service_cost > v_threshold THEN
        RETURN 1;  -- violation
    ELSE
        RETURN 0;  -- ok
    END IF;

EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RETURN 0;  -- no rule active, no alert
END;
$$ LANGUAGE plpgsql;
	

	
--3. Create a BEFORE INSERT OR UPDATE trigger on Service (or relevant table) that raises an application error when fn_should_alert returns 1.

/* 	Create a trigger on Service to invokes the function before inserting/updating a record.
	to check If the rule is violated, so as to raises an application error and stopping the DML.*/ 


-- 4. Trigger function (use NEW.cost)
CREATE OR REPLACE FUNCTION trg_service_cost_limit_func()
RETURNS TRIGGER AS $$
DECLARE
    v_alert INTEGER;
BEGIN
    -- Call validation function
    v_alert := fn_should_alert(NEW.cost);

    -- If alert triggered, raise exception
    IF v_alert = 1 THEN
        RAISE EXCEPTION 'Service cost exceeds business threshold!';
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;


-- 5. Attach trigger to Service table
CREATE TRIGGER trg_service_cost_limit
BEFORE INSERT OR UPDATE
ON service
FOR EACH ROW
EXECUTE FUNCTION trg_service_cost_limit_func();

--insert record in service table to check

INSERT INTO Service(ClaimID, Description, Cost, ServiceDate) VALUES
  (3, 'Consultation', 100000.00, '2025-01-10');

SELECT * FROM service;

--4. Demonstrate 2 failing and 2 passing DML cases; rollback the failing ones so total committed rows remain within the ≤10 budget.
now let us maTest Cases — 2 Failing and 2 Passing DMLs
/* EXPECTED OUTPUT
	DDL for BUSINESS_LIMITS, function source, and trigger source.
	Execution proof: two failed DML attempts (ORA- error) and two successful DMLs that commit.
	SELECT showing resulting committed data consistent with the rule; row budget respected.
*/



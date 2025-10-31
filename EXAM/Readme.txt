TOPIC: DIGITAL HEALTH INSURANCE &amp; CLAIMS
----------------------------------------------

The Summary
------------
This read me file is all about ADVANCED DATABASE PROJECT-BASE EXAM. The exam has two main sections (A & B).
Section A has 5 questions and B has 5 questions and each question ha it’s related sub questions as more detailed here bellow.
PostgreSQL is the database used during this project. 

------------
 section A
------------

Here is the list of section B with their respective implemented SQL solution and results

A1: Fragment & Recombine Main Fact
-----------------------------------

Question overview:
------------------- 
this question is all about performing database distribution by creating Nodes (Node A and Node B) then create and fragment table on those both nodes.
by using (HASH or RANGE) rule. creating views and running query to check if all work well. here bellow is the step by step demonstration of the solution to this question:

	1. Create Branch Databases(Nodes) and Enable Extensions 
	2. On central database (insurance_central_db) Create the main Service table to fragment to Node A and Node B.
	3. Create Fragmented Tables in nodes Databases	
        4. Buby Using HASH distribution, Insert data and split them across the two nodes
	5. Create Database Link so as to create Combined View.	  
        6. Create foreign table for Service_B and view.
	7. Create Validation Queries.

SQL/SCRIPTS
------------

1.---------------------------------------------------------------------------
/* Create Node_A database */ 
CREATE DATABASE Node_A_db;

/* Create Node_B database */  
CREATE DATABASE Node_B_db;

/* Connect to Node_A_db database and enable extensions*/
CREATE EXTENSION postgres_fdw;
CREATE EXTENSION dblink;

/* Connect to Node_B_db database and enable extensions */  
CREATE EXTENSION postgres_fdw;
CREATE EXTENSION dblink;

2.----------------------------------------------------------------------------------
/*on central database (insurance_central_db) Create the main Service table to flagment */
CREATE TABLE service (
    service_id SERIAL PRIMARY KEY,
	claim_id INTEGER NOT NULL REFERENCES claim(claim_id) ON DELETE CASCADE,
    service_name VARCHAR(100) NOT NULL,
    service_type VARCHAR(50) CHECK (service_type IN ('Claims Processing', 'Customer Support', 'Risk Assessment', 'Policy Management')),
    cost DECIMAL(10,2)NOT NULL CHECK (Cost >= 0),
    created_date DATE DEFAULT CURRENT_DATE,
    status VARCHAR(20) DEFAULT 'Active',
    CHECK (status IN ('Active', 'In Process', 'Completed'))
);







------------
 Section B
------------

Here is the list of section B with their respective implemented SQL solution and results

B6: Declarative Rules Hardening
--------------------------------

Question overview:
------------------- 
this question is all about implementing NOT NULL and domain CHECK constraints table' columns then after check the constrain implementation.
here bellow is the step by step demonstration of the solution to this question:

	1. Altering claim table to add constraint for: 
	2. adding approvaldate column to the claim table
	3. appliying NOT NULL constraints	
        4. Validating "status" values ("Pending", "Approved", "Rejected").
	5. Positive "amountclaimed" and "cost".	  
        6. Logical approval date ("approvaldate" >= datefiled`).


SQL/SCRIPTS
------------

1.---------------------------------------------------------------------------
ALTER TABLE claim
  ADD approvaldate DATE;

2.---------------------------------------------------------------------------
ALTER TABLE claim
    ALTER COLUMN amountclaimed SET NOT NULL,
    ALTER COLUMN status SET NOT NULL,
    ALTER COLUMN datefiled SET NOT NULL;

3.---------------------------------------------------------------------------
ALTER TABLE claim
    ADD CONSTRAINT check_claim_approval_status
    CHECK (status IN ('Pending', 'Approved', 'Rejected'));

4.---------------------------------------------------------------------------
ALTER TABLE claim
    ADD CONSTRAINT check_claim_amount_positive
    CHECK (amountclaimed > 0);

**applying NOT NULL to cost and service date**

ALTER TABLE service
    ALTER COLUMN cost SET NOT NULL,
    ALTER COLUMN servicedate SET NOT NULL;

**constraint for applying positive service cost**

ALTER TABLE Service
    ADD CONSTRAINT check_service_cost_positive
    CHECK (cost > 0);

5.----------------------------------------------------------------------------
ALTER TABLE claim
    ADD CONSTRAINT check_claim_date_order
    CHECK (
        approvaldate IS NULL 
        OR approvaldate >= datefiled
);

** constraint for service date is reasonable (not in far future, optional)**

ALTER TABLE Service
    ADD CONSTRAINT check_service_date_valid
    CHECK (servicedate <= CURRENT_DATE + INTERVAL '30 days');


SQL/SCRIPTS OUTPUT
------------------

screenshots for tests 

** 1. Create an audit table **
** 2. Test negative cost Constraints on service table **
** 3. test of insert successful records with constraints followed  **



B7: E–C–A Trigger for Denormalized Totals (small DML set)
----------------------------------------------------------

Question overview:
------------------- 
this question is all about creating an audit table and a trigger for billing (payment) computation tracking.
here bellow is the step by step executions to achieve these:

	1. Create an audit table Bill_AUDIT 
	2. Creating bill table to keep records about total by summing all payments
	3. update payment table to add "bill_id" column as a foreign key (relation between  payment and  bill_audit).
	4. Create the Trigger Function for computing total bill
	5. insert records in payment table for testing
	6. select data in bill_audit table to check Log before/after totals


SQL/SCRIPTS
------------

1.-------------------------------------------------------------------------------------------------

CREATE TABLE bill_audit (
    bef_total NUMERIC(12,2), 			      -- to view total before change
    aft_total NUMERIC(12,2),       		      -- to view total after change
    changed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,   -- to view when the change happened 
    key_col VARCHAR(64) 			      -- identifies which record was changed 
);


2.---------------------------------------------------------------------------------------------------

CREATE TABLE bill (
    bill_id SERIAL PRIMARY KEY,
    total NUMERIC(12,2) DEFAULT 0
);


3.------------------------------------------------------

ALTER TABLE Payment
  ADD bill_id SERIAL;


4.-----------------------------------------------------

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


5. ---------------------------------------------------------------------------

INSERT INTO Payment(ClaimID, AssessorID, Amount, PaymentDate, Method) VALUES
  (9, 1, 1200.00, '2025-02-12 10:00:00+03', 'Bank Transfer'),
  (8, 1, 1500.00, '2025-03-07 09:30:00+03', 'Bank Transfer');


6. -------------------------------------------------------------

SELECT * FROM bill_audit;


SQL/SCRIPTS OUTPUT
------------------

screenshots for tests 

** 1.view audit entries **


B8: Recursive Hierarchy Roll-Up (6–10 rows)
---------------------------------------------

Question overview:
------------------- 
this question is all about creating a hierarchy table for a natural hierarchy (domain-specific).
here bellow is the step by step executions to achieve these:

	1. Create table HIER table 
	2. Insert 6–10 rows forming a 3-level hierarchy
	3. write recursive query to finding all children of a root.
	4. make join hierarchy to Service and do aggregate


SQL/SCRIPTS
------------

1.---------------------------------------------------------

CREATE TABLE HIER (
    parent_id INT REFERENCES HIER(child_id),
    child_id  INT,
    name      VARCHAR(50),
    PRIMARY KEY (child_id)
);


2.---------------------------------------------------------

INSERT INTO HIER (parent_id, child_id, name) VALUES
(NULL, 1, 'Insurance Services'),
(1, 2, 'Health Insurance'),
(1, 3, 'Vehicle Insurance'),
(2, 4, 'Surgery Coverage'),
(2, 5, 'Dental Coverage'),
(3, 6, 'Accident Claims');


3.------------------------------------------------------

WITH RECURSIVE tree AS (
    SELECT child_id, parent_id, name, 0 AS depth
    FROM HIER
    WHERE parent_id IS NULL  -- start from root

    UNION ALL

    SELECT h.child_id, h.parent_id, h.name, t.depth + 1
    FROM HIER h
    JOIN tree t ON h.parent_id = t.child_id
)

SELECT * FROM HIER ORDER BY child_id;


4.-----------------------------------------------------

WITH RECURSIVE hier_cte AS (
    SELECT child_id, child_id AS root_id, 0 AS depth
    FROM HIER WHERE parent_id IS NULL
    UNION ALL
    SELECT h.child_id, c.root_id, c.depth + 1
    FROM HIER h
    JOIN hier_cte c ON h.parent_id = c.child_id
)
SELECT 
    h.root_id,
    COUNT(s.serviceid) AS service_count,
    SUM(s.cost) AS total_cost
FROM hier_cte h
LEFT JOIN Service s ON s.serviceid = h.child_id
GROUP BY h.root_id
ORDER BY h.root_id;


SQL/SCRIPTS OUTPUT
------------------

screenshots for tests 

** 1.view aggregate validating rollup **


B9: Mini-Knowledge Base with Transitive Inference
---------------------------------------------------

Question overview:
------------------- 
this question is all about creating a TRIPLE to stores information as a set of subject–predicate–object facts.
here bellow is the step by step executions to achieve these:

	1. create a TRIPLE table 
	2. Insert 8–10 domain facts relevant to your project(for my case “Insurance / Claim / Service)
	3. Write a recursive inference query implementing transitive isA*
	4. query for Validating grouping and label consistency 


SQL/SCRIPTS
------------

1.---------------------------------------------------------

CREATE TABLE TRIPLE (
    s VARCHAR(64),   -- Subject
    p VARCHAR(64),   -- Predicate
    o VARCHAR(64)    -- Object
);


2.---------------------------------------------------------

INSERT INTO TRIPLE (s, p, o) VALUES
	('Service', 'isA', 'BusinessProcess'),
	('ClaimService', 'isA', 'Service'),
	('MedicalService', 'isA', 'Service'),
	('DentalService', 'isA', 'MedicalService'),
	('PaymentService', 'isA', 'FinancialService'),
	('FinancialService', 'isA', 'Service'),
	('Claim', 'involves', 'ClaimService'),
	('Bill', 'requires', 'PaymentService'),
	('ClaimService', 'supports', 'Patient'),
	('MedicalService', 'supports', 'Patient');

SELECT * from TRIPLE;


3.------------------------------------------------------

WITH RECURSIVE isa_chain AS (
    -- Base case: direct isA facts
    SELECT s, o AS superclass
    FROM TRIPLE
    WHERE p = 'isA'
    
    UNION
    
    -- Recursive case: transitive closure
    SELECT t.s, i.superclass
    FROM TRIPLE t
    JOIN isa_chain i ON t.o = i.s
    WHERE t.p = 'isA'
)
SELECT DISTINCT s AS child, superclass, 'inferred isA*' AS label
FROM isa_chain
ORDER BY child, superclass
LIMIT 10;

4.-----------------------------------------------------

SELECT superclass, COUNT(*) AS num_children
FROM (
    WITH RECURSIVE isa_chain AS (
        SELECT s, o AS superclass FROM TRIPLE WHERE p='isA'
        UNION
        SELECT t.s, i.superclass FROM TRIPLE t JOIN isa_chain i ON t.o=i.s WHERE t.p='isA'
    )
    SELECT DISTINCT s, superclass FROM isa_chain
) grouped
GROUP BY superclass;


SQL/SCRIPTS OUTPUT
------------------

screenshots for tests 

** 1.view a Grouping counts proving inferred labels are consistent **


B10: Business Limit Alert (Function + Trigger) (row-budget safe)
-----------------------------------------------------------------

Question overview:
------------------- 
this question is all about Creating a BUSINESS_LIMITS table for keeping business rules. creating function and trigger to enforce those business limit rules.
here bellow is the step by step executions to achieve these:

	1. Create BUSINESS_LIMITS rules table 
	2. Insert one active sample rule in the table.
	3. Create the function a function for checking business rule violation at every new/update record.
	4. Create a BEFORE INSERT OR UPDATE trigger on Service that invoke  the function before inserting/updating a record 
	5. Attaching the trigger to table in case (EX: Service)
	6. insert record in service table to check 


SQL/SCRIPTS
------------

1.---------------------------------------------------------

CREATE TABLE BUSINESS_LIMITS (
	    rule_key VARCHAR(64),
	    threshold NUMERIC(12,2),
	    active CHAR(1) CHECK (active IN ('Y', 'N'))
);


2.---------------------------------------------------------

INSERT INTO BUSINESS_LIMITS VALUES ('MAX_SERVICE_COST', 20000, 'Y');
COMMIT;

3.------------------------------------------------------

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


4.-----------------------------------------------------

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

5.-----------------------------------------------------

CREATE TRIGGER trg_service_cost_limit
BEFORE INSERT OR UPDATE
ON service
FOR EACH ROW
EXECUTE FUNCTION trg_service_cost_limit_func();


6.-----------------------------------------------------

INSERT INTO Service(ClaimID, Description, Cost, ServiceDate) VALUES
  (3, 'Consultation', 100000.00, '2025-01-10');


SQL/SCRIPTS OUTPUT
------------------

screenshots for tests 

** 1.Execution proof of two failed DML attempts (ORA- error) and two successful **








 




   
 



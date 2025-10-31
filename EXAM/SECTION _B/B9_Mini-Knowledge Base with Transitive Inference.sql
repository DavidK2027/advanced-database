-- 1. Create table TRIPLE(s VARCHAR2(64), p VARCHAR2(64), o VARCHAR2(64)).
/*create a TRIPLE table to stores information as a set of subject–predicate–object facts.*/

CREATE TABLE TRIPLE (
    s VARCHAR(64),   -- Subject
    p VARCHAR(64),   -- Predicate
    o VARCHAR(64)    -- Object
);


-- 2. Insert 8–10 domain facts relevant to your project (e.g., simple type hierarchy or rule implications).
/* for my case “Insurance / Claim / Service”. here Below is a service hierarchy and business relationships that could exist in it.*/

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


-- 3. Write a recursive inference query implementing transitive isA*; apply labels to base records and return up to 10 labeled rows.
/*	Now let create a recursive inference query to find all transitive relationships of the isA predicate
	(to find if DentalService isA MedicalService and MedicalService isA Service, then infer DentalService isA Service.)
*/

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


-- 4. Ensure total committed rows across the project (including TRIPLE) remain ≤10; you may delete temporary rows after demo if needed.
/* quey for Validating grouping and label consistency */

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


/*EXPECTED OUTPUT
	DDL for TRIPLE and INSERT scripts for 8–10 facts.
	Inference SELECT (with recursive part) and sample labeled output (≤10 rows).
	Grouping counts proving inferred labels are consistent.
*/

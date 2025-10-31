-- 1. Create table HIER(parent_id, child_id) for a natural hierarchy (domain-specific).
/* creating A hierarchy table which is self-referencing list table) to  parent-child-  
relationships between entities within the same table.*/
--1 You need a flexible number of levels (not just 1–2).
--2 You want to easily add new branches.
--3 You’re okay using recursive CTEs for reporting and rollups.

CREATE TABLE HIER (
    parent_id INT REFERENCES HIER(child_id),
    child_id  INT,
    name      VARCHAR(50),
	PRIMARY KEY (child_id)
);


-- 2. Insert 6–10 rows forming a 3-level hierarchy.

INSERT INTO HIER (parent_id, child_id, name) VALUES
(NULL, 1, 'Insurance Services'),
(1, 2, 'Health Insurance'),
(1, 3, 'Vehicle Insurance'),
(2, 4, 'Surgery Coverage'),
(2, 5, 'Dental Coverage'),
(3, 6, 'Accident Claims');

SELECT * from HIER;

-- 3. Write a recursive WITH query to produce (child_id, root_id, depth) and join to Service or its parent to compute rollups; return 6–10 rows total.
 /*write recursive query to finding all children of a root  */

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

-- 4. Reuse existing seed rows; do not exceed the ≤10 committed rows budget.
/*Now, let make join hierarchy to Service and aggregate by root:*/

SELECT * FROM service

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


/* EXPECTED OUTPUT
	DDL + INSERTs for HIER (6–10 rows).
	Recursive WITH SQL and sample output rows (6–10).
	Control aggregation validating rollup correctness.
*/

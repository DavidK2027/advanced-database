/*A1: Fragment & Recombine Main Fact (≤10 rows)
----------------------------------------------
WHAT TO DO
1. Create horizontally fragmented tables Service_A on Node_A and Service_B on Node_B using a
deterministic rule (HASH or RANGE on a natural key).
2. Insert a TOTAL of ≤10 committed rows split across the two fragments (e.g., 5 on Node_A and 5
on Node_B). Reuse these rows for all remaining tasks.
3. On Node_A, create view Service_ALL as UNION ALL of Service_A and Service_B@proj_link.
4. Validate with COUNT(*) and a checksum on a key column (e.g., SUM(MOD(primary_key,97)))
:results must match fragments vs Service_ALL.
EXPECTED OUTPUT
✓ DDL for Service_A and Service_B; population scripts with ≤10 total committed rows.
✓ CREATE DATABASE LINK proj_link ... (shown).
✓ CREATE VIEW Service_ALL … UNION ALL … (shown).
✓ Matching COUNT(*) and checksum between fragments vs Service_ALL (evidence
screenshot).*/

/*steps to answer to this question*/
	/*i have alread two brachs or node (commercial_insurance_db & public_insurance_db). 
	instead of using the current nodes , let me create new one for this question*/

/* Step 1: Create Branch Databases(Nodes) and Enable Extensions*/

-- Create Node_A database
CREATE DATABASE Node_A_db;

-- Create Node_B database  
CREATE DATABASE Node_B_db;

-- Connect to Node_A_db database and enable extensions
CREATE EXTENSION postgres_fdw;
CREATE EXTENSION dblink;

-- Connect to Node_B_db database and enable extensions  
CREATE EXTENSION postgres_fdw;
CREATE EXTENSION dblink;

/* Step 2: on central database (insurance_central_db) Create the main Service table to flagment to other nodes*/

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

/* Step 3: Create Fragmented Tables in nodes Databases*/

-- In Node_A_db: Create Service_A fragment
 
CREATE TABLE Service_A (
    service_id INTEGER PRIMARY KEY,
	claim_id INTEGER,
    service_name VARCHAR(100),
    service_type VARCHAR(50),
    cost DECIMAL(10,2),
    created_date DATE,
    status VARCHAR(20)
);

--DROP TABLE Service_A;

-- In Node_B_db Database: Create Service_B fragment  

CREATE TABLE Service_B (
    service_id INTEGER PRIMARY KEY,
	claim_id INTEGER,
    service_name VARCHAR(100),
    service_type VARCHAR(50),
    cost DECIMAL(10,2),
    created_date DATE,
    status VARCHAR(20)
);

--DROP TABLE Service_B;

/* Step 3: Buby Using HASH distribution, Insert a TOTAL of ≤10 committed rows split across the two fragments(5 on Node_A and 5
on Node_B)*/

-- on Node_A Insert data into fragments using HASH distribution on service_id

-- Service_A gets even service_id (HASH rule)
INSERT INTO Service_A VALUES 
(2, 1, 'Commercial Claims Processing', 'Claims Processing', 2500.00, '2024-01-15', 'Active'),
(4, 2, 'Business Risk Assessment', 'Risk Assessment', 1800.00, '2024-02-01', 'Active'),
(6, 3, 'Enterprise Policy Management', 'Policy Management', 3200.00, '2024-01-20', 'Active'),
(8, 4, 'Corporate Support', 'Customer Support', 1200.00, '2024-02-10', 'Active'),
(10, 1, 'Commercial Audit Service', 'Risk Assessment', 2800.00, '2024-02-15', 'Active');

 
-- Service_B gets odd service_id (HASH rule)  
INSERT INTO Service_B VALUES 
(1, 5, 'Consultation', 'Vision Test', 5500.00, '2024-01-23', 'Completed'),
(3, 6, 'Consultation and Medication', 'Blood Pressure Monitoring', 15000.00, '2025-01-25', 'In Process'),
(5, 7, 'Consultation and Medication', 'Chemotherapy Session', 5000, '2023-04-15', 'Active'),
(7, 8, 'Consultation and Medication', 'Mental Health Counseling', 35000.00, '2021-03-15', 'In Process'),
(9, 5, 'Medical Certificate', 'COVID-19 Test (PCR)', 1000.00, '2019-10-05', 'Completed');
 
/* Step 4: Create Database Link so as to create Combined View*/

-- In  on Node_A: Create database link to Node_B

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
) SERVER proj_link OPTIONS (schema_name 'public', table_name 'service_b');

-- Create combined view
CREATE VIEW Service_ALL AS
SELECT * FROM Service_A
UNION ALL
SELECT * FROM Service_B_proj_link;


/* Step 5: Make Create Validation Queries */
/* to check Matching COUNT(*) and checksum between fragments vs Service_ALL	(evidence screenshot).*/

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




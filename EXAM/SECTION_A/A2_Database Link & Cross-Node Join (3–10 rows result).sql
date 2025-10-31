/* A2: Database Link & Cross-Node Join (3–10 rows result)
---------------------------------------------------------
WHAT TO DO
1. From Node_A, create database link 'proj_link' to Node_B.
2. Run remote SELECT on Claim@proj_link showing up to 5 sample rows.
3. Run a distributed join: local Service_A (or base Service) joined with remote Hospital@proj_link
returning between 3 and 10 rows total; include selective predicates to stay within the row budget.

EXPECTED OUTPUT
	✓ CREATE DATABASE LINK proj_link with connection details.
	✓ Screenshot of SELECT * FROM Claim@proj_link FETCH FIRST 5 ROWS ONLY.
	✓ Screenshot of distributed join on Service ⋈ Hospital@proj_link returning 3–10 rows.*/

/*steps to answer to this question*/
	/*i have alread two brachs or node (commercial_insurance_db & public_insurance_db). 
	instead of using the current nodes , let me create new one for this question*/

--1. on Node_A, creating database link 'proj_link' to Node_B
--2. create 'Claim' table (already created)
--3. run remote 5 rows selection of Claim table
--4. create 'Hospital' table (already created)
--5. Run a distributed join between local 'service_ table' and remote 'Hospital' table.

--1. Database link
--------------------

-- Enable dblink extension in your database
CREATE EXTENSION IF NOT EXISTS dblink;

-- Verify the extension is installed
SELECT extname, extversion FROM pg_extension WHERE extname = 'dblink';

--A) Simple dblink Connection and Query (it is a Basic dblink syntax for one-time connection).

SELECT * FROM dblink(
    'dbname=public_insurance_db host=localhost port=5432 user=postgres password=12345',
    'SELECT company_id, company_name, company_type FROM insurancecompany'
) AS t(company_id integer, company_name varchar(100), company_type varchar(20));

-- For our insurance setup, let's create proper dblink connections

--B) Persistent Database Links

-- In commercial_insurance_db
\c commercial_insurance_db

-- -- Drop existing if needed
-- DROP SERVER IF EXISTS proj_link CASCADE;

-- Create foreign server
CREATE SERVER proj_link
FOREIGN DATA WRAPPER postgres_fdw
OPTIONS (host 'localhost', dbname 'public_insurance_db', port '5432');

-- Create user mapping
CREATE USER MAPPING FOR CURRENT_USER
SERVER proj_link
OPTIONS (user 'postgres', password '12345');

-- Verify server creation
SELECT srvname, srvoptions FROM pg_foreign_server WHERE srvname = 'proj_link';

--C) Using dblink with Connection Names
-- Create a named connection (optional - dblink_connect)
SELECT dblink_connect('proj_link_conn', 
    'dbname=public_insurance_db host=localhost port=5432 user=postgres password=your_password'
);

-- Use the named connection
SELECT * FROM dblink(
    'proj_link_conn',
    'SELECT company_id, company_name, total_assets FROM insurancecompany LIMIT 3'
) AS t(company_id integer, company_name varchar(100), total_assets decimal(15,2));

-- Close connection when done
SELECT dblink_disconnect('proj_link_conn');


--===================================================
--Create Foreign Tables and Run Queries
-- In Commercial Database: Create foreign tables
\c commercial_insurance_db

CREATE FOREIGN TABLE Hospital_proj_link (
    hospital_id INTEGER,
    hospital_name VARCHAR(100),
    location VARCHAR(100),
    bed_count INTEGER,
    service_type VARCHAR(50)
) SERVER proj_link OPTIONS (schema_name 'public', table_name 'hospital');

CREATE FOREIGN TABLE Claim_proj_link (
    claim_id INTEGER,
    service_id INTEGER,
    hospital_id INTEGER,
    claim_amount DECIMAL(10,2),
    claim_date DATE,
    status VARCHAR(20)
) SERVER proj_link OPTIONS (schema_name 'public', table_name 'claim');

-- A2.2: Remote SELECT on Claim@proj_link (5 sample rows)
SELECT 'REMOTE CLAIM DATA (First 5 rows)' as query_type;
SELECT * FROM Claim_proj_link ORDER BY claim_id LIMIT 5;

-- A2.3: Distributed join (Service_A ⋈ Hospital@proj_link)
SELECT 'DISTRIBUTED JOIN RESULTS' as query_type;
SELECT 
    s.service_id,
    s.service_name,
    s.service_type,
    h.hospital_name,
    h.location,
    h.bed_count
FROM Service_A s
JOIN Hospital_proj_link h ON s.service_type = h.service_type
WHERE s.cost > 2000  -- Selective predicate to limit rows
ORDER BY s.service_id;



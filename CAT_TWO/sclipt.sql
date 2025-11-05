/* Course: Advanced Database Management Systems
 	Topic: Parallel and Distributed Databases
		Practical Lab Assessment 
============================================== */

/* The existing Health Insuarence database is which currently has a central "InsuranceCompany" table- 
and multiple dependent tables like: Plans, PolicyHolder, Hospital, Service, Claim, Assessor and Payment.

If i classify insurance companies as Public or Private, i can horizontally partition all dependent tables's data by that category — 
meaning: 1) Node A (Public node): as the database that keeps all data related to public or government insurance companies.
         2) Node B (Private node) as the database that keeps all data related to private or commercial insurance companies.

I found This as a realistic distributed plan that demonstrates true horizontal fragmentation based on a semantic attribute-
that has real-world meaning especially as it is here in Rwanda. */

-- Task NO.1: Distributed Schema Design and Fragmentation
--========================================================

-- STEPS:

-- 1. update InsuranceCompany table by Adding the Category column

ALTER TABLE InsuranceCompany
  ADD Category VARCHAR(10)
  CHECK (Category IN ('Public', 'Private'));

-- 2. populate data in Category to Categolize each Insurance Company.

UPDATE InsuranceCompany
SET Category = CASE CompanyID
  WHEN 'RAMA' THEN 'Public'
  WHEN 'RIC'  THEN 'Private'
  WHEN 'BRTM' THEN 'Private'
  WHEN 'ECMH' THEN 'Private'
  WHEN 'OMR'  THEN 'Private'
  WHEN 'MTL'  THEN 'Public'
  WHEN 'MMI'  THEN 'Public'
END;

SELECT * FROM InsuranceCompany;



/*Steps for distribution:*/
-----------------------------

--step 1: Enable extensions in main database and Create separate databases

--Enable extensions
CREATE EXTENSION IF NOT EXISTS dblink; -- DB link for DB inter connection and access
CREATE EXTENSION IF NOT EXISTS postgres_fdw; -- Enable FDW (foreign data wrapper) extension to distribute the data across databases.

-- Create separate databases
CREATE DATABASE public_insurance;
CREATE DATABASE private_insurance;


--step 2: Set Up Public Insurance Database Structure
--Connect to public_insurance database and create tables:
 
-- Create all tables with same structure
CREATE TABLE InsuranceCompany (
    CompanyID     VARCHAR(10) PRIMARY KEY,
    Name          TEXT NOT NULL,
    Address       TEXT,
    Contact       TEXT,
    Email         TEXT,
    LicenseNumber TEXT UNIQUE NOT NULL,
    Category      VARCHAR(10) CHECK (Category = 'Public')
);

CREATE TABLE Plan (
    PlanType      TEXT PRIMARY KEY,
    PlanLimit     NUMERIC(12,2) NOT NULL CHECK (PlanLimit >= 0)
);

CREATE TABLE PolicyHolder (
    HolderID    VARCHAR(9) PRIMARY KEY,
    FullName    TEXT NOT NULL,
    Contact     TEXT NOT NULL,
    NationalID  TEXT NOT NULL UNIQUE,
    PlanType    TEXT NOT NULL REFERENCES Plan(PlanType),
    CompanyID   VARCHAR(10) NOT NULL REFERENCES InsuranceCompany(CompanyID) ON DELETE SET NULL,
    JoinDate    DATE NOT NULL DEFAULT CURRENT_DATE
);

CREATE TABLE Hospital (
    HospitalID  SERIAL PRIMARY KEY,
    Name        TEXT NOT NULL,
    Address     TEXT,
    Contact     TEXT,
    Type        TEXT
);

CREATE TABLE Assessor (
    AssessorID  SERIAL PRIMARY KEY,
    FullName    TEXT NOT NULL,
    CompanyID   VARCHAR(10) NOT NULL REFERENCES InsuranceCompany(CompanyID) ON DELETE SET NULL,
    Department  TEXT,
    Contact     TEXT,
    Region      TEXT
);

CREATE TABLE Claim (
    ClaimID         SERIAL PRIMARY KEY,
    HolderID        VARCHAR(9) NOT NULL REFERENCES PolicyHolder(HolderID) ON DELETE RESTRICT,
    HospitalID      INTEGER NOT NULL REFERENCES Hospital(HospitalID) ON DELETE RESTRICT,
    DateFiled       DATE NOT NULL DEFAULT CURRENT_DATE,
    AmountClaimed   NUMERIC(12,2) NOT NULL CHECK (AmountClaimed >= 0),
    Status          TEXT NOT NULL CHECK (Status IN ('Pending','Approved','Rejected')) DEFAULT 'Pending'
);

CREATE TABLE Service (
    ServiceID   SERIAL PRIMARY KEY,
    ClaimID     INTEGER NOT NULL REFERENCES Claim(ClaimID) ON DELETE CASCADE,
    Description TEXT NOT NULL,
    Cost        NUMERIC(12,2) NOT NULL CHECK (Cost >= 0),
    ServiceDate DATE NOT NULL
);

CREATE TABLE Payment (
    PaymentID   SERIAL PRIMARY KEY,
    ClaimID     INTEGER NOT NULL UNIQUE REFERENCES Claim(ClaimID) ON DELETE RESTRICT,
    AssessorID  INTEGER REFERENCES Assessor(AssessorID) ON DELETE SET NULL,
    Amount      NUMERIC(12,2) CHECK (Amount >= 0),
    PaymentDate TIMESTAMP WITH TIME ZONE,
    Method      TEXT
);

--step 3: Set Up Private Insurance Database Structure
--Connect to private_insurance database and create tables:

-- Create all tables with same structure
CREATE TABLE InsuranceCompany (
    CompanyID     VARCHAR(10) PRIMARY KEY,
    Name          TEXT NOT NULL,
    Address       TEXT,
    Contact       TEXT,
    Email         TEXT,
    LicenseNumber TEXT UNIQUE NOT NULL,
    Category      VARCHAR(10) CHECK (Category = 'Private')
);

CREATE TABLE Plan (
    PlanType      TEXT PRIMARY KEY,
    PlanLimit     NUMERIC(12,2) NOT NULL CHECK (PlanLimit >= 0)
);

CREATE TABLE PolicyHolder (
    HolderID    VARCHAR(9) PRIMARY KEY,
    FullName    TEXT NOT NULL,
    Contact     TEXT NOT NULL,
    NationalID  TEXT NOT NULL UNIQUE,
    PlanType    TEXT NOT NULL REFERENCES Plan(PlanType),
    CompanyID   VARCHAR(10) NOT NULL REFERENCES InsuranceCompany(CompanyID) ON DELETE SET NULL,
    JoinDate    DATE NOT NULL DEFAULT CURRENT_DATE
);

CREATE TABLE Hospital (
    HospitalID  SERIAL PRIMARY KEY,
    Name        TEXT NOT NULL,
    Address     TEXT,
    Contact     TEXT,
    Type        TEXT
);

CREATE TABLE Assessor (
    AssessorID  SERIAL PRIMARY KEY,
    FullName    TEXT NOT NULL,
    CompanyID   VARCHAR(10) NOT NULL REFERENCES InsuranceCompany(CompanyID) ON DELETE SET NULL,
    Department  TEXT,
    Contact     TEXT,
    Region      TEXT
);

CREATE TABLE Claim (
    ClaimID         SERIAL PRIMARY KEY,
    HolderID        VARCHAR(9) NOT NULL REFERENCES PolicyHolder(HolderID) ON DELETE RESTRICT,
    HospitalID      INTEGER NOT NULL REFERENCES Hospital(HospitalID) ON DELETE RESTRICT,
    DateFiled       DATE NOT NULL DEFAULT CURRENT_DATE,
    AmountClaimed   NUMERIC(12,2) NOT NULL CHECK (AmountClaimed >= 0),
    Status          TEXT NOT NULL CHECK (Status IN ('Pending','Approved','Rejected')) DEFAULT 'Pending'
);

CREATE TABLE Service (
    ServiceID   SERIAL PRIMARY KEY,
    ClaimID     INTEGER NOT NULL REFERENCES Claim(ClaimID) ON DELETE CASCADE,
    Description TEXT NOT NULL,
    Cost        NUMERIC(12,2) NOT NULL CHECK (Cost >= 0),
    ServiceDate DATE NOT NULL
);

CREATE TABLE Payment (
    PaymentID   SERIAL PRIMARY KEY,
    ClaimID     INTEGER NOT NULL UNIQUE REFERENCES Claim(ClaimID) ON DELETE RESTRICT,
    AssessorID  INTEGER REFERENCES Assessor(AssessorID) ON DELETE SET NULL,
    Amount      NUMERIC(12,2) CHECK (Amount >= 0),
    PaymentDate TIMESTAMP WITH TIME ZONE,
    Method      TEXT
);


--step 4: --Set Up Foreign Servers and Data Distribution
---Connect back to healthInsurance main databse and set up the distribution:


-- Create foreign servers
CREATE SERVER public_insurance_server 
    FOREIGN DATA WRAPPER postgres_fdw 
    OPTIONS (host 'localhost', dbname 'public_insurance', port '5432');

CREATE SERVER private_insurance_server 
    FOREIGN DATA WRAPPER postgres_fdw 
    OPTIONS (host 'localhost', dbname 'private_insurance', port '5432');

-- Create user mappings
CREATE USER MAPPING FOR CURRENT_USER
    SERVER public_insurance_server 
    OPTIONS (user 'postgres', password '12345');

CREATE USER MAPPING FOR CURRENT_USER
    SERVER private_insurance_server 
    OPTIONS (user 'postgres', password '12345');

-- Create schemas for foreign tables
CREATE SCHEMA IF NOT EXISTS public_insurance;
CREATE SCHEMA IF NOT EXISTS private_insurance;

-- Import foreign schemas
IMPORT FOREIGN SCHEMA public 
    FROM SERVER public_insurance_server 
    INTO public_insurance;

IMPORT FOREIGN SCHEMA public 
    FROM SERVER private_insurance_server 
    INTO private_insurance;


--step 5: Function to distribute Plan data (common to both)
CREATE OR REPLACE FUNCTION distribute_plans()
RETURNS void AS $$
BEGIN
    -- Insert into public insurance database
    PERFORM dblink_connect('public_conn', 'public_insurance_server');
    PERFORM dblink_exec('public_conn', 
        'INSERT INTO plan (plantype, planlimit) VALUES ' ||
        '(''Basic'', 1000.00), ' ||
        '(''Standard'', 5000.00), ' ||
        '(''Premium'', 20000.00)');
    PERFORM dblink_disconnect('public_conn');
    
    -- Insert into private insurance database  
    PERFORM dblink_connect('private_conn', 'private_insurance_server');
    PERFORM dblink_exec('private_conn',
        'INSERT INTO plan (plantype, planlimit) VALUES ' ||
        '(''Basic'', 1000.00), ' ||
        '(''Standard'', 5000.00), ' ||
        '(''Premium'', 20000.00)');
    PERFORM dblink_disconnect('private_conn');
END;
$$ LANGUAGE plpgsql;

-- Function to distribute Insurance Companies
CREATE OR REPLACE FUNCTION distribute_insurance_companies()
RETURNS void AS $$
BEGIN
    -- Public companies
    PERFORM dblink_connect('public_conn', 'public_insurance_server');
    PERFORM dblink_exec('public_conn', 
        'INSERT INTO insurancecompany (companyid, name, address, contact, email, licensenumber, category) ' ||
        'SELECT companyid, name, address, contact, email, licensenumber, category ' ||
        'FROM insurancecompany WHERE category = ''Public''');
    PERFORM dblink_disconnect('public_conn');
    
    -- Private companies
    PERFORM dblink_connect('private_conn', 'private_insurance_server');
    PERFORM dblink_exec('private_conn',
        'INSERT INTO insurancecompany (companyid, name, address, contact, email, licensenumber, category) ' ||
        'SELECT companyid, name, address, contact, email, licensenumber, category ' ||
        'FROM insurancecompany WHERE category = ''Private''');
    PERFORM dblink_disconnect('private_conn');
END;
$$ LANGUAGE plpgsql;

-- Function to distribute Hospitals (common to both)
CREATE OR REPLACE FUNCTION distribute_hospitals()
RETURNS void AS $$
BEGIN
    PERFORM dblink_connect('public_conn', 'public_insurance_server');
    PERFORM dblink_exec('public_conn', 
        'INSERT INTO hospital (name, address, contact, type) VALUES ' ||
        '(''Rwanda Central Hospital'', ''Kigali - Nyarugenge'', ''0781000001'', ''Public''), ' ||
        '(''Green Valley Clinic'', ''Kigali - Gasabo'', ''0781000002'', ''Clinic''), ' ||
        '(''Mountain View Medical Centre'', ''Kigali - Kicukiro'', ''0781000003'', ''Private''), ' ||
        '(''RiverSide Hospital'', ''Kigali - Remera'', ''0781000004'', ''Private''), ' ||
        '(''St. Mary Community Hospital'', ''Kigali - Nyamirambo'', ''0781000005'', ''Public''), ' ||
        '(''La Polyfame Hospital'', ''Kigali - Nyamirambo'', ''0781000005'', ''Private''), ' ||
        '(''Muhima Hospital'', ''Kigali - Nyarugenge'', ''0791000005'', ''Public''), ' ||
        '(''Masaka Hospital'', ''Kigali - Masaka'', ''0781000040'', ''Public'')');
    PERFORM dblink_disconnect('public_conn');
    
    PERFORM dblink_connect('private_conn', 'private_insurance_server');
    PERFORM dblink_exec('private_conn',
        'INSERT INTO hospital (name, address, contact, type) VALUES ' ||
        '(''Rwanda Central Hospital'', ''Kigali - Nyarugenge'', ''0781000001'', ''Public''), ' ||
        '(''Green Valley Clinic'', ''Kigali - Gasabo'', ''0781000002'', ''Clinic''), ' ||
        '(''Mountain View Medical Centre'', ''Kigali - Kicukiro'', ''0781000003'', ''Private''), ' ||
        '(''RiverSide Hospital'', ''Kigali - Remera'', ''0781000004'', ''Private''), ' ||
        '(''St. Mary Community Hospital'', ''Kigali - Nyamirambo'', ''0781000005'', ''Public''), ' ||
        '(''La Polyfame Hospital'', ''Kigali - Nyamirambo'', ''0781000005'', ''Private''), ' ||
        '(''Muhima Hospital'', ''Kigali - Nyarugenge'', ''0791000005'', ''Public''), ' ||
        '(''Masaka Hospital'', ''Kigali - Masaka'', ''0781000040'', ''Public'')');
    PERFORM dblink_disconnect('private_conn');
END;
$$ LANGUAGE plpgsql;

-- Function to distribute Policy Holders
CREATE OR REPLACE FUNCTION distribute_policy_holders()
RETURNS void AS $$
BEGIN
    -- Public policy holders
    PERFORM dblink_connect('public_conn', 'public_insurance_server');
    PERFORM dblink_exec('public_conn', 
        'INSERT INTO policyholder (holderid, fullname, contact, nationalid, plantype, companyid, joindate) ' ||
        'SELECT holderid, fullname, contact, nationalid, plantype, companyid, joindate ' ||
        'FROM policyholder WHERE companyid IN (''RAMA'', ''MTL'', ''MMI'')');
    PERFORM dblink_disconnect('public_conn');
    
    -- Private policy holders
    PERFORM dblink_connect('private_conn', 'private_insurance_server');
    PERFORM dblink_exec('private_conn',
        'INSERT INTO policyholder (holderid, fullname, contact, nationalid, plantype, companyid, joindate) ' ||
        'SELECT holderid, fullname, contact, nationalid, plantype, companyid, joindate ' ||
        'FROM policyholder WHERE companyid IN (''BRTM'', ''OMR'', ''ECMH'', ''RIC'')');
    PERFORM dblink_disconnect('private_conn');
END;
$$ LANGUAGE plpgsql;

-- Function to distribute Assessors
CREATE OR REPLACE FUNCTION distribute_assessors()
RETURNS void AS $$
BEGIN
    -- Public assessors
    PERFORM dblink_connect('public_conn', 'public_insurance_server');
    PERFORM dblink_exec('public_conn', 
        'INSERT INTO assessor (fullname, companyid, department, contact, region) ' ||
        'SELECT fullname, companyid, department, contact, region ' ||
        'FROM assessor WHERE companyid IN (''RAMA'', ''MTL'', ''MMI'')');
    PERFORM dblink_disconnect('public_conn');
    
    -- Private assessors
    PERFORM dblink_connect('private_conn', 'private_insurance_server');
    PERFORM dblink_exec('private_conn',
        'INSERT INTO assessor (fullname, companyid, department, contact, region) ' ||
        'SELECT fullname, companyid, department, contact, region ' ||
        'FROM assessor WHERE companyid IN (''BRTM'', ''OMR'', ''ECMH'', ''RIC'')');
    PERFORM dblink_disconnect('private_conn');
END;
$$ LANGUAGE plpgsql;

-- Function to distribute Claims
CREATE OR REPLACE FUNCTION distribute_claims()
RETURNS void AS $$
BEGIN
    -- Public claims
    PERFORM dblink_connect('public_conn', 'public_insurance_server');
    PERFORM dblink_exec('public_conn', 
        'INSERT INTO claim (holderid, hospitalid, datefiled, amountclaimed, status) ' ||
        'SELECT c.holderid, c.hospitalid, c.datefiled, c.amountclaimed, c.status ' ||
        'FROM claim c ' ||
        'JOIN policyholder ph ON c.holderid = ph.holderid ' ||
        'WHERE ph.companyid IN (''RAMA'', ''MTL'', ''MMI'')');
    PERFORM dblink_disconnect('public_conn');
    
    -- Private claims
    PERFORM dblink_connect('private_conn', 'private_insurance_server');
    PERFORM dblink_exec('private_conn',
        'INSERT INTO claim (holderid, hospitalid, datefiled, amountclaimed, status) ' ||
        'SELECT c.holderid, c.hospitalid, c.datefiled, c.amountclaimed, c.status ' ||
        'FROM claim c ' ||
        'JOIN policyholder ph ON c.holderid = ph.holderid ' ||
        'WHERE ph.companyid IN (''BRTM'', ''OMR'', ''ECMH'', ''RIC'')');
    PERFORM dblink_disconnect('private_conn');
END;
$$ LANGUAGE plpgsql;

-- Function to distribute Services
CREATE OR REPLACE FUNCTION distribute_services()
RETURNS void AS $$
BEGIN
    -- Public services
    PERFORM dblink_connect('public_conn', 'public_insurance_server');
    PERFORM dblink_exec('public_conn', 
        'INSERT INTO service (claimid, description, cost, servicedate) ' ||
        'SELECT s.claimid, s.description, s.cost, s.servicedate ' ||
        'FROM service s ' ||
        'JOIN claim c ON s.claimid = c.claimid ' ||
        'JOIN policyholder ph ON c.holderid = ph.holderid ' ||
        'WHERE ph.companyid IN (''RAMA'', ''MTL'', ''MMI'')');
    PERFORM dblink_disconnect('public_conn');
    
    -- Private services
    PERFORM dblink_connect('private_conn', 'private_insurance_server');
    PERFORM dblink_exec('private_conn',
        'INSERT INTO service (claimid, description, cost, servicedate) ' ||
        'SELECT s.claimid, s.description, s.cost, s.servicedate ' ||
        'FROM service s ' ||
        'JOIN claim c ON s.claimid = c.claimid ' ||
        'JOIN policyholder ph ON c.holderid = ph.holderid ' ||
        'WHERE ph.companyid IN (''BRTM'', ''OMR'', ''ECMH'', ''RIC'')');
    PERFORM dblink_disconnect('private_conn');
END;
$$ LANGUAGE plpgsql;

-- Function to distribute Payments
CREATE OR REPLACE FUNCTION distribute_payments()
RETURNS void AS $$
BEGIN
    -- Public payments
    PERFORM dblink_connect('public_conn', 'public_insurance_server');
    PERFORM dblink_exec('public_conn', 
        'INSERT INTO payment (claimid, assessorid, amount, paymentdate, method) ' ||
        'SELECT p.claimid, p.assessorid, p.amount, p.paymentdate, p.method ' ||
        'FROM payment p ' ||
        'JOIN claim c ON p.claimid = c.claimid ' ||
        'JOIN policyholder ph ON c.holderid = ph.holderid ' ||
        'WHERE ph.companyid IN (''RAMA'', ''MTL'', ''MMI'')');
    PERFORM dblink_disconnect('public_conn');
    
    -- Private payments
    PERFORM dblink_connect('private_conn', 'private_insurance_server');
    PERFORM dblink_exec('private_conn',
        'INSERT INTO payment (claimid, assessorid, amount, paymentdate, method) ' ||
        'SELECT p.claimid, p.assessorid, p.amount, p.paymentdate, p.method ' ||
        'FROM payment p ' ||
        'JOIN claim c ON p.claimid = c.claimid ' ||
        'JOIN policyholder ph ON c.holderid = ph.holderid ' ||
        'WHERE ph.companyid IN (''BRTM'', ''OMR'', ''ECMH'', ''RIC'')');
    PERFORM dblink_disconnect('private_conn');
END;
$$ LANGUAGE plpgsql;




/* Task 2: Create and Use Database Links
=========================================*/

--1. Create Named Database Links (Connections)

-- Create named connection to public_insurance database
SELECT dblink_connect('public_insurance_conn', 
                      'dbname=public_insurance user=postgres host=localhost port=5432 password=12345');

-- Create named connection to private_insurance database
SELECT dblink_connect('private_insurance_conn', 
                      'dbname=private_insurance user=postgres host=localhost port=5432 password=12345');

--2. Remote SELECT Using Named Database Links

-- Select from public_insurance using named connection
SELECT * 
FROM dblink('public_insurance_conn', 
            'SELECT companyid, name, category FROM insurancecompany') 
AS public_companies(companyid varchar(10), name text, category text);

-- Select from private_insurance using named connection
SELECT * 
FROM dblink('private_insurance_conn', 
            'SELECT companyid, name, category FROM insurancecompany') 
AS private_companies(companyid varchar(10), name text, category text);

-- Remote SELECT with Filtering
-- Get policy holders from public_insurance with Premium plan
SELECT * 
FROM dblink('public_insurance_conn', 
            'SELECT holderid, fullname, plantype FROM policyholder WHERE plantype=''Premium''') 
AS premium_holders(holderid varchar(9), fullname text, plantype text);

SELECT * FROM policyholder

-- Get claims from private_insurance with status 'Approved'
SELECT * 
FROM dblink('private_insurance_conn', 
            'SELECT claimid, holderid, amountclaimed FROM claim WHERE status=''Approved''') 
AS approved_claims(claimid int, holderid varchar(9), amountclaimed numeric(12,2));


/* Task 3: Parallel Query Execution
=========================================*/

/*In  PostgreSQL setting hints to force parallel or serial query execution, 
installation and enabling pg_hint_plan because PostgreSQL ignores hint by default, */

CREATE EXTENSION pg_hint_plan; /* script to enable hint */

SELECT * FROM pg_available_extensions WHERE name = 'pg_hint_plan'; /* checking available hint extension */

SET max_parallel_workers_per_gather = 8; /* setting up to 8 parallel worker processes allowed to use when executing parallel queries */

-- Serial execution 

EXPLAIN ANALYZE SELECT COUNT(*) FROM PolicyHolder;

-- Parallel execution performance

EXPLAIN ANALYZE SELECT /*+ Parallel(PolicyHolder 4) */ COUNT(*) FROM PolicyHolder;
EXPLAIN ANALYZE SELECT COUNT(*) FROM PolicyHolder;

/* Task 4: Two-Phase Commit Simulation
=========================================*/
--Enable the dblink extension
CREATE EXTENSION IF NOT EXISTS dblink;

--Connect to both participant databases
-- Connect to the public insurance node
SELECT dblink_connect(
  'PrivateInsuarance_node',
  'dbname=PrivateHealthInsuranceCompany_DB host=localhost user=postgres password=12345'
);

-- Connect to the private insurance node
SELECT dblink_connect(
  'PublicInsuarance_node',
  'dbname=PublicHealthInsuranceCompany_DB host=localhost user=postgres password=12345'
);

--Enable the FDW extension
CREATE EXTENSION IF NOT EXISTS postgres_fdw;

--Create connections (servers)

-- For public insurance node
CREATE SERVER PublicInsuarance_node
FOREIGN DATA WRAPPER postgres_fdw
OPTIONS (dbname 'PublicHealthInsuranceCompany_DB', host 'localhost');

-- For private insurance node
CREATE SERVER PrivateInsuarance_node
FOREIGN DATA WRAPPER postgres_fdw
OPTIONS (dbname 'PrivateHealthInsuranceCompany_DB', host 'localhost');


--Create user mappings
CREATE USER MAPPING FOR postgres
SERVER PublicInsuarance_node
OPTIONS (user 'postgres', password '12345');

CREATE USER MAPPING FOR postgres
SERVER PrivateInsuarance_node
OPTIONS (user 'postgres', password '12345');

--Import or manually create foreign tables

-- Import from Public
IMPORT FOREIGN SCHEMA public
FROM SERVER PublicInsuarance_node
INTO public;

-- Import from Private
IMPORT FOREIGN SCHEMA public
FROM SERVER PrivateInsuarance_node
INTO public;

--selectively:

IMPORT FOREIGN SCHEMA public
LIMIT TO (PolicyHolder, InsuranceCompany, Plan)
FROM SERVER PublicInsuarance_node
INTO public;


--Execute the distributed transaction in two phases


-- BEGIN;
-- INSERT INTO PublicHealthInsuranceCompany_DB.PolicyHolder VALUES ('Z00000001','Zoe Uwase','0789001111','1200999999001','Basic','RAMA',CURRENT_DATE);
-- INSERT INTO PrivateHealthInsuranceCompany_DB.PolicyHolder VALUES ('Z00000002','Zane Iradukunda','0789002222','1200999999002','Premium','BRTM',CURRENT_DATE);
-- PREPARE TRANSACTION 'tx_lab';
-- -- COMMIT both
-- COMMIT PREPARED 'tx_lab';

-- Enable dblink on coordinator
CREATE EXTENSION IF NOT EXISTS dblink;

-- Step 1: Prepare on both nodes
SELECT dblink_exec('dbname=PublicHealthInsuranceCompany_DB host=localhost user=postgres password=12345',
$$
  BEGIN;
  INSERT INTO PolicyHolder(HolderID, FullName, Contact, NationalID, PlanType, CompanyID, JoinDate)
  VALUES ('Z00000001','Zoe Uwase','0789001111','1200999999001','Basic','RAMA',CURRENT_DATE);
  PREPARE TRANSACTION 'tx_public';
$$);

SELECT dblink_exec('dbname=PrivateHealthInsuranceCompany_DB host=localhost user=postgres password=12345',
$$
  BEGIN;
  INSERT INTO PolicyHolder(HolderID, FullName, Contact, NationalID, PlanType, CompanyID, JoinDate)
  VALUES ('Z00000002','Zane Iradukunda','0789002222','1200999999002','Premium','BRTM',CURRENT_DATE);
  PREPARE TRANSACTION 'tx_private';
$$);

-- Step 2: Commit both prepared transactions
SELECT dblink_exec('dbname=PublicHealthInsuranceCompany_DB host=localhost user=postgres password=12345',
$$ COMMIT PREPARED 'tx_public'; $$);

SELECT dblink_exec('dbname=PrivateHealthInsuranceCompany_DB host=localhost user=postgres password=12345',
$$ COMMIT PREPARED 'tx_private'; $$);


ROLLBACK;

-- On public DB
SELECT * FROM dblink('dbname=PublicHealthInsuranceCompany_DB host=localhost user=postgres password=12345',
'SELECT * FROM pg_prepared_xacts;')
AS t(gid text, owner text, dbname text, prepared timestamp);
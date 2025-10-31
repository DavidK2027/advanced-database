-------------------------------------------------------------
/* Step 1: Create Branch Databases and Enable Extensions*/
-------------------------------------------------------------
-- Connect to Node_B_db database and enable extensions  
CREATE EXTENSION postgres_fdw;
CREATE EXTENSION dblink;

/* Step 2: Create Fragmented Tables in nodes Databases*/

-- In Node_B_db Database: Create Service_B fragment  

CREATE TABLE Service_B (
    service_id INTEGER PRIMARY KEY,
	claim_id INTEGER,
	service_type VARCHAR(50),
    service_name VARCHAR(100),
    cost DECIMAL(10,2),
    created_date DATE,
    status VARCHAR(20)
);

/* Step 3: Buby Using HASH distribution, Insert a TOTAL of ≤10*/

INSERT INTO Service_B VALUES 
(1, 5, 'Consultation', 'Vision Test', 5500.00, '2024-01-23', 'Completed'),
(3, 6, 'Consultation and Medication', 'Blood Pressure Monitoring', 15000.00, '2025-01-25', 'In Process'),
(5, 7, 'Consultation and Medication', 'Chemotherapy Session', 5000, '2023-04-15', 'Active'),
(7, 8, 'Consultation and Medication', 'Mental Health Counseling', 35000.00, '2021-03-15', 'In Process'),
(9, 5, 'Medical Certificate', 'COVID-19 Test (PCR)', 1000.00, '2019-10-05', 'Completed');

/* A2: Database Link & Cross-Node Join (3–10 rows result)
	Create Additional Tables for Joins*/

-- Create Hospital table in Node_B database 

CREATE TABLE InsuranceCompany (
    company_id SERIAL PRIMARY KEY,
    company_name VARCHAR(100) NOT NULL,
    company_type VARCHAR(20) NOT NULL CHECK (company_type IN ('Private', 'Public')),
    address TEXT,
    phone VARCHAR(20),
    email VARCHAR(100),
    founded_date DATE,
    total_assets DECIMAL(15,2),
    region VARCHAR(50),
    employee_count INTEGER,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- ALTER TABLE InsuranceCompany DROP CONSTRAINT insurancecompany_company_type_check;

-- ALTER TABLE InsuranceCompany
-- ADD CONSTRAINT insurancecompany_company_type_check
-- CHECK (company_type IN ('Private', 'Public'));

INSERT INTO InsuranceCompany (
    company_name, company_type, address, phone, email, founded_date,
    total_assets, region, employee_count
) VALUES
-- Private / Commercial Insurance Companies
('SecureLife Insurance Ltd.', 'Private', '123 Main St, Kigali', '+250788111222', 'info@securelife.com', '2005-04-12', 12500000.00, 'Kigali City', 150),
('BlueShield Assurance', 'Private', '45 Avenue de la Paix, Huye', '+250788333444', 'contact@blueshield.com', '2010-06-23', 8900000.00, 'Southern Province', 90),
('PrimeCare Insurance Co.', 'Private', '78 Remera Rd, Kigali', '+250788555666', 'support@primecare.com', '2012-02-10', 15700000.00, 'Kigali City', 200),
('Rwanda General Insurance', 'Private', '4 Independence Ave, Rubavu', '+250788777888', 'info@rwgi.com', '2008-11-05', 13400000.00, 'Western Province', 120),
('TrustPlus Insurance PLC', 'Private', '16 Nyagatare Rd, Nyagatare', '+250788999000', 'admin@trustplus.com', '2016-08-17', 9700000.00, 'Eastern Province', 70),

-- Public / Non-Commercial Insurance Companies
('Rwanda Public Health Insurance Agency', 'Public', '1 Government Blvd, Kigali', '+250788101010', 'info@rphia.gov.rw', '1998-03-25', 35000000.00, 'Kigali City', 600),
('National Cooperative Insurance Board', 'Public', '25 Gisenyi Ave, Rubavu', '+250788202020', 'contact@ncib.gov.rw', '2003-07-14', 27000000.00, 'Western Province', 350),
('Social Protection Insurance Agency', 'Public', '12 Kayonza Rd, Kayonza', '+250788303030', 'support@spia.gov.rw', '2001-12-09', 19000000.00, 'Eastern Province', 250),
('Rwanda Teachers Mutual Insurance', 'Public', '8 Nyarugenge Blvd, Kigali', '+250788404040', 'rtmi@edu.gov.rw', '2005-01-19', 21000000.00, 'Kigali City', 400),
('National Health Fund of Rwanda', 'Public', '99 Butare St, Huye', '+250788505050', 'nhfr@rwanda.gov.rw', '1995-05-05', 46000000.00, 'Southern Province', 800);

SELECT * FROM InsuranceCompany; 

CREATE TABLE Hospital (
    hospital_id  SERIAL PRIMARY KEY,
    Name        TEXT NOT NULL,
    Address     TEXT,
    Contact     TEXT,
	Type      TEXT NOT NULL CHECK (Type IN ('Public','Private','Clinic'))
);

SELECT * FROM Hospital; 

SELECT * FROM InsuranceCompany; 

INSERT INTO Hospital (hospital_id, Name, Address, Contact, Type) VALUES
(1, 'Rwanda Central Hospital', 'Kigali - Nyarugenge', '0781000001', 'Public'),
(2, 'Green Valley Clinic', 'Kigali - Gasabo', '0781000002', 'Clinic'),
(3, 'La Polyfame Hospital', 'Kigali - Kicukiro', '0781000005', 'Private'),
(4, 'Masaka Hospital', 'Kigali - Masaka', '0781000040', 'Public'),
(5, 'Muhima Hospital', 'Kigali - Nyarugenge', '0791000005', 'Public');

SELECT * FROM Hospital; 

CREATE TABLE plan (
    plan_type      TEXT PRIMARY KEY,
    planLimit     NUMERIC(12,2) NOT NULL CHECK (PlanLimit >= 0)
);

SELECT * FROM plan;


CREATE TABLE policyHolder (
    holder_id    VARCHAR(9) PRIMARY KEY,
    full_name    TEXT NOT NULL,
    contact     TEXT NOT NULL,
    national_id  TEXT NOT NULL UNIQUE,
    plan_type    TEXT NOT NULL REFERENCES plan(plan_type),
	company_id   SERIAL NOT NULL REFERENCES InsuranceCompany(company_id) ON DELETE SET NULL,
    join_date    DATE NOT NULL DEFAULT CURRENT_DATE
);

ALTER TABLE PolicyHolder DROP CONSTRAINT policyholder_pkey;

ALTER TABLE PolicyHolder DROP COLUMN holder_id;

ALTER TABLE PolicyHolder ADD COLUMN holder_id SERIAL PRIMARY KEY;



INSERT INTO PolicyHolder(holder_id, full_name, contact, national_id, plan_type, company_id, join_date) VALUES
  ('A00000001', 'Alice Uwase','0781210001','1198680184134041','Basic', 3, '2024-01-15'),
  ('B00000002', 'Bob Nkurunziza','0781210002','1198880184134061','Standard', 3, '2023-06-10'),
  ('C00000003', 'Charlie Mukamana','0781210003','1197680184134141','Premium', 5, '2022-09-01'),
  ('D00000004', 'Diane Habimana','0781210004','1198980184134041','Standard', 4, '2025-02-20'),
  ('E00000005', 'Elias Uwitonze','0781210005','1200380184131041','Basic', 10, '2024-11-01'),
  ('F00000006', 'Faith Kagabo','0781210006','1201380184131061','Premium', 7, '2023-03-03'),
  ('G00000007', 'George Manzi','0781210007','1200380184131071','Standard', 8, '2021-12-12'),
  ('H00000008', 'Hannah Mukaruriza','0781210008','1200380184181041','Basic',8, '2022-05-05'),
  ('I00000009', 'Ivan Byiringiro','0781210009','1200380194131041','Premium', 6, '2020-08-08'),
  ('J00000010', 'Joyce Karekezi','0781210010','1200380183131041','Standard', 6, '2024-07-07');


-- Create Claim table in Node_B 

CREATE TABLE claim (
    claim_id         SERIAL PRIMARY KEY,
    holder_id        VARCHAR(9) NOT NULL REFERENCES PolicyHolder(holder_id) ON DELETE RESTRICT,
    hospital_id      INTEGER NOT NULL REFERENCES Hospital(hospital_id) ON DELETE RESTRICT,    
    amountClaimed   NUMERIC(12,2) NOT NULL CHECK (AmountClaimed >= 0),
	dateFiled       DATE NOT NULL DEFAULT CURRENT_DATE,
    status          TEXT NOT NULL CHECK (Status IN ('Pending','Approved','Rejected')) DEFAULT 'Pending'
);


INSERT INTO claim VALUES
(1, 'A00000001', 1, 5000.00, '2024-01-20', 'Approved'),
(2, 'B00000002', 2, 2500.00, '2024-01-25', 'Pending'),
(3, 'C00000003', 3, 1800.00, '2024-02-01', 'Approved'),
(4, 'D00000004', 4, 3200.00, '2024-02-10', 'Pending'),
(5, 'E00000005', 5, 1500.00, '2024-02-15', 'Rejected');

SELECT * FROM claim; 

--A4 QUESTION

SELECT extname, extversion FROM pg_extension WHERE extname = 'dblink';

--\df dblink_exec

-- Create similar table in Public database via dblink
SELECT dblink_exec(
    'dbname=Node_A_db host=localhost port=5432 user=postgres password=12345',
    'CREATE TABLE IF NOT EXISTS transaction_log (
        log_id SERIAL PRIMARY KEY,
        node_name VARCHAR(50),
        service_id INTEGER,
        action_type VARCHAR(20),
        transaction_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    )'
);

SELECT dblink_exec(
    'host=localhost port=5432 dbname=Node_B_db user=postgres password=12345',
    'CREATE TABLE IF NOT EXISTS transaction_log (
        log_id SERIAL PRIMARY KEY,
        node_name VARCHAR(50),
        service_id INTEGER,
        action_type VARCHAR(20),
        transaction_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    )'
);

-- Correct syntax for dblink_exec
SELECT dblink_exec(
    'dbname=Node_B_db host=localhost port=5432 user=postgres password=12345',
    'CREATE TABLE IF NOT EXISTS transaction_log (
        log_id SERIAL PRIMARY KEY,
        node_name VARCHAR(50),
        service_id INTEGER,
        action_type VARCHAR(20),
        transaction_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    )'
) AS result;

-- Method 1: Using connection string directly
SELECT dblink_exec(
    'host=localhost port=5432 dbname=Node_B_db user=postgres password=12345',
    'CREATE TABLE IF NOT EXISTS transaction_log (
        log_id SERIAL PRIMARY KEY,
        node_name VARCHAR(50),
        service_id INTEGER,
        action_type VARCHAR(20),
        transaction_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    )'
);

--Option B: Create Named Connection First

-- Method 2: Create named connection first
SELECT dblink_connect('remote_conn', 
    'host=localhost port=5432 dbname=Node_B_db user=postgres password=12345'
);

-- Then execute using the connection name
SELECT dblink_exec('remote_conn',
    'CREATE TABLE IF NOT EXISTS transaction_log (
        log_id SERIAL PRIMARY KEY,
        node_name VARCHAR(50),
        service_id INTEGER,
        action_type VARCHAR(20),
        transaction_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    )'
);

-- Close the connection
SELECT dblink_disconnect('remote_conn');







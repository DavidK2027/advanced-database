
--START=========================================================================================

--create database

CREATE DATABASE healthInsurance

--1. Create all tables with data validation and referential integrity rules
=======================================================================================
-- creating insuarance company table to store information about insuarance companies

CREATE TABLE InsuranceCompany (
    CompanyID     VARCHAR(10) PRIMARY KEY,
    Name          TEXT NOT NULL,
    Address       TEXT,
    Contact       TEXT,
    Email         TEXT,
    LicenseNumber TEXT UNIQUE NOT NULL
);

-- insert data in insuarance company table

INSERT INTO InsuranceCompany (CompanyID, Name, Address, Contact, Email, LicenseNumber)
VALUES
('RAMA', 'Rwanda Medical Insurance Scheme', 'Kigali - Nyarugenge', '0788001111', 'info@mutuellecare.rw', 'RAMA001'),
('BRTM', 'BRITAM', 'Kigali - Gasabo', '0788002222', 'support@blitam.rw', 'BRTM002'),
('OMR', 'Old Mutual Rwanda', 'Kigali - Nyarugenge', '0788002672', 'support@Oldmutual.rw', 'OMR003'),
('ECMH', 'Eden Care Medical Health Insurance company', 'Kigali - Rwamagana', '0788002689', 'support@edencare.rw', 'ECMH004'),
('RIC', 'Radiant Insurance Company', 'Kigali - Karongi', '0798002000', 'support@radiant.rw', 'RIC005'),
('MTL', 'Mutuel', 'Kigali - Nyarugenge', '079800209', 'Mutuel@radiant.rw', 'MTL006'),
('MMI', 'Multary Mutual Insuarence', 'Kigali - Kimironko', '078800209', 'mmi@radiant.rw', 'MMI007');


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


-- fetch data from insuarance company table

SELECT * FROM InsuranceCompany;


-- creating Plans table for the trigger to check limits reliably.

CREATE TABLE Plan (
    PlanType      TEXT PRIMARY KEY,
    PlanLimit     NUMERIC(12,2) NOT NULL CHECK (PlanLimit >= 0)
);

-- insert data in insuarance company table

INSERT INTO Plan(PlanType, PlanLimit) VALUES
  ('Basic',    1000.00),
  ('Standard', 5000.00),
  ('Premium', 20000.00);

-- fetch data from insuarance company table

SELECT * FROM Plan;


-- creating PolicyHolder table to store information about PolicyHolder(Clients).

CREATE TABLE PolicyHolder (
    HolderID    VARCHAR(9) PRIMARY KEY,
    FullName    TEXT NOT NULL,
    Contact     TEXT NOT NULL,
    NationalID  TEXT NOT NULL UNIQUE,
    PlanType    TEXT NOT NULL REFERENCES Plan(PlanType),
	  CompanyID   VARCHAR(10) NOT NULL REFERENCES InsuranceCompany(CompanyID) ON DELETE SET NULL,
    JoinDate    DATE NOT NULL DEFAULT CURRENT_DATE
);

-- insert data in PolicyHolder table

INSERT INTO PolicyHolder(HolderID, FullName, Contact, NationalID, PlanType, CompanyID, JoinDate) VALUES
  ('A00000001', 'Alice Uwase','0781210001','1198680184134041','Basic', 'RAMA', '2024-01-15'),
  ('B00000002', 'Bob Nkurunziza','0781210002','1198880184134061','Standard', 'RAMA', '2023-06-10'),
  ('C00000003', 'Charlie Mukamana','0781210003','1197680184134141','Premium', 'BRTM', '2022-09-01'),
  ('D00000004', 'Diane Habimana','0781210004','1198980184134041','Standard', 'RAMA', '2025-02-20'),
  ('E00000005', 'Elias Uwitonze','0781210005','1200380184131041','Basic', 'OMR', '2024-11-01'),
  ('F00000006', 'Faith Kagabo','0781210006','1201380184131061','Premium', 'ECMH', '2023-03-03'),
  ('G00000007', 'George Manzi','0781210007','1200380184131071','Standard', 'RAMA', '2021-12-12'),
  ('H00000008', 'Hannah Mukaruriza','0781210008','1200380184181041','Basic', 'ECMH', '2022-05-05'),
  ('I00000009', 'Ivan Byiringiro','0781210009','1200380194131041','Premium', 'RIC', '2020-08-08'),
  ('J00000010', 'Joyce Karekezi','0781210010','1200380183131041','Standard', 'RIC', '2024-07-07');

-- fetch data from insuarance company table

SELECT * FROM PolicyHolder;


-- creating Hospital table to store information about Hospital.

CREATE TABLE Hospital (
    HospitalID  SERIAL PRIMARY KEY,
    Name        TEXT NOT NULL,
    Address     TEXT,
    Contact     TEXT,
    Type        TEXT -- e.g. "Public", "Private", "Clinic"
);


-- insert data in Hospital table

INSERT INTO Hospital(Name, Address, Contact, Type) VALUES
  ('Rwanda Central Hospital', 'Kigali - Nyarugenge', '0781000001', 'Public'),
  ('Green Valley Clinic', 'Kigali - Gasabo', '0781000002', 'Clinic'),
  ('Mountain View Medical Centre', 'Kigali - Kicukiro', '0781000003', 'Private'),
  ('RiverSide Hospital', 'Kigali - Remera', '0781000004', 'Private'),
  ('St. Mary Community Hospital', 'Kigali - Nyamirambo', '0781000005', 'Public'),
  ('La Polyfame Hospital', 'Kigali - Nyamirambo', '0781000005', 'Private'),
  ('Muhima Hospital', 'Kigali - Nyarugenge', '0791000005', 'Public'),
  ('Masaka Hospital', 'Kigali - Masaka', '0781000040', 'Public');


-- fetch data from insuarance company table

SELECT * FROM Hospital;

-- creating Assessor table to store information about Assessors.

CREATE TABLE Assessor (
    AssessorID  SERIAL PRIMARY KEY,
    FullName    TEXT NOT NULL,
    CompanyID   VARCHAR(10) NOT NULL REFERENCES InsuranceCompany(CompanyID) ON DELETE SET NULL,
	Department  TEXT,
    Contact     TEXT,
    Region      TEXT
);


-- insert data in Assessor table

INSERT INTO Assessor(FullName, CompanyID, Department, Contact, Region) VALUES
  ('Samuel Auditor', 'RAMA', 'Claims Dept','0781300001','Kigali'),
  ('Rachel Inspector', 'BRTM', 'Medical Review','0781300002','North'),
  ('Thomas Checker', 'RAMA', 'Finance','0781300003','Kigali'),
  ('David Kali', 'BRTM', 'Claims Dept','0781300001','Kigali'),
  ('Mugabo Jean', 'OMR', 'Medical Review','0781300002','North'),
  ('Rwaka Yves', 'ECMH', 'Finance','0781300003','Kigali'),
  ('Rukundo Obed', 'RIC', 'Finance','0781300003','Kigali');



-- creating Claim table to store information about Claim.

CREATE TABLE Claim (
    ClaimID         SERIAL PRIMARY KEY,
    HolderID        VARCHAR(9) NOT NULL REFERENCES PolicyHolder(HolderID) ON DELETE RESTRICT,
    HospitalID      INTEGER NOT NULL REFERENCES Hospital(HospitalID) ON DELETE RESTRICT,
    DateFiled       DATE NOT NULL DEFAULT CURRENT_DATE,
    AmountClaimed   NUMERIC(12,2) NOT NULL CHECK (AmountClaimed >= 0),
    Status          TEXT NOT NULL CHECK (Status IN ('Pending','Approved','Rejected')) DEFAULT 'Pending'
);



-- insert data in Claim table

INSERT INTO Claim(HolderID, HospitalID, DateFiled, AmountClaimed, Status) VALUES
  ('A00000001', 1, '2025-01-12', 300000.00, 'Pending'),
  ('B00000002', 2, '2025-02-10', 120000.00, 'Approved'),  
  ('C00000003', 3, '2025-03-05', 1500.00, 'Approved'),
  ('D00000004', 1, '2025-04-20', 450.00, 'Pending'),
  ('E00000005', 4, '2025-05-15', 900.00, 'Rejected'),
  ('F00000006', 2, '2025-06-01', 2000.00, 'Approved'),
  ('G00000007', 3, '2025-06-18', 300.00, 'Pending'),
  ('H00000008', 5, '2025-07-21', 800.00, 'Approved'),
  ('I00000009', 1, '2025-08-11', 4000.00, 'Pending'),
  ('A00000001', 4, '2025-09-02', 250.00, 'Approved');
  

-- creating Service table to store information about Service.

CREATE TABLE Service (
    ServiceID   SERIAL PRIMARY KEY,
    ClaimID     INTEGER NOT NULL REFERENCES Claim(ClaimID) ON DELETE CASCADE,
    Description TEXT NOT NULL,
    Cost        NUMERIC(12,2) NOT NULL CHECK (Cost >= 0),
    ServiceDate DATE NOT NULL
);


-- insert data in Service table

INSERT INTO Service(ClaimID, Description, Cost, ServiceDate) VALUES
  (1, 'Consultation', 100.00, '2025-01-10'),
  (1, 'X-Ray', 200.00, '2025-01-10'),
  (2, 'Blood Tests', 300.00, '2025-02-09'),
  (2, 'Medication', 900.00, '2025-02-09'),
  (3, 'Surgery', 1500.00, '2025-03-04'),
  (4, 'Physiotherapy', 150.00, '2025-04-19'),
  (5, 'Consultation', 100.00, '2025-05-14'),
  (6, 'Inpatient stay', 2000.00, '2025-05-31'),
  (8, 'Maternity', 800.00, '2025-07-20'),
  (10, 'Outpatient', 250.00, '2025-09-01');



-- creating Payment table to store information about Payment.

CREATE TABLE Payment (
    PaymentID   SERIAL PRIMARY KEY,
    ClaimID     INTEGER NOT NULL UNIQUE REFERENCES Claim(ClaimID) ON DELETE RESTRICT,
    AssessorID  INTEGER REFERENCES Assessor(AssessorID) ON DELETE SET NULL,
    Amount      NUMERIC(12,2) CHECK (Amount >= 0),
    PaymentDate TIMESTAMP WITH TIME ZONE,
    Method      TEXT -- e.g. 'Bank Transfer', 'Cash', 'Mobile Money'
);

-- insert data in Payment table

INSERT INTO Payment(ClaimID, AssessorID, Amount, PaymentDate, Method) VALUES
  (2, 1, 1200.00, '2025-02-12 10:00:00+03', 'Bank Transfer'),
  (3, 1, 1500.00, '2025-03-07 09:30:00+03', 'Bank Transfer'),
  (6, 2, NULL, NULL, NULL),  -- pending payment; to be updated after approval
  (8, 3, 800.00, '2025-07-25 14:00:00+03', 'Cash'),
  (10, 2, 250.00, '2025-09-05 11:00:00+03', 'Mobile Money');


-- let make Indexes to help queries

CREATE INDEX idx_claim_holder ON Claim(HolderID);
CREATE INDEX idx_claim_hospital ON Claim(HospitalID);
CREATE INDEX idx_payment_assessor ON Payment(AssessorID);


-- 2--. Cascade Delete Between Claim → Service
-- ==============================================

CREATE TABLE Service (
    ServiceID   SERIAL PRIMARY KEY,
    ClaimID     INTEGER NOT NULL REFERENCES Claim(ClaimID) ON DELETE CASCADE,
    Description TEXT NOT NULL,
    Cost        NUMERIC(12,2) NOT NULL CHECK (Cost >= 0),
    ServiceDate DATE NOT NULL
);

--This means each Service record is linked to exactly one Claim.
--(Every service belongs to a claim.)
--“If a Claim is deleted, automatically delete all Service records that reference it.”

--Exmple: 
DELETE FROM Claim WHERE ClaimID = 1; -- these will dellete two  records in services table referenced by ClaimID = 1)

--3--. Insert 5 hospitals, 10 policyholders, and 10 claims.
-- =========================================================

--Insert records into hospitals Table

INSERT INTO Hospital(Name, Address, Contact, Type) VALUES
  ('Rwanda Central Hospital', 'Kigali - Nyarugenge', '0781000001', 'Public'),
  ('Green Valley Clinic', 'Kigali - Gasabo', '0781000002', 'Clinic'),
  ('Mountain View Medical Centre', 'Kigali - Kicukiro', '0781000003', 'Private'),
  ('RiverSide Hospital', 'Kigali - Remera', '0781000004', 'Private'),
  ('St. Mary Community Hospital', 'Kigali - Nyamirambo', '0781000005', 'Public'),
  ('La Polyfame Hospital', 'Kigali - Nyamirambo', '0781000005', 'Private'),
  ('Muhima Hospital', 'Kigali - Nyarugenge', '0791000005', 'Public'),
  ('Masaka Hospital', 'Kigali - Masaka', '0781000040', 'Public');

  --Insert records into policyholders Table
  
  INSERT INTO PolicyHolder(HolderID, FullName, Contact, NationalID, PlanType, CompanyID, JoinDate) VALUES
  ('A00000001', 'Alice Uwase','0781210001','1198680184134041','Basic', 'RAMA', '2024-01-15'),
  ('B00000002', 'Bob Nkurunziza','0781210002','1198880184134061','Standard', 'RAMA', '2023-06-10'),
  ('C00000003', 'Charlie Mukamana','0781210003','1197680184134141','Premium', 'BRTM', '2022-09-01'),
  ('D00000004', 'Diane Habimana','0781210004','1198980184134041','Standard', 'RAMA', '2025-02-20'),
  ('E00000005', 'Elias Uwitonze','0781210005','1200380184131041','Basic', 'OMR', '2024-11-01'),
  ('F00000006', 'Faith Kagabo','0781210006','1201380184131061','Premium', 'ECMH', '2023-03-03'),
  ('G00000007', 'George Manzi','0781210007','1200380184131071','Standard', 'RAMA', '2021-12-12'),
  ('H00000008', 'Hannah Mukaruriza','0781210008','1200380184181041','Basic', 'ECMH', '2022-05-05'),
  ('I00000009', 'Ivan Byiringiro','0781210009','1200380194131041','Premium', 'RIC', '2020-08-08'),
  ('J00000010', 'Joyce Karekezi','0781210010','1200380183131041','Standard', 'RIC', '2024-);
  

-- 4--. Retrieve total approved claim amounts per hospital.
-- ========================================================

-- This query sums AmountClaimed for Claims with Status='Approved', grouped by hospital


SELECT h.HospitalID, h.Name,
       COUNT(c.ClaimID) AS approved_claim_count,
       SUM(c.AmountClaimed) AS total_approved_amount
FROM Hospital h
LEFT JOIN Claim c ON c.HospitalID = h.HospitalID AND c.Status = 'Approved'
GROUP BY h.HospitalID, h.Name
ORDER BY total_approved_amount DESC NULLS LAST;


-- 5. Update payment records after approval
-- ============================================

-- Eg: for approved claims that have a payment row with NULL amount, set payment to claim amount and mark payment date + method.
-- Update existing payment rows associated to claims that are 'Approved' and currently have NULL Amount.

UPDATE Payment p
SET Amount = c.AmountClaimed,
    PaymentDate = now(),
    Method = COALESCE(p.Method, 'Bank Transfer')
FROM Claim c
WHERE p.ClaimID = c.ClaimID
  AND c.Status = 'Approved'
  AND p.Amount IS NULL;

-- If there are approved claims without any payment row at all, create payment rows (example: create payments for all approved claims missing payments)
INSERT INTO Payment (ClaimID, AssessorID, Amount, PaymentDate, Method)
SELECT c.ClaimID, -- choose a default assessor or NULL
       1 AS AssessorID,
       c.AmountClaimed,
       now(),
       'Bank Transfer'
FROM Claim c
LEFT JOIN Payment p ON p.ClaimID = c.ClaimID
WHERE c.Status = 'Approved'
  AND p.ClaimID IS NULL;



-- 6. Identify hospitals with the highest claim frequency
-- =======================================================

-- Show counts, sorted descending; to include ties we can use RANK()
-- =================================================================

SELECT h.HospitalID, h.Name,
       COUNT(c.ClaimID) AS claim_count
FROM Hospital h
LEFT JOIN Claim c ON c.HospitalID = h.HospitalID
GROUP BY h.HospitalID, h.Name
ORDER BY claim_count DESC;

-- To show the top hospital(s) including ties:
WITH counts AS (
  SELECT h.HospitalID, h.Name, COUNT(c.ClaimID) AS claim_count
  FROM Hospital h
  LEFT JOIN Claim c ON c.HospitalID = h.HospitalID
  GROUP BY h.HospitalID, h.Name
)

SELECT * FROM counts
WHERE claim_count = (SELECT MAX(claim_count) FROM counts);



-- 7. Create a view summarizing claim settlements by assessor
-- ============================================================

-- The view shows assessor name, number of payments they processed, total paid, average paid, last payment date.

CREATE OR REPLACE VIEW vw_assessor_claim_settlements AS
SELECT a.AssessorID,
       a.FullName AS AssessorName,
       COUNT(p.PaymentID) AS payments_processed,
       COALESCE(SUM(p.Amount), 0) AS total_paid,
       COALESCE(AVG(p.Amount), 0) AS avg_payment,
       MAX(p.PaymentDate) AS last_payment_date
FROM Assessor a
LEFT JOIN Payment p ON p.AssessorID = a.AssessorID
GROUP BY a.AssessorID, a.FullName;

-- Example usage:
SELECT * FROM vw_assessor_claim_settlements ORDER BY total_paid DESC;


--8--. Implement a trigger that rejects claim insertion if amount exceeds plan limit.
-- =====================================================================================

CREATE OR REPLACE FUNCTION fn_check_claim_within_plan_limit()
RETURNS TRIGGER AS $$
DECLARE
    allowed NUMERIC;
BEGIN
    -- Get plan limit for the policyholder
    SELECT p.PlanLimit INTO allowed
      FROM PolicyHolder ph
      JOIN Plan p ON ph.PlanType = p.PlanType
      WHERE ph.HolderID = NEW.HolderID;

    IF allowed IS NULL THEN
        RAISE EXCEPTION 'Policy holder % has no plan or plan not found', NEW.HolderID;
    END IF;

    IF NEW.AmountClaimed > allowed THEN
        RAISE EXCEPTION 'Claim rejected: amount (%.2f) exceeds plan limit (%.2f) for holder %', NEW.AmountClaimed, allowed, NEW.HolderID;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_claim_within_limit
BEFORE INSERT ON Claim
FOR EACH ROW EXECUTE FUNCTION fn_check_claim_within_plan_limit();

====================================================================== END

 








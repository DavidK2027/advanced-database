====================================== START =================================================================================


TOPIC: DIGITAL HEALTH INSURANCE AND CLAIMS
===========================================

The Summary
------------

This topic is about analysis and design Health Insurance database to manage policyholders, hospitals, claims, medical services, 
assessors, and payments. It automates claim validation and ensures accurate and timely reimbursements for insured clients.
 
The database has flowing tables:

	1. InsuranceCompany (CompanyID, Name, Category, Address, Contact, Email, LicenseNumber)
	2. Plan (PlanType, PlanLimit)
	3. PolicyHolder(HolderID, FullName, Contact, NationalID, PlanType, JoinDate)
	4. Hospital (HospitalID, Name, Address, Contact, Type)
	5. Assessor (AssessorID, FullName, Department, Contact, Region)
	6. Claim (ClaimID, HolderID, HospitalID, DateFiled, AmountClaimed, Status)
	7. Service (ServiceID, ClaimID, Description, Cost, ServiceDate)
	8. Payment (PaymentID, ClaimID, AssessorID, Amount, PaymentDate, Method)


Here is the Tasks to Perform during this assessment 


	1. Create all tables with data validation and referential integrity rules.
	2. Apply CASCADE DELETE between Claim → Service.
	3. Insert 5 hospitals, 10 policyholders, and 10 claims.
	4. Retrieve total approved claim amounts per hospital.
	5. Update payment records after approval.
	6. Identify hospitals with the highest claim frequency.
	7. Create a view summarizing claim settlements by assessor.
	8. Implement a trigger that rejects claim insertion if amount exceeds plan

====================================== END =================================================================================

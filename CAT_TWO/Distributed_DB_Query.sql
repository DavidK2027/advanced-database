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



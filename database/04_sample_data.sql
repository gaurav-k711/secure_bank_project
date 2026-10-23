-- ============================================================================
-- SecureBank DBMS Project - 04_sample_data.sql
-- Description: Inserts at least 10 consistent, realistic sample records into
-- all 8 tables. Run after tables, constraints, and sequences are created.
-- ============================================================================

-- Disable triggers during seed insertion to prevent double counting or recursive side effects
ALTER TRIGGER trg_cust_id_pk ENABLE;
ALTER TRIGGER trg_acc_id_pk ENABLE;
ALTER TRIGGER trg_txn_id_pk ENABLE;
ALTER TRIGGER trg_ben_id_pk ENABLE;
ALTER TRIGGER trg_loan_id_pk ENABLE;
ALTER TRIGGER trg_pay_id_pk ENABLE;
ALTER TRIGGER trg_alert_id_pk ENABLE;
ALTER TRIGGER trg_audit_id_pk ENABLE;

-- ----------------------------------------------------------------------------
-- 1. CUSTOMER (10 Records)
-- ----------------------------------------------------------------------------
INSERT INTO customer (name, phone, email, address, city, date_of_birth) 
VALUES ('Arun Kumar', '9876500001', 'arun.kumar@mail.com', '12 North Mada St', 'Chennai', TO_DATE('1988-04-12', 'YYYY-MM-DD'));

INSERT INTO customer (name, phone, email, address, city, date_of_birth) 
VALUES ('Priya Sharma', '9876500002', 'priya.s@mail.com', '45 Gandhi Road', 'Vellore', TO_DATE('1992-08-25', 'YYYY-MM-DD'));

INSERT INTO customer (name, phone, email, address, city, date_of_birth) 
VALUES ('Rahul Mehta', '9876500003', 'rahul.m@mail.com', '78 Marine Drive', 'Mumbai', TO_DATE('1985-11-19', 'YYYY-MM-DD'));

INSERT INTO customer (name, phone, email, address, city, date_of_birth) 
VALUES ('Sneha Reddy', '9876500004', 'sneha.r@mail.com', '101 Jubilee Hills', 'Hyderabad', TO_DATE('1995-01-30', 'YYYY-MM-DD'));

INSERT INTO customer (name, phone, email, address, city, date_of_birth) 
VALUES ('Vikram Singh', '9876500005', 'vikram.s@mail.com', '23 Connaught Place', 'Delhi', TO_DATE('1980-06-15', 'YYYY-MM-DD'));

INSERT INTO customer (name, phone, email, address, city, date_of_birth) 
VALUES ('Anita Nair', '9876500006', 'anita.n@mail.com', '56 MG Road', 'Kochi', TO_DATE('1991-03-22', 'YYYY-MM-DD'));

INSERT INTO customer (name, phone, email, address, city, date_of_birth) 
VALUES ('Karthik Raj', '9876500007', 'karthik.r@mail.com', '89 Cross Cut Rd', 'Coimbatore', TO_DATE('1994-07-09', 'YYYY-MM-DD'));

INSERT INTO customer (name, phone, email, address, city, date_of_birth) 
VALUES ('Meena Iyer', '9876500008', 'meena.i@mail.com', '34 West Tower St', 'Madurai', TO_DATE('1987-12-03', 'YYYY-MM-DD'));

INSERT INTO customer (name, phone, email, address, city, date_of_birth) 
VALUES ('Tariq Ali', '9876500009', 'tariq.a@mail.com', '67 Park Street', 'Kolkata', TO_DATE('1993-09-17', 'YYYY-MM-DD'));

INSERT INTO customer (name, phone, email, address, city, date_of_birth) 
VALUES ('Sunita Patel', '9876500010', 'sunita.p@mail.com', '90 SG Highway', 'Ahmedabad', TO_DATE('1989-05-11', 'YYYY-MM-DD'));

-- ----------------------------------------------------------------------------
-- 2. ACCOUNT (10 Records - linked to Customer IDs 1 to 10)
-- ----------------------------------------------------------------------------
INSERT INTO account (customer_id, account_type, balance, status) 
VALUES (1, 'SAVINGS', 75000.00, 'ACTIVE');

INSERT INTO account (customer_id, account_type, balance, status) 
VALUES (2, 'SAVINGS', 120000.00, 'ACTIVE');

INSERT INTO account (customer_id, account_type, balance, status) 
VALUES (3, 'CURRENT', 250000.00, 'ACTIVE');

INSERT INTO account (customer_id, account_type, balance, status) 
VALUES (4, 'SAVINGS', 45000.00, 'ACTIVE');

INSERT INTO account (customer_id, account_type, balance, status) 
VALUES (5, 'CURRENT', 500000.00, 'ACTIVE');

INSERT INTO account (customer_id, account_type, balance, status) 
VALUES (6, 'SAVINGS', 35000.00, 'ACTIVE');

INSERT INTO account (customer_id, account_type, balance, status) 
VALUES (7, 'SAVINGS', 90000.00, 'ACTIVE');

INSERT INTO account (customer_id, account_type, balance, status) 
VALUES (8, 'CURRENT', 60000.00, 'ACTIVE');

INSERT INTO account (customer_id, account_type, balance, status) 
VALUES (9, 'SAVINGS', 180000.00, 'ACTIVE');

INSERT INTO account (customer_id, account_type, balance, status) 
VALUES (10, 'SAVINGS', 15000.00, 'BLOCKED');

-- ----------------------------------------------------------------------------
-- 3. BANK_TRANSACTION (20 Records: 10 Normal + 10 Suspicious)
-- ----------------------------------------------------------------------------
-- Normal historical transactions (IDs 1 to 10)
INSERT INTO bank_transaction (account_id, txn_type, amount, txn_date, status, description) 
VALUES (1, 'DEPOSIT', 10000.00, TO_DATE('2026-09-01', 'YYYY-MM-DD'), 'SUCCESS', 'Salary deposit');

INSERT INTO bank_transaction (account_id, txn_type, amount, txn_date, status, description) 
VALUES (1, 'WITHDRAW', 2000.00, TO_DATE('2026-09-02', 'YYYY-MM-DD'), 'SUCCESS', 'ATM cash withdrawal');

INSERT INTO bank_transaction (account_id, txn_type, amount, txn_date, status, description) 
VALUES (2, 'DEPOSIT', 50000.00, TO_DATE('2026-09-03', 'YYYY-MM-DD'), 'SUCCESS', 'Cheque clearing');

INSERT INTO bank_transaction (account_id, txn_type, amount, txn_date, status, description) 
VALUES (2, 'WITHDRAW', 5000.00, TO_DATE('2026-09-04', 'YYYY-MM-DD'), 'SUCCESS', 'Utility bill payment');

INSERT INTO bank_transaction (account_id, txn_type, amount, txn_date, status, description) 
VALUES (3, 'DEPOSIT', 100000.00, TO_DATE('2026-09-05', 'YYYY-MM-DD'), 'SUCCESS', 'Vendor payment received');

INSERT INTO bank_transaction (account_id, txn_type, amount, txn_date, status, description) 
VALUES (4, 'DEPOSIT', 20000.00, TO_DATE('2026-09-06', 'YYYY-MM-DD'), 'SUCCESS', 'Monthly deposit');

INSERT INTO bank_transaction (account_id, txn_type, amount, txn_date, status, description) 
VALUES (5, 'WITHDRAW', 15000.00, TO_DATE('2026-09-07', 'YYYY-MM-DD'), 'SUCCESS', 'Branch cash withdrawal');

INSERT INTO bank_transaction (account_id, txn_type, amount, txn_date, status, description) 
VALUES (6, 'DEPOSIT', 30000.00, TO_DATE('2026-09-08', 'YYYY-MM-DD'), 'SUCCESS', 'Cash deposit');

INSERT INTO bank_transaction (account_id, txn_type, amount, txn_date, status, description) 
VALUES (8, 'WITHDRAW', 4000.00, TO_DATE('2026-09-09', 'YYYY-MM-DD'), 'SUCCESS', 'Online purchase');

INSERT INTO bank_transaction (account_id, txn_type, amount, txn_date, status, description) 
VALUES (10, 'WITHDRAW', 2500.00, TO_DATE('2026-09-10', 'YYYY-MM-DD'), 'SUCCESS', 'POS payment');

-- Suspicious transactions breaking fraud rules (IDs 11 to 20)
INSERT INTO bank_transaction (account_id, txn_type, amount, txn_date, status, description) 
VALUES (3, 'TRANSFER', 150000.00, TO_DATE('2026-09-11', 'YYYY-MM-DD'), 'SUSPICIOUS', 'High value offshore transfer');

INSERT INTO bank_transaction (account_id, txn_type, amount, txn_date, status, description) 
VALUES (6, 'TRANSFER', 200000.00, TO_DATE('2026-09-12', 'YYYY-MM-DD'), 'SUSPICIOUS', 'Large sum outward wire');

INSERT INTO bank_transaction (account_id, txn_type, amount, txn_date, status, description) 
VALUES (9, 'WITHDRAW', 120000.00, TO_DATE('2026-09-13', 'YYYY-MM-DD'), 'SUSPICIOUS', 'Sudden high cash withdrawal');

INSERT INTO bank_transaction (account_id, txn_type, amount, txn_date, status, description) 
VALUES (3, 'WITHDRAW', 110000.00, TO_DATE('2026-09-14', 'YYYY-MM-DD'), 'SUSPICIOUS', 'Commercial cash out');

INSERT INTO bank_transaction (account_id, txn_type, amount, txn_date, status, description) 
VALUES (1, 'TRANSFER', 175000.00, TO_DATE('2026-09-15', 'YYYY-MM-DD'), 'SUSPICIOUS', 'Rapid funds movement');

INSERT INTO bank_transaction (account_id, txn_type, amount, txn_date, status, description) 
VALUES (3, 'TRANSFER', 300000.00, TO_DATE('2026-09-16', 'YYYY-MM-DD'), 'SUSPICIOUS', 'Very high third-party transfer');

INSERT INTO bank_transaction (account_id, txn_type, amount, txn_date, status, description) 
VALUES (8, 'WITHDRAW', 80000.00, TO_DATE('2026-09-17', 'YYYY-MM-DD'), 'SUSPICIOUS', 'Withdrawal >80% of account balance');

INSERT INTO bank_transaction (account_id, txn_type, amount, txn_date, status, description) 
VALUES (9, 'TRANSFER', 250000.00, TO_DATE('2026-09-18', 'YYYY-MM-DD'), 'SUSPICIOUS', 'Wire to unknown account');

INSERT INTO bank_transaction (account_id, txn_type, amount, txn_date, status, description) 
VALUES (4, 'WITHDRAW', 70000.00, TO_DATE('2026-09-19', 'YYYY-MM-DD'), 'SUSPICIOUS', 'Drain attempt >80% balance');

INSERT INTO bank_transaction (account_id, txn_type, amount, txn_date, status, description) 
VALUES (7, 'TRANSFER', 105000.00, TO_DATE('2026-09-20', 'YYYY-MM-DD'), 'SUSPICIOUS', 'Interbank bulk transfer');

-- ----------------------------------------------------------------------------
-- 4. BENEFICIARY (10 Records)
-- ----------------------------------------------------------------------------
INSERT INTO beneficiary (customer_id, ben_name, ben_account_no, bank_name, status) 
VALUES (1, 'Ravi Kumar', '5001000001', 'SecureBank', 'ACTIVE');

INSERT INTO beneficiary (customer_id, ben_name, ben_account_no, bank_name, status) 
VALUES (1, 'Lakshmi Kumar', '6002000002', 'State Bank of India', 'ACTIVE');

INSERT INTO beneficiary (customer_id, ben_name, ben_account_no, bank_name, status) 
VALUES (2, 'Suresh Sharma', '5001000003', 'SecureBank', 'ACTIVE');

INSERT INTO beneficiary (customer_id, ben_name, ben_account_no, bank_name, status) 
VALUES (3, 'Neha Mehta', '7003000004', 'HDFC Bank', 'ACTIVE');

INSERT INTO beneficiary (customer_id, ben_name, ben_account_no, bank_name, status) 
VALUES (4, 'Rohan Reddy', '5001000005', 'SecureBank', 'ACTIVE');

INSERT INTO beneficiary (customer_id, ben_name, ben_account_no, bank_name, status) 
VALUES (5, 'Pooja Singh', '8004000006', 'ICICI Bank', 'ACTIVE');

INSERT INTO beneficiary (customer_id, ben_name, ben_account_no, bank_name, status) 
VALUES (6, 'Gopal Nair', '5001000007', 'SecureBank', 'ACTIVE');

INSERT INTO beneficiary (customer_id, ben_name, ben_account_no, bank_name, status) 
VALUES (7, 'Latha Raj', '6002000008', 'State Bank of India', 'ACTIVE');

INSERT INTO beneficiary (customer_id, ben_name, ben_account_no, bank_name, status) 
VALUES (8, 'Ramesh Iyer', '7003000009', 'HDFC Bank', 'ACTIVE');

INSERT INTO beneficiary (customer_id, ben_name, ben_account_no, bank_name, status) 
VALUES (9, 'Sana Ali', '8004000010', 'ICICI Bank', 'ACTIVE');

-- ----------------------------------------------------------------------------
-- 5. LOAN (10 Records)
-- ----------------------------------------------------------------------------
INSERT INTO loan (customer_id, loan_amount, interest_rate, loan_term, status, application_date) 
VALUES (1, 500000.00, 8.50, 24, 'APPROVED', TO_DATE('2026-07-01', 'YYYY-MM-DD'));

INSERT INTO loan (customer_id, loan_amount, interest_rate, loan_term, status, application_date) 
VALUES (2, 200000.00, 9.00, 12, 'APPROVED', TO_DATE('2026-07-15', 'YYYY-MM-DD'));

INSERT INTO loan (customer_id, loan_amount, interest_rate, loan_term, status, application_date) 
VALUES (3, 1000000.00, 8.00, 36, 'PENDING', TO_DATE('2026-08-01', 'YYYY-MM-DD'));

INSERT INTO loan (customer_id, loan_amount, interest_rate, loan_term, status, application_date) 
VALUES (4, 300000.00, 9.50, 18, 'APPROVED', TO_DATE('2026-08-10', 'YYYY-MM-DD'));

INSERT INTO loan (customer_id, loan_amount, interest_rate, loan_term, status, application_date) 
VALUES (5, 150000.00, 10.00, 12, 'REJECTED', TO_DATE('2026-08-15', 'YYYY-MM-DD'));

INSERT INTO loan (customer_id, loan_amount, interest_rate, loan_term, status, application_date) 
VALUES (6, 750000.00, 8.50, 36, 'APPROVED', TO_DATE('2026-08-20', 'YYYY-MM-DD'));

INSERT INTO loan (customer_id, loan_amount, interest_rate, loan_term, status, application_date) 
VALUES (7, 100000.00, 9.00, 6, 'CLOSED', TO_DATE('2026-06-01', 'YYYY-MM-DD'));

INSERT INTO loan (customer_id, loan_amount, interest_rate, loan_term, status, application_date) 
VALUES (8, 400000.00, 8.75, 24, 'APPROVED', TO_DATE('2026-08-25', 'YYYY-MM-DD'));

INSERT INTO loan (customer_id, loan_amount, interest_rate, loan_term, status, application_date) 
VALUES (9, 600000.00, 8.50, 24, 'PENDING', TO_DATE('2026-09-01', 'YYYY-MM-DD'));

INSERT INTO loan (customer_id, loan_amount, interest_rate, loan_term, status, application_date) 
VALUES (10, 250000.00, 9.25, 12, 'APPROVED', TO_DATE('2026-09-05', 'YYYY-MM-DD'));

-- ----------------------------------------------------------------------------
-- 6. LOAN_PAYMENT (10 Records)
-- ----------------------------------------------------------------------------
INSERT INTO loan_payment (loan_id, amount_paid, payment_date, payment_status) 
VALUES (1, 25000.00, TO_DATE('2026-08-05', 'YYYY-MM-DD'), 'COMPLETED');

INSERT INTO loan_payment (loan_id, amount_paid, payment_date, payment_status) 
VALUES (1, 25000.00, TO_DATE('2026-09-05', 'YYYY-MM-DD'), 'COMPLETED');

INSERT INTO loan_payment (loan_id, amount_paid, payment_date, payment_status) 
VALUES (2, 10000.00, TO_DATE('2026-08-10', 'YYYY-MM-DD'), 'COMPLETED');

INSERT INTO loan_payment (loan_id, amount_paid, payment_date, payment_status) 
VALUES (4, 15000.00, TO_DATE('2026-08-12', 'YYYY-MM-DD'), 'COMPLETED');

INSERT INTO loan_payment (loan_id, amount_paid, payment_date, payment_status) 
VALUES (6, 30000.00, TO_DATE('2026-08-15', 'YYYY-MM-DD'), 'COMPLETED');

INSERT INTO loan_payment (loan_id, amount_paid, payment_date, payment_status) 
VALUES (6, 30000.00, TO_DATE('2026-09-15', 'YYYY-MM-DD'), 'COMPLETED');

INSERT INTO loan_payment (loan_id, amount_paid, payment_date, payment_status) 
VALUES (7, 100000.00, TO_DATE('2026-09-01', 'YYYY-MM-DD'), 'COMPLETED');

INSERT INTO loan_payment (loan_id, amount_paid, payment_date, payment_status) 
VALUES (8, 20000.00, TO_DATE('2026-08-20', 'YYYY-MM-DD'), 'COMPLETED');

INSERT INTO loan_payment (loan_id, amount_paid, payment_date, payment_status) 
VALUES (8, 20000.00, TO_DATE('2026-09-20', 'YYYY-MM-DD'), 'COMPLETED');

INSERT INTO loan_payment (loan_id, amount_paid, payment_date, payment_status) 
VALUES (10, 12000.00, TO_DATE('2026-09-25', 'YYYY-MM-DD'), 'COMPLETED');

-- ----------------------------------------------------------------------------
-- 7. FRAUD_ALERT (10 Records - linked to suspicious txn IDs 11 to 20)
-- ----------------------------------------------------------------------------
INSERT INTO fraud_alert (txn_id, reason, risk_level, review_status, alert_date, reviewed_at) 
VALUES (11, 'Transaction broke rule R1: Amount exceeds Rs. 1,00,000 threshold', 'HIGH', 'PENDING', TO_DATE('2026-09-11', 'YYYY-MM-DD'), NULL);

INSERT INTO fraud_alert (txn_id, reason, risk_level, review_status, alert_date, reviewed_at) 
VALUES (12, 'Transaction broke rule R1: Amount exceeds Rs. 1,00,000 threshold', 'HIGH', 'REVIEWED', TO_DATE('2026-09-12', 'YYYY-MM-DD'), TO_DATE('2026-09-13', 'YYYY-MM-DD'));

INSERT INTO fraud_alert (txn_id, reason, risk_level, review_status, alert_date, reviewed_at) 
VALUES (13, 'Transaction broke rule R1: Amount exceeds Rs. 1,00,000 threshold', 'HIGH', 'CONFIRMED', TO_DATE('2026-09-13', 'YYYY-MM-DD'), TO_DATE('2026-09-14', 'YYYY-MM-DD'));

INSERT INTO fraud_alert (txn_id, reason, risk_level, review_status, alert_date, reviewed_at) 
VALUES (14, 'Transaction broke rule R1: Amount exceeds Rs. 1,00,000 threshold', 'HIGH', 'PENDING', TO_DATE('2026-09-14', 'YYYY-MM-DD'), NULL);

INSERT INTO fraud_alert (txn_id, reason, risk_level, review_status, alert_date, reviewed_at) 
VALUES (15, 'Transaction broke rule R1: Amount exceeds Rs. 1,00,000 threshold', 'HIGH', 'FALSE_ALARM', TO_DATE('2026-09-15', 'YYYY-MM-DD'), TO_DATE('2026-09-15', 'YYYY-MM-DD'));

INSERT INTO fraud_alert (txn_id, reason, risk_level, review_status, alert_date, reviewed_at) 
VALUES (16, 'Transaction broke rule R1: Amount exceeds Rs. 1,00,000 threshold', 'HIGH', 'PENDING', TO_DATE('2026-09-16', 'YYYY-MM-DD'), NULL);

INSERT INTO fraud_alert (txn_id, reason, risk_level, review_status, alert_date, reviewed_at) 
VALUES (17, 'Transaction broke rule R2: Amount exceeds 80% of account balance', 'HIGH', 'PENDING', TO_DATE('2026-09-17', 'YYYY-MM-DD'), NULL);

INSERT INTO fraud_alert (txn_id, reason, risk_level, review_status, alert_date, reviewed_at) 
VALUES (18, 'Transaction broke rule R1: Amount exceeds Rs. 1,00,000 threshold', 'HIGH', 'CONFIRMED', TO_DATE('2026-09-18', 'YYYY-MM-DD'), TO_DATE('2026-09-19', 'YYYY-MM-DD'));

INSERT INTO fraud_alert (txn_id, reason, risk_level, review_status, alert_date, reviewed_at) 
VALUES (19, 'Transaction broke rule R2: Amount exceeds 80% of account balance', 'HIGH', 'PENDING', TO_DATE('2026-09-19', 'YYYY-MM-DD'), NULL);

INSERT INTO fraud_alert (txn_id, reason, risk_level, review_status, alert_date, reviewed_at) 
VALUES (20, 'Transaction broke rule R1: Amount exceeds Rs. 1,00,000 threshold', 'HIGH', 'REVIEWED', TO_DATE('2026-09-20', 'YYYY-MM-DD'), TO_DATE('2026-09-21', 'YYYY-MM-DD'));

-- ----------------------------------------------------------------------------
-- 8. AUDIT_LOG (10 Records)
-- ----------------------------------------------------------------------------
INSERT INTO audit_log (account_id, table_name, action_type, action_time, details) 
VALUES (1, 'ACCOUNT', 'UPDATE', TO_DATE('2026-09-01 10:15:00', 'YYYY-MM-DD HH24:MI:SS'), 'Balance credited: Rs. 10000.00 via salary deposit');

INSERT INTO audit_log (account_id, table_name, action_type, action_time, details) 
VALUES (1, 'ACCOUNT', 'UPDATE', TO_DATE('2026-09-02 14:30:00', 'YYYY-MM-DD HH24:MI:SS'), 'Balance debited: Rs. 2000.00 via ATM cash withdrawal');

INSERT INTO audit_log (account_id, table_name, action_type, action_time, details) 
VALUES (2, 'ACCOUNT', 'UPDATE', TO_DATE('2026-09-03 11:20:00', 'YYYY-MM-DD HH24:MI:SS'), 'Balance credited: Rs. 50000.00 via cheque clearing');

INSERT INTO audit_log (account_id, table_name, action_type, action_time, details) 
VALUES (3, 'ACCOUNT', 'UPDATE', TO_DATE('2026-09-05 16:45:00', 'YYYY-MM-DD HH24:MI:SS'), 'Balance credited: Rs. 100000.00 via vendor payment');

INSERT INTO audit_log (account_id, table_name, action_type, action_time, details) 
VALUES (3, 'FRAUD_ALERT', 'REVIEW', TO_DATE('2026-09-13 09:10:00', 'YYYY-MM-DD HH24:MI:SS'), 'Admin confirmed fraud alert #13 for account #3');

INSERT INTO audit_log (account_id, table_name, action_type, action_time, details) 
VALUES (4, 'ACCOUNT', 'UPDATE', TO_DATE('2026-09-06 12:00:00', 'YYYY-MM-DD HH24:MI:SS'), 'Balance credited: Rs. 20000.00 via monthly deposit');

INSERT INTO audit_log (account_id, table_name, action_type, action_time, details) 
VALUES (5, 'ACCOUNT', 'UPDATE', TO_DATE('2026-09-07 15:10:00', 'YYYY-MM-DD HH24:MI:SS'), 'Balance debited: Rs. 15000.00 via branch cash withdrawal');

INSERT INTO audit_log (account_id, table_name, action_type, action_time, details) 
VALUES (6, 'ACCOUNT', 'UPDATE', TO_DATE('2026-09-08 10:05:00', 'YYYY-MM-DD HH24:MI:SS'), 'Balance credited: Rs. 30000.00 via cash deposit');

INSERT INTO audit_log (account_id, table_name, action_type, action_time, details) 
VALUES (9, 'FRAUD_ALERT', 'REVIEW', TO_DATE('2026-09-19 14:00:00', 'YYYY-MM-DD HH24:MI:SS'), 'Admin confirmed fraud alert #18 for account #9');

INSERT INTO audit_log (account_id, table_name, action_type, action_time, details) 
VALUES (10, 'ACCOUNT', 'UPDATE', TO_DATE('2026-09-10 18:25:00', 'YYYY-MM-DD HH24:MI:SS'), 'Account status updated to BLOCKED after risk evaluation');

COMMIT;

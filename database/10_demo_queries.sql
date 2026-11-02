-- ============================================================================
-- SecureBank DBMS Project - 10_demo_queries.sql
-- Description: 17 Meaningful SQL Queries demonstrating joins, aggregations,
-- subqueries, date manipulation, set logic, and business reporting.
-- Compatible with Oracle Database 11g, 12c, 19c, 21c, 23c.
-- ============================================================================

SET LINESIZE 200;
SET PAGESIZE 100;

-- ----------------------------------------------------------------------------
-- Q1: Basic Retrieval with Projection and WHERE Clause
-- Description: Retrieve active savings accounts with balance over Rs. 50,000.
-- Concept: Single-table SELECT, Boolean AND, Comparison Operators.
-- ----------------------------------------------------------------------------
SELECT account_id, customer_id, account_type, balance, status, created_at
FROM account
WHERE account_type = 'SAVINGS'
  AND status = 'ACTIVE'
  AND balance >= 50000
ORDER BY balance DESC;

-- ----------------------------------------------------------------------------
-- Q2: String Matching and Sorting (LIKE + ORDER BY)
-- Description: Find customers whose city starts with 'C' or 'M', sorted alphabetically.
-- Concept: Pattern matching with LIKE, OR condition, ORDER BY ascending.
-- ----------------------------------------------------------------------------
SELECT customer_id, name, phone, email, city
FROM customer
WHERE city LIKE 'C%' OR city LIKE 'M%'
ORDER BY name ASC;

-- ----------------------------------------------------------------------------
-- Q3: Aggregation with GROUP BY
-- Description: Calculate total transaction volume and count grouped by transaction type.
-- Concept: GROUP BY, COUNT(*), SUM(amount), ROUND(AVG(amount), 2).
-- ----------------------------------------------------------------------------
SELECT txn_type,
       COUNT(*) AS txn_count,
       SUM(amount) AS total_volume,
       ROUND(AVG(amount), 2) AS average_amount,
       MIN(amount) AS lowest_amount,
       MAX(amount) AS highest_amount
FROM bank_transaction
GROUP BY txn_type
ORDER BY total_volume DESC;

-- ----------------------------------------------------------------------------
-- Q4: Two-Table Inner Join
-- Description: List each bank account along with customer's full name and city.
-- Concept: INNER JOIN between ACCOUNT and CUSTOMER on primary-foreign key relationship.
-- ----------------------------------------------------------------------------
SELECT a.account_id,
       c.name AS customer_name,
       c.city,
       a.account_type,
       a.balance,
       a.status
FROM account a
JOIN customer c ON a.customer_id = c.customer_id
ORDER BY a.account_id ASC;

-- ----------------------------------------------------------------------------
-- Q5: Three-Table Join with Filtering
-- Description: Retrieve all transactions flagged as SUSPICIOUS with account and customer details.
-- Concept: Multi-table JOIN (BANK_TRANSACTION -> ACCOUNT -> CUSTOMER) with WHERE filter.
-- ----------------------------------------------------------------------------
SELECT t.txn_id,
       c.name AS account_holder,
       t.account_id,
       t.txn_type,
       t.amount,
       t.status,
       t.description,
       TO_CHAR(t.txn_date, 'YYYY-MM-DD HH24:MI') AS transaction_time
FROM bank_transaction t
JOIN account a ON t.account_id = a.account_id
JOIN customer c ON a.customer_id = c.customer_id
WHERE t.status = 'SUSPICIOUS'
ORDER BY t.amount DESC;

-- ----------------------------------------------------------------------------
-- Q6: Scalar Subquery in WHERE Clause
-- Description: Find all accounts whose balance is strictly above the bank-wide average balance.
-- Concept: Nested subquery returning a scalar aggregate to outer query filter.
-- ----------------------------------------------------------------------------
SELECT a.account_id,
       c.name AS customer_name,
       a.account_type,
       a.balance
FROM account a
JOIN customer c ON a.customer_id = c.customer_id
WHERE a.balance > (SELECT AVG(balance) FROM account)
ORDER BY a.balance DESC;

-- ----------------------------------------------------------------------------
-- Q7: Subquery with NOT IN
-- Description: Find customers who currently do NOT have any approved loan.
-- Concept: Subquery negation with NOT IN.
-- ----------------------------------------------------------------------------
SELECT customer_id, name, phone, city
FROM customer
WHERE customer_id NOT IN (
    SELECT DISTINCT customer_id 
    FROM loan 
    WHERE status = 'APPROVED'
)
ORDER BY customer_id ASC;

-- ----------------------------------------------------------------------------
-- Q8: Correlated Subquery with EXISTS
-- Description: Identify accounts that have experienced at least one suspicious transaction.
-- Concept: Correlated subquery using EXISTS with outer-table reference.
-- ----------------------------------------------------------------------------
SELECT a.account_id,
       c.name AS customer_name,
       a.account_type,
       a.balance
FROM account a
JOIN customer c ON a.customer_id = c.customer_id
WHERE EXISTS (
    SELECT 1 
    FROM bank_transaction t 
    WHERE t.account_id = a.account_id 
      AND t.status = 'SUSPICIOUS'
)
ORDER BY a.account_id ASC;

-- ----------------------------------------------------------------------------
-- Q9: GROUP BY with HAVING Clause
-- Description: Identify customers who have accumulated 2 or more fraud alerts.
-- Concept: 4-table JOIN with GROUP BY and post-aggregation filter using HAVING.
-- ----------------------------------------------------------------------------
SELECT c.customer_id,
       c.name AS customer_name,
       c.phone,
       COUNT(f.alert_id) AS fraud_alert_count
FROM fraud_alert f
JOIN bank_transaction t ON f.txn_id = t.txn_id
JOIN account a ON t.account_id = a.account_id
JOIN customer c ON a.customer_id = c.customer_id
GROUP BY c.customer_id, c.name, c.phone
HAVING COUNT(f.alert_id) >= 2
ORDER BY fraud_alert_count DESC;

-- ----------------------------------------------------------------------------
-- Q10: LEFT OUTER JOIN with NVL
-- Description: Display outstanding loan balance and repayment summary for each loan.
-- Concept: LEFT JOIN to include loans with zero repayments, NVL handling NULL sums.
-- ----------------------------------------------------------------------------
SELECT l.loan_id,
       c.name AS borrower_name,
       l.loan_amount AS principal,
       NVL(SUM(p.amount_paid), 0) AS total_repaid,
       (l.loan_amount - NVL(SUM(p.amount_paid), 0)) AS outstanding_principal,
       l.status AS loan_status
FROM loan l
JOIN customer c ON l.customer_id = c.customer_id
LEFT JOIN loan_payment p ON l.loan_id = p.loan_id
GROUP BY l.loan_id, c.name, l.loan_amount, l.status
ORDER BY outstanding_principal DESC;

-- ----------------------------------------------------------------------------
-- Q11: Top-N Query (ROWNUM / FETCH FIRST)
-- Description: Retrieve the top 5 highest value transactions processed by the bank.
-- Concept: Subquery with ORDER BY + ROWNUM <= 5 for Oracle 11g/12c compatibility.
-- ----------------------------------------------------------------------------
SELECT *
FROM (
    SELECT txn_id, account_id, txn_type, amount, status, txn_date
    FROM bank_transaction
    ORDER BY amount DESC
)
WHERE ROWNUM <= 5;

-- ----------------------------------------------------------------------------
-- Q12: Date Truncation and Monthly Trend Reporting
-- Description: Summarize transaction count and monetary volume by calendar month.
-- Concept: TO_CHAR(date, 'YYYY-MM') date transformation with GROUP BY.
-- ----------------------------------------------------------------------------
SELECT TO_CHAR(txn_date, 'YYYY-MM') AS transaction_month,
       COUNT(*) AS total_transactions,
       SUM(amount) AS total_monthly_volume,
       ROUND(AVG(amount), 2) AS avg_monthly_txn
FROM bank_transaction
GROUP BY TO_CHAR(txn_date, 'YYYY-MM')
ORDER BY transaction_month ASC;

-- ----------------------------------------------------------------------------
-- Q13: Pending Fraud Alerts with Full Context
-- Description: Compliance queue of all PENDING alerts requiring administrator review.
-- Concept: Inner join between FRAUD_ALERT and BANK_TRANSACTION with status predicate.
-- ----------------------------------------------------------------------------
SELECT f.alert_id,
       f.txn_id,
       t.account_id,
       t.txn_type,
       t.amount,
       f.risk_level,
       f.reason,
       TO_CHAR(f.alert_date, 'YYYY-MM-DD HH24:MI') AS alerted_on
FROM fraud_alert f
JOIN bank_transaction t ON f.txn_id = t.txn_id
WHERE f.review_status = 'PENDING'
ORDER BY f.alert_id ASC;

-- ----------------------------------------------------------------------------
-- Q14: Beneficiary Relationship Listing
-- Description: List registered beneficiaries and destination banks for each customer.
-- Concept: Two-table JOIN between BENEFICIARY and CUSTOMER.
-- ----------------------------------------------------------------------------
SELECT c.name AS customer_name,
       b.ben_name AS beneficiary_name,
       b.ben_account_no,
       b.bank_name,
       b.status AS beneficiary_status
FROM beneficiary b
JOIN customer c ON b.customer_id = c.customer_id
ORDER BY c.name, b.ben_name;

-- ----------------------------------------------------------------------------
-- Q15: Loan Portfolio Breakdown by Loan Status
-- Description: Breakdown of loan count and monetary exposure grouped by status.
-- Concept: GROUP BY on status with COUNT and SUM aggregates.
-- ----------------------------------------------------------------------------
SELECT status AS loan_status,
       COUNT(*) AS total_loans,
       SUM(loan_amount) AS total_exposure,
       ROUND(AVG(loan_amount), 2) AS average_loan_size,
       ROUND(AVG(interest_rate), 2) AS avg_interest_rate
FROM loan
GROUP BY status
ORDER BY total_exposure DESC;

-- ----------------------------------------------------------------------------
-- Q16: Inactive or Blocked Accounts Report
-- Description: List non-active accounts that may require investigation or reactivation.
-- Concept: WHERE status <> 'ACTIVE', joining with customer details.
-- ----------------------------------------------------------------------------
SELECT a.account_id,
       c.name AS customer_name,
       c.phone,
       a.account_type,
       a.balance,
       a.status
FROM account a
JOIN customer c ON a.customer_id = c.customer_id
WHERE a.status != 'ACTIVE'
ORDER BY a.account_id ASC;

-- ----------------------------------------------------------------------------
-- Q17: Recent Audit Trail Entries with User Action Breakdown
-- Description: Audit log verification showing recent updates, table actions, and timestamps.
-- Concept: Subquery limiting to top 10 most recent chronological audit entries.
-- ----------------------------------------------------------------------------
SELECT *
FROM (
    SELECT log_id, account_id, table_name, action_type, 
           TO_CHAR(action_time, 'YYYY-MM-DD HH24:MI:SS') AS log_time, details
    FROM audit_log
    ORDER BY log_id DESC
)
WHERE ROWNUM <= 10;

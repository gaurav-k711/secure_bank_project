-- ============================================================================
-- SecureBank DBMS Project - 09_views.sql
-- Description: Analytical and Operational Views for SecureBank reporting.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- View 1: v_customer_portfolio
-- Provides a consolidated 360-degree overview of each customer:
-- Total accounts, total deposit balance, active loans, and alert frequency.
-- ----------------------------------------------------------------------------
CREATE OR REPLACE VIEW v_customer_portfolio AS
SELECT 
    c.customer_id,
    c.name AS customer_name,
    c.phone,
    c.email,
    c.city,
    COUNT(DISTINCT a.account_id) AS total_accounts,
    NVL(SUM(a.balance), 0) AS total_balance,
    COUNT(DISTINCT l.loan_id) AS total_loans,
    NVL(SUM(l.loan_amount), 0) AS total_loan_amount
FROM customer c
LEFT JOIN account a ON c.customer_id = a.customer_id
LEFT JOIN loan l ON c.customer_id = l.customer_id
GROUP BY c.customer_id, c.name, c.phone, c.email, c.city;

-- ----------------------------------------------------------------------------
-- View 2: v_fraud_alert_details
-- Denormalized administrative view connecting fraud alerts directly to the
-- underlying transaction details, affected account, and customer.
-- ----------------------------------------------------------------------------
CREATE OR REPLACE VIEW v_fraud_alert_details AS
SELECT 
    f.alert_id,
    f.txn_id,
    t.account_id,
    c.customer_id,
    c.name AS customer_name,
    c.phone AS customer_phone,
    t.txn_type,
    t.amount AS txn_amount,
    t.txn_date,
    f.reason,
    f.risk_level,
    f.review_status,
    f.alert_date,
    f.reviewed_at
FROM fraud_alert f
JOIN bank_transaction t ON f.txn_id = t.txn_id
JOIN account a ON t.account_id = a.account_id
JOIN customer c ON a.customer_id = c.customer_id;

-- ----------------------------------------------------------------------------
-- View 3: v_loan_summary
-- Calculates repaid amount, remaining balance, and repayment percentage for all loans.
-- ----------------------------------------------------------------------------
CREATE OR REPLACE VIEW v_loan_summary AS
SELECT 
    l.loan_id,
    l.customer_id,
    c.name AS customer_name,
    l.loan_amount,
    l.interest_rate,
    l.loan_term,
    l.status,
    l.application_date,
    NVL(SUM(p.amount_paid), 0) AS total_paid,
    (l.loan_amount - NVL(SUM(p.amount_paid), 0)) AS remaining_balance,
    CASE 
        WHEN l.loan_amount > 0 THEN 
            ROUND((NVL(SUM(p.amount_paid), 0) / l.loan_amount) * 100, 2)
        ELSE 0 
    END AS repayment_percentage
FROM loan l
JOIN customer c ON l.customer_id = c.customer_id
LEFT JOIN loan_payment p ON l.loan_id = p.loan_id
GROUP BY l.loan_id, l.customer_id, c.name, l.loan_amount, l.interest_rate, l.loan_term, l.status, l.application_date;

-- ----------------------------------------------------------------------------
-- View 4: v_daily_transaction_stats
-- Daily aggregation of transaction volume and frequency for financial auditing.
-- ----------------------------------------------------------------------------
CREATE OR REPLACE VIEW v_daily_transaction_stats AS
SELECT 
    TRUNC(txn_date) AS transaction_day,
    txn_type,
    status,
    COUNT(*) AS total_transactions,
    SUM(amount) AS total_volume,
    ROUND(AVG(amount), 2) AS avg_amount,
    MIN(amount) AS min_amount,
    MAX(amount) AS max_amount
FROM bank_transaction
GROUP BY TRUNC(txn_date), txn_type, status;

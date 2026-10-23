-- ============================================================================
-- SecureBank DBMS Project - 02_constraints.sql
-- Description: Indexes, integrity checks, and constraints summary for SecureBank.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- Performance Indexes on Foreign Keys and High-Frequency Query Fields
-- (Prevents full table scans on joins and filter operations)
-- ----------------------------------------------------------------------------

-- Index on account foreign key
CREATE INDEX idx_account_customer ON account(customer_id);

-- Index on transaction account and date
CREATE INDEX idx_txn_account ON bank_transaction(account_id);
CREATE INDEX idx_txn_date ON bank_transaction(txn_date);
CREATE INDEX idx_txn_status ON bank_transaction(status);

-- Index on beneficiary customer
CREATE INDEX idx_ben_customer ON beneficiary(customer_id);

-- Index on loan customer and status
CREATE INDEX idx_loan_customer ON loan(customer_id);
CREATE INDEX idx_loan_status ON loan(status);

-- Index on loan payment
CREATE INDEX idx_payment_loan ON loan_payment(loan_id);

-- Index on fraud alert transaction and review status
CREATE INDEX idx_alert_txn ON fraud_alert(txn_id);
CREATE INDEX idx_alert_review ON fraud_alert(review_status);

-- Index on audit log account and action time
CREATE INDEX idx_audit_account ON audit_log(account_id);
CREATE INDEX idx_audit_time ON audit_log(action_time);

-- ----------------------------------------------------------------------------
-- Constraints Verification Query
-- ----------------------------------------------------------------------------
-- Execute to verify all constraints are ACTIVE and ENABLED in the schema:
-- SELECT table_name, constraint_name, constraint_type, status 
-- FROM user_constraints 
-- WHERE table_name IN ('CUSTOMER', 'ACCOUNT', 'BANK_TRANSACTION', 'BENEFICIARY', 
--                      'LOAN', 'LOAN_PAYMENT', 'FRAUD_ALERT', 'AUDIT_LOG')
-- ORDER BY table_name, constraint_type;

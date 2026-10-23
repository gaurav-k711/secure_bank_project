-- ============================================================================
-- SecureBank DBMS Project - 08_triggers.sql
-- Description: PL/SQL Triggers for automated business rules, auditing,
-- and constraint enforcement.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- Trigger 1: trg_audit_account_changes
-- Automatically creates an immutable audit trail entry whenever an account's
-- balance or status is updated.
-- ----------------------------------------------------------------------------
CREATE OR REPLACE TRIGGER trg_audit_account_changes
AFTER UPDATE OF balance, status ON account
FOR EACH ROW
DECLARE
    v_details VARCHAR2(400);
BEGIN
    IF :OLD.balance != :NEW.balance AND :OLD.status != :NEW.status THEN
        v_details := 'Balance changed from ' || :OLD.balance || ' to ' || :NEW.balance || 
                     ' and status changed from ' || :OLD.status || ' to ' || :NEW.status;
    ELSIF :OLD.balance != :NEW.balance THEN
        v_details := 'Balance changed from Rs. ' || :OLD.balance || ' to Rs. ' || :NEW.balance;
    ELSE
        v_details := 'Account status changed from ' || :OLD.status || ' to ' || :NEW.status;
    END IF;

    INSERT INTO audit_log (account_id, table_name, action_type, action_time, details)
    VALUES (:NEW.account_id, 'ACCOUNT', 'UPDATE', SYSDATE, v_details);
END trg_audit_account_changes;
/

-- ----------------------------------------------------------------------------
-- Trigger 2: trg_prevent_closed_account_txn
-- Enforces data integrity by preventing transaction insertion on CLOSED accounts.
-- ----------------------------------------------------------------------------
CREATE OR REPLACE TRIGGER trg_prevent_closed_account_txn
BEFORE INSERT ON bank_transaction
FOR EACH ROW
DECLARE
    v_status account.status%TYPE;
BEGIN
    SELECT status INTO v_status 
    FROM account 
    WHERE account_id = :NEW.account_id;

    IF v_status = 'CLOSED' THEN
        RAISE_APPLICATION_ERROR(-20061, 'Transaction rejected: Account #' || :NEW.account_id || ' is permanently CLOSED.');
    END IF;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RAISE_APPLICATION_ERROR(-20062, 'Transaction rejected: Account #' || :NEW.account_id || ' does not exist.');
END trg_prevent_closed_account_txn;
/

-- ----------------------------------------------------------------------------
-- Trigger 3: trg_auto_fraud_detection
-- Automatically evaluates transactions inserted directly and creates a fraud alert
-- if the transaction is flagged SUSPICIOUS.
-- ----------------------------------------------------------------------------
CREATE OR REPLACE TRIGGER trg_auto_fraud_detection
AFTER INSERT ON bank_transaction
FOR EACH ROW
DECLARE
    v_reason VARCHAR2(255);
BEGIN
    IF :NEW.status = 'SUSPICIOUS' THEN
        IF :NEW.amount > 100000 THEN
            v_reason := 'Transaction broke rule R1: Amount Rs. ' || :NEW.amount || ' exceeds Rs. 1,00,000 threshold';
        ELSE
            v_reason := 'Transaction broke rule R2: High-percentage balance drain (>80% of balance)';
        END IF;

        INSERT INTO fraud_alert (txn_id, reason, risk_level, review_status, alert_date)
        VALUES (:NEW.txn_id, v_reason, 'HIGH', 'PENDING', SYSDATE);
    END IF;
END trg_auto_fraud_detection;
/

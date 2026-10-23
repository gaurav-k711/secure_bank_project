-- ============================================================================
-- SecureBank DBMS Project - 05_procedures.sql
-- Description: PL/SQL Stored Procedures for core banking operations,
-- ACID money transfers, loan processing, and fraud alert reviews.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- Procedure 1: transfer_money
-- Performs an atomic, ACID-compliant funds transfer between two accounts.
-- Evaluates fraud detection rules (R1 & R2) and raises fraud alerts when flagged.
-- ----------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE transfer_money (
    p_from        IN NUMBER,
    p_to          IN NUMBER,
    p_amount      IN NUMBER,
    p_description IN VARCHAR2 DEFAULT NULL
) 
IS
    v_from_status   account.status%TYPE;
    v_to_status     account.status%TYPE;
    v_from_balance  account.balance%TYPE;
    v_txn_status    VARCHAR2(20);
    v_from_txn_id   NUMBER;
    v_to_txn_id     NUMBER;
    v_desc          VARCHAR2(255);
    v_alert_reason  VARCHAR2(255);
BEGIN
    -- 1. Validation: Amount must be positive
    IF p_amount <= 0 THEN
        RAISE_APPLICATION_ERROR(-20001, 'Transfer amount must be greater than zero.');
    END IF;

    -- 2. Validation: Sender and receiver accounts must be different
    IF p_from = p_to THEN
        RAISE_APPLICATION_ERROR(-20002, 'Sender and receiver accounts must be different.');
    END IF;

    -- 3. Lock sender account row and check status and balance (prevents race conditions)
    BEGIN
        SELECT status, balance 
        INTO v_from_status, v_from_balance
        FROM account 
        WHERE account_id = p_from 
        FOR UPDATE;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(-20003, 'Sender account #' || p_from || ' not found.');
    END;

    IF v_from_status != 'ACTIVE' THEN
        RAISE_APPLICATION_ERROR(-20004, 'Sender account is ' || v_from_status || '. Transfers not allowed.');
    END IF;

    IF v_from_balance < p_amount THEN
        RAISE_APPLICATION_ERROR(-20005, 'Insufficient funds. Available balance: Rs. ' || v_from_balance);
    END IF;

    -- 4. Lock receiver account row and check status
    BEGIN
        SELECT status 
        INTO v_to_status
        FROM account 
        WHERE account_id = p_to 
        FOR UPDATE;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(-20006, 'Receiver account #' || p_to || ' not found.');
    END;

    IF v_to_status != 'ACTIVE' THEN
        RAISE_APPLICATION_ERROR(-20007, 'Receiver account is ' || v_to_status || '. Cannot accept transfers.');
    END IF;

    -- 5. Evaluate fraud detection rules (R1 and R2)
    IF p_amount > 100000 THEN
        v_txn_status := 'SUSPICIOUS';
        v_alert_reason := 'High value transfer: Amount Rs. ' || p_amount || ' exceeds Rs. 1,00,000 threshold (Rule R1)';
    ELSIF p_amount > 50000 AND (p_amount > 0.80 * v_from_balance) THEN
        v_txn_status := 'SUSPICIOUS';
        v_alert_reason := 'Rapid balance drain: Transfer Rs. ' || p_amount || ' exceeds 80% of account balance (Rule R2)';
    ELSE
        v_txn_status := 'SUCCESS';
    END IF;

    -- 6. Update balances (Debit sender, Credit receiver)
    UPDATE account 
    SET balance = balance - p_amount 
    WHERE account_id = p_from;

    UPDATE account 
    SET balance = balance + p_amount 
    WHERE account_id = p_to;

    -- 7. Record debit transaction for sender
    v_desc := NVL(p_description, 'Transfer to account #' || p_to);
    INSERT INTO bank_transaction (account_id, txn_type, amount, status, description)
    VALUES (p_from, 'TRANSFER', p_amount, v_txn_status, v_desc);

    SELECT MAX(txn_id) INTO v_from_txn_id FROM bank_transaction WHERE account_id = p_from;

    -- 8. Record credit transaction for receiver
    INSERT INTO bank_transaction (account_id, txn_type, amount, status, description)
    VALUES (p_to, 'DEPOSIT', p_amount, 'SUCCESS', 'Transfer received from account #' || p_from);

    -- Note: Fraud alert is automatically created by database trigger trg_auto_fraud_detection
    -- whenever bank_transaction.status is set to 'SUSPICIOUS'.

    -- 9. Audit log entries
    INSERT INTO audit_log (account_id, table_name, action_type, details)
    VALUES (p_from, 'ACCOUNT', 'UPDATE', 'Transferred Rs. ' || p_amount || ' to account #' || p_to || ' | Status: ' || v_txn_status);

    INSERT INTO audit_log (account_id, table_name, action_type, details)
    VALUES (p_to, 'ACCOUNT', 'UPDATE', 'Received Rs. ' || p_amount || ' from account #' || p_from);

    COMMIT;
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
END transfer_money;
/

-- ----------------------------------------------------------------------------
-- Procedure 2: deposit_money
-- Safely deposits funds into an active account and records transaction & audit log.
-- ----------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE deposit_money (
    p_account_id  IN NUMBER,
    p_amount      IN NUMBER,
    p_description IN VARCHAR2 DEFAULT NULL
) 
IS
    v_status account.status%TYPE;
    v_desc   VARCHAR2(255);
BEGIN
    IF p_amount <= 0 THEN
        RAISE_APPLICATION_ERROR(-20011, 'Deposit amount must be greater than zero.');
    END IF;

    BEGIN
        SELECT status INTO v_status 
        FROM account 
        WHERE account_id = p_account_id 
        FOR UPDATE;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(-20012, 'Account #' || p_account_id || ' not found.');
    END;

    IF v_status != 'ACTIVE' THEN
        RAISE_APPLICATION_ERROR(-20013, 'Account is ' || v_status || '. Deposits not allowed.');
    END IF;

    UPDATE account 
    SET balance = balance + p_amount 
    WHERE account_id = p_account_id;

    v_desc := NVL(p_description, 'Cash / Cheque deposit');
    INSERT INTO bank_transaction (account_id, txn_type, amount, status, description)
    VALUES (p_account_id, 'DEPOSIT', p_amount, 'SUCCESS', v_desc);

    INSERT INTO audit_log (account_id, table_name, action_type, details)
    VALUES (p_account_id, 'ACCOUNT', 'UPDATE', 'Deposit Rs. ' || p_amount || ' credited to account #' || p_account_id);

    COMMIT;
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
END deposit_money;
/

-- ----------------------------------------------------------------------------
-- Procedure 3: withdraw_money
-- Safely withdraws funds from an active account with fraud detection and checks.
-- ----------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE withdraw_money (
    p_account_id  IN NUMBER,
    p_amount      IN NUMBER,
    p_description IN VARCHAR2 DEFAULT NULL
) 
IS
    v_status       account.status%TYPE;
    v_balance      account.balance%TYPE;
    v_txn_status   VARCHAR2(20);
    v_alert_reason VARCHAR2(255);
    v_txn_id       NUMBER;
    v_desc         VARCHAR2(255);
BEGIN
    IF p_amount <= 0 THEN
        RAISE_APPLICATION_ERROR(-20021, 'Withdrawal amount must be greater than zero.');
    END IF;

    BEGIN
        SELECT status, balance 
        INTO v_status, v_balance 
        FROM account 
        WHERE account_id = p_account_id 
        FOR UPDATE;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(-20022, 'Account #' || p_account_id || ' not found.');
    END;

    IF v_status != 'ACTIVE' THEN
        RAISE_APPLICATION_ERROR(-20023, 'Account is ' || v_status || '. Withdrawals not allowed.');
    END IF;

    IF v_balance < p_amount THEN
        RAISE_APPLICATION_ERROR(-20024, 'Insufficient funds. Available balance: Rs. ' || v_balance);
    END IF;

    -- Evaluate fraud detection rules (R1 and R2)
    IF p_amount > 100000 THEN
        v_txn_status := 'SUSPICIOUS';
        v_alert_reason := 'High cash withdrawal: Amount Rs. ' || p_amount || ' exceeds Rs. 1,00,000 threshold (Rule R1)';
    ELSIF p_amount > 50000 AND (p_amount > 0.80 * v_balance) THEN
        v_txn_status := 'SUSPICIOUS';
        v_alert_reason := 'Rapid balance drain: Cash withdrawal Rs. ' || p_amount || ' exceeds 80% of account balance (Rule R2)';
    ELSE
        v_txn_status := 'SUCCESS';
    END IF;

    UPDATE account 
    SET balance = balance - p_amount 
    WHERE account_id = p_account_id;

    v_desc := NVL(p_description, 'ATM / Counter cash withdrawal');
    INSERT INTO bank_transaction (account_id, txn_type, amount, status, description)
    VALUES (p_account_id, 'WITHDRAW', p_amount, v_txn_status, v_desc);

    -- Note: trg_auto_fraud_detection creates fraud alert if v_txn_status = 'SUSPICIOUS'

    INSERT INTO audit_log (account_id, table_name, action_type, details)
    VALUES (p_account_id, 'ACCOUNT', 'UPDATE', 'Withdrawal Rs. ' || p_amount || ' debited | Status: ' || v_txn_status);

    COMMIT;
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
END withdraw_money;
/

-- ----------------------------------------------------------------------------
-- Procedure 4: process_loan
-- Evaluates loan application against active accounts and customer risk (Rule R3).
-- ----------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE process_loan (
    p_customer_id   IN NUMBER,
    p_amount        IN NUMBER,
    p_interest_rate IN NUMBER DEFAULT 8.5,
    p_term          IN NUMBER DEFAULT 12
) 
IS
    v_active_accounts NUMBER;
    v_risk            VARCHAR2(20);
    v_loan_status     VARCHAR2(20);
BEGIN
    IF p_amount <= 0 THEN
        RAISE_APPLICATION_ERROR(-20031, 'Loan amount must be greater than zero.');
    END IF;

    -- Validate active account
    SELECT COUNT(*) 
    INTO v_active_accounts 
    FROM account 
    WHERE customer_id = p_customer_id AND status = 'ACTIVE';

    IF v_active_accounts = 0 THEN
        RAISE_APPLICATION_ERROR(-20032, 'Customer #' || p_customer_id || ' has no active bank account.');
    END IF;

    -- Check customer risk (Rule R3)
    v_risk := get_customer_risk(p_customer_id);

    IF v_risk = 'HIGH' THEN
        v_loan_status := 'REJECTED';
    ELSE
        v_loan_status := 'APPROVED';
    END IF;

    INSERT INTO loan (customer_id, loan_amount, interest_rate, loan_term, status, application_date)
    VALUES (p_customer_id, p_amount, p_interest_rate, p_term, v_loan_status, SYSDATE);

    INSERT INTO audit_log (account_id, table_name, action_type, details)
    VALUES (NULL, 'LOAN', 'INSERT', 'Loan request for Rs. ' || p_amount || ' by customer #' || p_customer_id || ' evaluated: ' || v_loan_status || ' (Risk: ' || v_risk || ')');

    COMMIT;
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
END process_loan;
/

-- ----------------------------------------------------------------------------
-- Procedure 5: pay_loan
-- Records a loan repayment and automatically closes the loan if fully paid.
-- ----------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE pay_loan (
    p_loan_id IN NUMBER,
    p_amount  IN NUMBER
) 
IS
    v_loan_amount  loan.loan_amount%TYPE;
    v_loan_status  loan.status%TYPE;
    v_total_paid   NUMBER(14, 2);
BEGIN
    IF p_amount <= 0 THEN
        RAISE_APPLICATION_ERROR(-20041, 'Repayment amount must be greater than zero.');
    END IF;

    BEGIN
        SELECT loan_amount, status 
        INTO v_loan_amount, v_loan_status
        FROM loan 
        WHERE loan_id = p_loan_id 
        FOR UPDATE;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(-20042, 'Loan #' || p_loan_id || ' not found.');
    END;

    IF v_loan_status != 'APPROVED' THEN
        RAISE_APPLICATION_ERROR(-20043, 'Cannot make payment for a loan with status: ' || v_loan_status);
    END IF;

    INSERT INTO loan_payment (loan_id, amount_paid, payment_date, payment_status)
    VALUES (p_loan_id, p_amount, SYSDATE, 'COMPLETED');

    SELECT NVL(SUM(amount_paid), 0) 
    INTO v_total_paid 
    FROM loan_payment 
    WHERE loan_id = p_loan_id;

    IF v_total_paid >= v_loan_amount THEN
        UPDATE loan 
        SET status = 'CLOSED' 
        WHERE loan_id = p_loan_id;
    END IF;

    INSERT INTO audit_log (account_id, table_name, action_type, details)
    VALUES (NULL, 'LOAN_PAYMENT', 'INSERT', 'Repayment of Rs. ' || p_amount || ' for loan #' || p_loan_id || ' recorded. Total paid: Rs. ' || v_total_paid);

    COMMIT;
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
END pay_loan;
/

-- ----------------------------------------------------------------------------
-- Procedure 6: review_fraud_alert
-- Allows bank administrator or compliance officer to mark an alert reviewed,
-- false alarm, or confirmed, updating audit trail.
-- ----------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE review_fraud_alert (
    p_alert_id       IN NUMBER,
    p_new_status     IN VARCHAR2,
    p_reviewer_notes IN VARCHAR2 DEFAULT NULL
) 
IS
    v_txn_id   NUMBER;
    v_acc_id   NUMBER;
    v_details  VARCHAR2(400);
BEGIN
    IF p_new_status NOT IN ('REVIEWED', 'CONFIRMED', 'FALSE_ALARM') THEN
        RAISE_APPLICATION_ERROR(-20051, 'Invalid review status. Must be REVIEWED, CONFIRMED, or FALSE_ALARM.');
    END IF;

    SELECT a.txn_id, t.account_id 
    INTO v_txn_id, v_acc_id 
    FROM fraud_alert a
    JOIN bank_transaction t ON a.txn_id = t.txn_id
    WHERE a.alert_id = p_alert_id;

    UPDATE fraud_alert 
    SET review_status = p_new_status,
        reviewed_at = SYSDATE 
    WHERE alert_id = p_alert_id;

    v_details := 'Fraud alert #' || p_alert_id || ' updated to ' || p_new_status || '. Notes: ' || NVL(p_reviewer_notes, 'None');
    
    INSERT INTO audit_log (account_id, table_name, action_type, details)
    VALUES (v_acc_id, 'FRAUD_ALERT', 'REVIEW', v_details);

    COMMIT;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        ROLLBACK;
        RAISE_APPLICATION_ERROR(-20052, 'Fraud alert #' || p_alert_id || ' not found.');
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
END review_fraud_alert;
/

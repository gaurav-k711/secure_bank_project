-- ============================================================================
-- SecureBank DBMS Project - 06_functions.sql
-- Description: Oracle PL/SQL Functions for balance lookups, fraud rules,
-- customer risk classification, and EMI calculation.
-- ============================================================================

-- ----------------------------------------------------------------------------
-- Function 1: get_balance
-- Returns the current balance of a specified account.
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION get_balance (
    p_account_id IN NUMBER
) RETURN NUMBER 
IS
    v_balance NUMBER(14, 2);
BEGIN
    SELECT balance 
    INTO v_balance 
    FROM account 
    WHERE account_id = p_account_id;
    
    RETURN v_balance;
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        RETURN -1;
    WHEN OTHERS THEN
        RETURN -1;
END get_balance;
/

-- ----------------------------------------------------------------------------
-- Function 2: get_txn_status
-- Evaluates fraud detection rules R1 and R2 for a proposed transaction amount.
-- Returns 'SUSPICIOUS' if any threshold is violated, otherwise 'NORMAL'.
--
-- Rules:
--   R1: Transaction amount > Rs. 1,00,000
--   R2: Transaction amount > Rs. 50,000 AND > 80% of current account balance
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION get_txn_status (
    p_account_id IN NUMBER,
    p_amount     IN NUMBER
) RETURN VARCHAR2 
IS
    v_balance NUMBER(14, 2);
BEGIN
    v_balance := get_balance(p_account_id);
    
    -- Rule R1: Absolute threshold
    IF p_amount > 100000 THEN
        RETURN 'SUSPICIOUS';
    END IF;
    
    -- Rule R2: Relative high-percentage drain
    IF p_amount > 50000 AND v_balance > 0 AND (p_amount > 0.80 * v_balance) THEN
        RETURN 'SUSPICIOUS';
    END IF;
    
    RETURN 'NORMAL';
END get_txn_status;
/

-- ----------------------------------------------------------------------------
-- Function 3: get_customer_risk
-- Evaluates Rule R3: Customer risk based on historical fraud alerts.
-- Returns 'HIGH' (>= 3 alerts), 'MEDIUM' (1-2 alerts), or 'LOW' (0 alerts).
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION get_customer_risk (
    p_customer_id IN NUMBER
) RETURN VARCHAR2 
IS
    v_alert_count NUMBER := 0;
BEGIN
    SELECT COUNT(f.alert_id) 
    INTO v_alert_count
    FROM fraud_alert f
    JOIN bank_transaction t ON f.txn_id = t.txn_id
    JOIN account a ON t.account_id = a.account_id
    WHERE a.customer_id = p_customer_id;
    
    IF v_alert_count >= 3 THEN
        RETURN 'HIGH';
    ELSIF v_alert_count >= 1 THEN
        RETURN 'MEDIUM';
    ELSE
        RETURN 'LOW';
    END IF;
END get_customer_risk;
/

-- ----------------------------------------------------------------------------
-- Function 4: calculate_loan_emi
-- Calculates monthly Equated Monthly Installment (EMI) using the formula:
--   EMI = [P x r x (1+r)^n] / [(1+r)^n - 1]
-- where:
--   P = Principal amount (p_amount)
--   r = Monthly interest rate (p_annual_rate / (12 * 100))
--   n = Term in months (p_term_months)
-- ----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION calculate_loan_emi (
    p_amount        IN NUMBER,
    p_annual_rate   IN NUMBER,
    p_term_months   IN NUMBER
) RETURN NUMBER 
IS
    v_monthly_rate NUMBER;
    v_factor       NUMBER;
    v_emi          NUMBER(14, 2);
BEGIN
    IF p_amount <= 0 OR p_term_months <= 0 THEN
        RETURN 0;
    END IF;

    -- Zero interest edge case
    IF p_annual_rate = 0 THEN
        RETURN ROUND(p_amount / p_term_months, 2);
    END IF;

    v_monthly_rate := p_annual_rate / (12 * 100);
    v_factor := POWER(1 + v_monthly_rate, p_term_months);
    v_emi := ROUND((p_amount * v_monthly_rate * v_factor) / (v_factor - 1), 2);

    RETURN v_emi;
EXCEPTION
    WHEN OTHERS THEN
        RETURN 0;
END calculate_loan_emi;
/

-- ============================================================================
-- SecureBank DBMS Project - setup_all.sql
-- Master Execution Script: Runs all DDL, DML, Functions, Procedures,
-- Cursors, Triggers, and Views in correct dependency sequence.
--
-- How to run in SQL*Plus:
--   sqlplus securebank/securebank@127.0.0.1:1521/XE @setup_all.sql
-- ============================================================================

SET DEFINE OFF;
SET FEEDBACK ON;

PROMPT ============================================================
PROMPT 1. Creating Tables...
PROMPT ============================================================
@@01_create_tables.sql;

PROMPT ============================================================
PROMPT 2. Creating Constraints and Indexes...
PROMPT ============================================================
@@02_constraints.sql;

PROMPT ============================================================
PROMPT 3. Creating Sequences and PK Triggers...
PROMPT ============================================================
@@03_sequences.sql;

PROMPT ============================================================
PROMPT 4. Populating Sample Data (10+ records per table)...
PROMPT ============================================================
@@04_sample_data.sql;

PROMPT ============================================================
PROMPT 5. Creating Functions...
PROMPT ============================================================
@@06_functions.sql;

PROMPT ============================================================
PROMPT 6. Creating Stored Procedures...
PROMPT ============================================================
@@05_procedures.sql;

PROMPT ============================================================
PROMPT 7. Creating Cursors...
PROMPT ============================================================
@@07_cursors.sql;

PROMPT ============================================================
PROMPT 8. Creating Business and Audit Triggers...
PROMPT ============================================================
@@08_triggers.sql;

PROMPT ============================================================
PROMPT 9. Creating Views...
PROMPT ============================================================
@@09_views.sql;

PROMPT ============================================================
PROMPT SecureBank Database Setup Complete!
PROMPT Verifying Table Record Counts:
PROMPT ============================================================

SELECT 'CUSTOMER' AS table_name, COUNT(*) AS row_count FROM customer
UNION ALL
SELECT 'ACCOUNT', COUNT(*) FROM account
UNION ALL
SELECT 'BANK_TRANSACTION', COUNT(*) FROM bank_transaction
UNION ALL
SELECT 'BENEFICIARY', COUNT(*) FROM beneficiary
UNION ALL
SELECT 'LOAN', COUNT(*) FROM loan
UNION ALL
SELECT 'LOAN_PAYMENT', COUNT(*) FROM loan_payment
UNION ALL
SELECT 'FRAUD_ALERT', COUNT(*) FROM fraud_alert
UNION ALL
SELECT 'AUDIT_LOG', COUNT(*) FROM audit_log;

COMMIT;

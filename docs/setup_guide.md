# SecureBank — Installation & Deployment Guide

This guide provides step-by-step instructions to configure Oracle Database, create schemas, populate sample records, and launch the SecureBank web application.

---

## 1. Prerequisites

- **Operating System**: Windows 10/11, Linux, or macOS.
- **Database Engine**: Oracle Database 11g XE, 12c, 19c, 21c, or 23c.
- **Python Runtime**: Python 3.10 or newer.
- **Required Packages**: `fastapi`, `uvicorn`, `jinja2`, `python-multipart`, `cx_Oracle` (for Oracle 11g XE) or `oracledb` (for Oracle 12c+), `pytest`, `python-dotenv`.

---

## 2. Oracle Database Setup

### Step A: Connect as Administrator
Open PowerShell or Command Prompt as Administrator and connect to SQL*Plus:

```powershell
# Set ORACLE_SID if working on local Express Edition
$env:ORACLE_SID="XE"

# Connect via sysdba
sqlplus "/ as sysdba"
```

### Step B: Create the SecureBank Database User
Execute the following commands in SQL*Plus:

```sql
-- Create user
CREATE USER securebank IDENTIFIED BY securebank;

-- Grant core privileges
GRANT CONNECT, RESOURCE, DBA TO securebank;
GRANT UNLIMITED TABLESPACE TO securebank;

EXIT;
```

---

## 3. Database Schema & Sample Data Initialization

Execute the master setup script `setup_all.sql` located in `securebank/database/`. This script automatically creates all 8 tables, indexes, sequences, sample data, functions, procedures, cursors, triggers, and views in the exact required dependency order.

### Option 1: Execute via SQL*Plus (Recommended)
```powershell
cd securebank/database
cmd /c "sqlplus -S securebank/securebank @setup_all.sql < NUL"
```

### Expected Output Summary:
```text
Table created. (x8)
Index created. (x12)
Sequence created. (x8)
Trigger created. (x11)
Function created. (x4)
Procedure created. (x6)
View created. (x4)

TABLE_NAME         ROW_COUNT
-----------------  ---------
CUSTOMER                  10
ACCOUNT                   10
BANK_TRANSACTION          20
BENEFICIARY               10
LOAN                      10
LOAN_PAYMENT              10
FRAUD_ALERT               10
AUDIT_LOG                 10
```

---

## 4. Python Environment & Dependency Installation

1. Navigate to the project root directory:
   ```powershell
   cd c:\Users\admin\OneDrive\Desktop\NIDS-project
   ```

2. Install dependencies:
   ```powershell
   pip install -r securebank/requirements.txt
   ```

3. Configure Environment Variables (`securebank/.env`):
   ```ini
   ORACLE_USER=securebank
   ORACLE_PASSWORD=securebank
   ORACLE_DSN=127.0.0.1:1521/XE
   ORACLE_CLIENT_DIR=C:\oraclexe\app\oracle\product\11.2.0\server\bin
   APP_HOST=127.0.0.1
   APP_PORT=8000
   ```

---

## 5. Running the Application

Launch the FastAPI application server:

```powershell
python securebank/run.py
```

Or run via Uvicorn:
```powershell
uvicorn securebank.app.main:app --host 127.0.0.1 --port 8000 --reload
```

Open your browser and navigate to:
👉 **`http://127.0.0.1:8000`**

---

## 6. Running Automated Verification Tests

Execute the 16 automated tests covering transactions, ACID transfers, fraud detection rules, procedures, constraints, and cursor execution:

```powershell
python -m pytest securebank/tests/test_banking.py -v
```

All 16 test cases should report `PASSED`.

---

## 7. Troubleshooting Common Issues

| Error | Cause | Resolution |
|---|---|---|
| `ORA-12541: TNS:no listener` | Oracle Listener service is stopped | Run `Start-Service OracleXETNSListener` in PowerShell as Admin |
| `ORA-01017: invalid username/password` | User `securebank` has not been created | Re-run Step 2 to create user with password `securebank` |
| `DPI-1047: Cannot locate a 64-bit Oracle Client library` | Missing Oracle Client DLLs in PATH | Ensure `ORACLE_CLIENT_DIR` points to `C:\oraclexe\app\oracle\product\11.2.0\server\bin` |
| `ORA-00001: unique constraint violated` | Duplicate phone or email inserted | Use distinct contact numbers for new customer entries |

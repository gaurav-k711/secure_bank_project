"""
SecureBank - Smart Banking Management System with Database-Based Fraud Detection
Main FastAPI Application Entrypoint.
"""

from fastapi import FastAPI, Request
from fastapi.responses import HTMLResponse
from fastapi.staticfiles import StaticFiles
from fastapi.templating import Jinja2Templates
from pathlib import Path

from .database import execute_query, test_connection
from .routes import customers, accounts, transactions, beneficiaries, loans, fraud_alerts, reports, audit_logs

BASE_DIR = Path(__file__).resolve().parent

app = FastAPI(
    title="SecureBank DBMS",
    description="College DBMS Project: Smart Banking Management System with Database-Based Fraud Detection",
    version="1.0.0"
)

# Mount static assets
app.mount("/static", StaticFiles(directory=str(BASE_DIR / "static")), name="static")

# Templates
templates = Jinja2Templates(directory=str(BASE_DIR / "templates"))

# Register sub-routers
app.include_router(customers.router)
app.include_router(accounts.router)
app.include_router(transactions.router)
app.include_router(beneficiaries.router)
app.include_router(loans.router)
app.include_router(fraud_alerts.router)
app.include_router(reports.router)
app.include_router(audit_logs.router)


@app.get("/", response_class=HTMLResponse)
async def dashboard(request: Request):
    """
    Dashboard providing real-time statistics directly queried from the Oracle database:
    - Total Customers
    - Total Accounts
    - Total Transaction Value
    - Suspicious Activity (Fraud) Alerts
    - Pending Loan Applications
    """
    db_ok, db_status = test_connection()

    stats = {
        "total_customers": 0,
        "total_accounts": 0,
        "total_txn_volume": 0.0,
        "pending_alerts": 0,
        "pending_loans": 0,
        "total_deposits": 0.0
    }
    recent_txns = []
    recent_alerts = []

    if db_ok:
        try:
            # 1. Total Customers
            res = execute_query("SELECT COUNT(*) AS cnt FROM customer", fetch_one=True)
            stats["total_customers"] = res["cnt"] if res else 0

            # 2. Total Accounts & Total Deposits
            res = execute_query("SELECT COUNT(*) AS cnt, NVL(SUM(balance), 0) AS total_bal FROM account", fetch_one=True)
            if res:
                stats["total_accounts"] = res["cnt"]
                stats["total_deposits"] = res["total_bal"]

            # 3. Total Transaction Volume
            res = execute_query("SELECT NVL(SUM(amount), 0) AS total_vol FROM bank_transaction", fetch_one=True)
            stats["total_txn_volume"] = res["total_vol"] if res else 0.0

            # 4. Pending Fraud Alerts
            res = execute_query("SELECT COUNT(*) AS cnt FROM fraud_alert WHERE review_status = 'PENDING'", fetch_one=True)
            stats["pending_alerts"] = res["cnt"] if res else 0

            # 5. Pending Loans
            res = execute_query("SELECT COUNT(*) AS cnt FROM loan WHERE status = 'PENDING'", fetch_one=True)
            stats["pending_loans"] = res["cnt"] if res else 0

            # Recent 6 transactions
            recent_txns_sql = """
                SELECT t.txn_id, t.account_id, c.name AS customer_name,
                       t.txn_type, t.amount, t.status,
                       TO_CHAR(t.txn_date, 'YYYY-MM-DD HH24:MI') AS txn_date
                FROM bank_transaction t
                JOIN account a ON t.account_id = a.account_id
                JOIN customer c ON a.customer_id = c.customer_id
                WHERE ROWNUM <= 6
                ORDER BY t.txn_id DESC
            """
            recent_txns = execute_query(recent_txns_sql)

            # Recent 5 fraud alerts
            recent_alerts_sql = """
                SELECT f.alert_id, f.txn_id, c.name AS customer_name,
                       t.amount, f.reason, f.risk_level, f.review_status,
                       TO_CHAR(f.alert_date, 'YYYY-MM-DD HH24:MI') AS alert_date
                FROM fraud_alert f
                JOIN bank_transaction t ON f.txn_id = t.txn_id
                JOIN account a ON t.account_id = a.account_id
                JOIN customer c ON a.customer_id = c.customer_id
                WHERE ROWNUM <= 5
                ORDER BY f.alert_id DESC
            """
            recent_alerts = execute_query(recent_alerts_sql)

        except Exception as e:
            db_status = str(e)

    return templates.TemplateResponse(request=request, name="dashboard.html", context={
        "request": request,
        "db_ok": db_ok,
        "db_status": db_status,
        "stats": stats,
        "recent_txns": recent_txns,
        "recent_alerts": recent_alerts
    })

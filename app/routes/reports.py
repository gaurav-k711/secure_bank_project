from fastapi import APIRouter, Request
from fastapi.responses import HTMLResponse
from fastapi.templating import Jinja2Templates
from pathlib import Path
from ..database import execute_query

router = APIRouter(prefix="/reports", tags=["reports"])
templates = Jinja2Templates(directory=str(Path(__file__).resolve().parent.parent / "templates"))


@router.get("", response_class=HTMLResponse)
async def view_reports(request: Request, report_type: str = "summary"):
    """Render analytical and compliance reports powered by live database queries."""

    # 1. Total Deposits vs Withdrawals vs Transfers
    sql_totals = """
        SELECT txn_type,
               COUNT(*) AS total_count,
               SUM(amount) AS total_amount,
               ROUND(AVG(amount), 2) AS avg_amount,
               MIN(amount) AS min_amount,
               MAX(amount) AS max_amount
        FROM bank_transaction
        GROUP BY txn_type
        ORDER BY total_amount DESC
    """
    totals_report = execute_query(sql_totals)

    # 2. Account-wise Transaction Volume & Counts
    sql_accounts = """
        SELECT a.account_id,
               c.name AS customer_name,
               a.account_type,
               a.balance,
               COUNT(t.txn_id) AS txn_count,
               NVL(SUM(CASE WHEN t.txn_type = 'DEPOSIT' THEN t.amount ELSE 0 END), 0) AS total_deposited,
               NVL(SUM(CASE WHEN t.txn_type IN ('WITHDRAW', 'TRANSFER') THEN t.amount ELSE 0 END), 0) AS total_withdrawn
        FROM account a
        JOIN customer c ON a.customer_id = c.customer_id
        LEFT JOIN bank_transaction t ON a.account_id = t.account_id
        GROUP BY a.account_id, c.name, a.account_type, a.balance
        ORDER BY total_deposited + total_withdrawn DESC
    """
    accounts_report = execute_query(sql_accounts)

    # 3. Customers with Multiple Accounts
    sql_multi_accounts = """
        SELECT c.customer_id,
               c.name,
               c.phone,
               c.city,
               COUNT(a.account_id) AS account_count,
               SUM(a.balance) AS combined_balance
        FROM customer c
        JOIN account a ON c.customer_id = a.customer_id
        GROUP BY c.customer_id, c.name, c.phone, c.city
        HAVING COUNT(a.account_id) >= 1
        ORDER BY account_count DESC, combined_balance DESC
    """
    multi_accounts_report = execute_query(sql_multi_accounts)

    # 4. Loan Portfolio & Repayment Progress
    sql_loans = """
        SELECT l.loan_id,
               c.name AS customer_name,
               l.loan_amount,
               l.interest_rate,
               l.status,
               NVL(SUM(p.amount_paid), 0) AS amount_paid,
               (l.loan_amount - NVL(SUM(p.amount_paid), 0)) AS remaining_amount,
               COUNT(p.payment_id) AS payment_count
        FROM loan l
        JOIN customer c ON l.customer_id = c.customer_id
        LEFT JOIN loan_payment p ON l.loan_id = p.loan_id
        GROUP BY l.loan_id, c.name, l.loan_amount, l.interest_rate, l.status
        ORDER BY l.loan_id ASC
    """
    loans_report = execute_query(sql_loans)

    # 5. High-Value Transactions (Above Rs. 1,00,000 threshold)
    sql_high_val = """
        SELECT t.txn_id,
               t.account_id,
               c.name AS customer_name,
               t.txn_type,
               t.amount,
               t.status,
               TO_CHAR(t.txn_date, 'YYYY-MM-DD HH24:MI') AS txn_date,
               t.description
        FROM bank_transaction t
        JOIN account a ON t.account_id = a.account_id
        JOIN customer c ON a.customer_id = c.customer_id
        WHERE t.amount >= 100000
        ORDER BY t.amount DESC
    """
    high_val_report = execute_query(sql_high_val)

    # 6. Suspicious Transactions by Date and Risk
    sql_suspicious = """
        SELECT f.alert_id,
               f.txn_id,
               c.name AS customer_name,
               t.amount,
               f.reason,
               f.risk_level,
               f.review_status,
               TO_CHAR(f.alert_date, 'YYYY-MM-DD HH24:MI') AS alert_date
        FROM fraud_alert f
        JOIN bank_transaction t ON f.txn_id = t.txn_id
        JOIN account a ON t.account_id = a.account_id
        JOIN customer c ON a.customer_id = c.customer_id
        ORDER BY f.alert_date DESC
    """
    suspicious_report = execute_query(sql_suspicious)

    # 7. Monthly Transaction Summary
    sql_monthly = """
        SELECT TO_CHAR(txn_date, 'YYYY-MM') AS month_str,
               COUNT(*) AS total_txns,
               SUM(amount) AS total_volume,
               ROUND(AVG(amount), 2) AS avg_ticket_size,
               SUM(CASE WHEN status = 'SUSPICIOUS' THEN 1 ELSE 0 END) AS suspicious_count
        FROM bank_transaction
        GROUP BY TO_CHAR(txn_date, 'YYYY-MM')
        ORDER BY month_str ASC
    """
    monthly_report = execute_query(sql_monthly)

    return templates.TemplateResponse(request=request, name="reports.html", context={
        "request": request,
        "report_type": report_type,
        "totals_report": totals_report,
        "accounts_report": accounts_report,
        "multi_accounts_report": multi_accounts_report,
        "loans_report": loans_report,
        "high_val_report": high_val_report,
        "suspicious_report": suspicious_report,
        "monthly_report": monthly_report
    })

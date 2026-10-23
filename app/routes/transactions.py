from fastapi import APIRouter, Request, Form
from fastapi.responses import HTMLResponse, RedirectResponse
from fastapi.templating import Jinja2Templates
from pathlib import Path
from ..database import execute_query, call_procedure

router = APIRouter(prefix="/transactions", tags=["transactions"])
templates = Jinja2Templates(directory=str(Path(__file__).resolve().parent.parent / "templates"))


@router.get("", response_class=HTMLResponse)
async def list_transactions(
    request: Request,
    account_id: int = None,
    txn_type: str = None,
    status: str = None,
    min_amount: float = None,
    success: str = None,
    error: str = None,
    alert_info: str = None
):
    """View transaction history with filtering across accounts, types, and fraud statuses."""
    conditions = []
    params = {}

    if account_id:
        conditions.append("t.account_id = :account_id")
        params["account_id"] = account_id
    if txn_type and txn_type != "ALL":
        conditions.append("t.txn_type = :txn_type")
        params["txn_type"] = txn_type
    if status and status != "ALL":
        conditions.append("t.status = :status")
        params["status"] = status
    if min_amount is not None:
        conditions.append("t.amount >= :min_amount")
        params["min_amount"] = min_amount

    where_clause = "WHERE " + " AND ".join(conditions) if conditions else ""

    sql = f"""
        SELECT t.txn_id, t.account_id, c.name AS customer_name,
               t.txn_type, t.amount, t.status, t.description,
               TO_CHAR(t.txn_date, 'YYYY-MM-DD HH24:MI:SS') AS txn_date,
               (SELECT COUNT(*) FROM fraud_alert fa WHERE fa.txn_id = t.txn_id) AS has_alert
        FROM bank_transaction t
        JOIN account a ON t.account_id = a.account_id
        JOIN customer c ON a.customer_id = c.customer_id
        {where_clause}
        ORDER BY t.txn_id DESC
    """
    transactions = execute_query(sql, params)

    # Fetch active accounts for forms
    active_acc_sql = """
        SELECT a.account_id, c.name, a.account_type, a.balance, a.status
        FROM account a
        JOIN customer c ON a.customer_id = c.customer_id
        WHERE a.status = 'ACTIVE'
        ORDER BY a.account_id ASC
    """
    active_accounts = execute_query(active_acc_sql)

    return templates.TemplateResponse("transactions.html", {
        "request": request,
        "transactions": transactions,
        "active_accounts": active_accounts,
        "selected_account": account_id or "",
        "selected_type": txn_type or "ALL",
        "selected_status": status or "ALL",
        "min_amount": min_amount or "",
        "success": success,
        "error": error,
        "alert_info": alert_info
    })


@router.post("/deposit")
async def do_deposit(
    account_id: int = Form(...),
    amount: float = Form(...),
    description: str = Form("Cash Deposit")
):
    """Execute a deposit using the deposit_money PL/SQL procedure."""
    try:
        call_procedure("deposit_money", [account_id, amount, description])
        return RedirectResponse(
            url=f"/transactions?success=Successfully+deposited+Rs.+{amount:,.2f}+into+Account+#{account_id}",
            status_code=303
        )
    except Exception as e:
        return RedirectResponse(url=f"/transactions?error={str(e)}", status_code=303)


@router.post("/withdraw")
async def do_withdraw(
    account_id: int = Form(...),
    amount: float = Form(...),
    description: str = Form("Cash Withdrawal")
):
    """Execute a withdrawal using the withdraw_money PL/SQL procedure."""
    try:
        call_procedure("withdraw_money", [account_id, amount, description])
        
        # Check if the latest txn was flagged suspicious
        latest = execute_query("""
            SELECT status FROM (
                SELECT status FROM bank_transaction 
                WHERE account_id = :id 
                ORDER BY txn_id DESC
            ) WHERE ROWNUM = 1
        """, {"id": account_id}, fetch_one=True)

        if latest and latest.get("status") == "SUSPICIOUS":
            alert_msg = f"WARNING: Withdrawal of Rs. {amount:,.2f} triggered a DATABASE FRAUD ALERT! Transaction status: SUSPICIOUS."
            return RedirectResponse(url=f"/transactions?alert_info={alert_msg}", status_code=303)

        return RedirectResponse(
            url=f"/transactions?success=Successfully+withdrew+Rs.+{amount:,.2f}+from+Account+#{account_id}",
            status_code=303
        )
    except Exception as e:
        return RedirectResponse(url=f"/transactions?error={str(e)}", status_code=303)


@router.post("/transfer")
async def do_transfer(
    from_account: int = Form(...),
    to_account: int = Form(...),
    amount: float = Form(...),
    description: str = Form(None)
):
    """Execute an atomic transfer using the transfer_money PL/SQL procedure."""
    try:
        call_procedure("transfer_money", [from_account, to_account, amount, description or "Online Funds Transfer"])

        # Check if transaction was flagged suspicious
        latest = execute_query("""
            SELECT status FROM (
                SELECT status FROM bank_transaction 
                WHERE account_id = :id AND txn_type = 'TRANSFER'
                ORDER BY txn_id DESC
            ) WHERE ROWNUM = 1
        """, {"id": from_account}, fetch_one=True)

        if latest and latest.get("status") == "SUSPICIOUS":
            alert_msg = f"FRAUD DETECTED: Transfer of Rs. {amount:,.2f} violated configured fraud rule(s). Flagged as SUSPICIOUS and recorded in Fraud Alerts table!"
            return RedirectResponse(url=f"/transactions?alert_info={alert_msg}", status_code=303)

        return RedirectResponse(
            url=f"/transactions?success=Successfully+transferred+Rs.+{amount:,.2f}+from+Account+#{from_account}+to+Account+#{to_account}",
            status_code=303
        )
    except Exception as e:
        return RedirectResponse(url=f"/transactions?error={str(e)}", status_code=303)

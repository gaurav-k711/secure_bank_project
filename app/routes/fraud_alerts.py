from fastapi import APIRouter, Request, Form
from fastapi.responses import HTMLResponse, RedirectResponse
from fastapi.templating import Jinja2Templates
from pathlib import Path
from ..database import execute_query, call_procedure

router = APIRouter(prefix="/fraud-alerts", tags=["fraud-alerts"])
templates = Jinja2Templates(directory=str(Path(__file__).resolve().parent.parent / "templates"))


@router.get("", response_class=HTMLResponse)
async def list_fraud_alerts(
    request: Request,
    risk: str = None,
    status: str = None,
    success: str = None,
    error: str = None
):
    """View all detected fraud alerts with filtering by risk level and review status."""
    conditions = []
    params = {}

    if risk and risk != "ALL":
        conditions.append("risk_level = :risk")
        params["risk"] = risk
    if status and status != "ALL":
        conditions.append("review_status = :status")
        params["status"] = status

    where_clause = "WHERE " + " AND ".join(conditions) if conditions else ""

    sql = f"""
        SELECT alert_id, txn_id, account_id, customer_id, customer_name,
               customer_phone, txn_type, txn_amount,
               TO_CHAR(txn_date, 'YYYY-MM-DD HH24:MI') AS txn_date,
               reason, risk_level, review_status,
               TO_CHAR(alert_date, 'YYYY-MM-DD HH24:MI') AS alert_date,
               TO_CHAR(reviewed_at, 'YYYY-MM-DD HH24:MI') AS reviewed_at
        FROM v_fraud_alert_details
        {where_clause}
        ORDER BY alert_id DESC
    """
    alerts = execute_query(sql, params)

    # Summary stats
    stats_sql = """
        SELECT 
            COUNT(*) AS total_alerts,
            SUM(CASE WHEN review_status = 'PENDING' THEN 1 ELSE 0 END) AS pending_alerts,
            SUM(CASE WHEN review_status = 'CONFIRMED' THEN 1 ELSE 0 END) AS confirmed_alerts,
            SUM(CASE WHEN review_status = 'FALSE_ALARM' THEN 1 ELSE 0 END) AS false_alarms
        FROM fraud_alert
    """
    stats = execute_query(stats_sql, fetch_one=True) or {}

    return templates.TemplateResponse(request=request, name="fraud_alerts.html", context={
        "request": request,
        "alerts": alerts,
        "stats": stats,
        "selected_risk": risk or "ALL",
        "selected_status": status or "ALL",
        "success": success,
        "error": error
    })


@router.post("/{alert_id}/review")
async def review_alert(
    alert_id: int,
    review_status: str = Form(...),
    notes: str = Form(None)
):
    """Update review status of a fraud alert using review_fraud_alert procedure."""
    try:
        call_procedure("review_fraud_alert", [alert_id, review_status, notes or "Admin review completed"])
        return RedirectResponse(
            url=f"/fraud-alerts?success=Alert+#{alert_id}+marked+as+{review_status}",
            status_code=303
        )
    except Exception as e:
        return RedirectResponse(url=f"/fraud-alerts?error={str(e)}", status_code=303)


@router.post("/batch-audit")
async def run_batch_audit_cursor():
    """Execute the PL/SQL cursor procedure check_high_risk_accounts."""
    try:
        call_procedure("check_high_risk_accounts", [])
        return RedirectResponse(
            url="/fraud-alerts?success=Batch+cursor+executed+successfully.+High-risk+accounts+have+been+blocked+and+audited.",
            status_code=303
        )
    except Exception as e:
        return RedirectResponse(url=f"/fraud-alerts?error={str(e)}", status_code=303)

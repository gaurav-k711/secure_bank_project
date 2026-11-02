
import os
from pathlib import Path
from contextlib import contextmanager

import oracledb
from dotenv import load_dotenv

# Load environment variables from project root
PROJECT_ROOT = Path(__file__).resolve().parent.parent
load_dotenv(PROJECT_ROOT / ".env")

DB_USER = os.getenv("ORACLE_USER")
DB_PASSWORD = os.getenv("ORACLE_PASSWORD")
DB_DSN = os.getenv("ORACLE_DSN")


def get_connection():
    """Connect to Oracle FreeSQL database."""
    if not DB_USER or not DB_PASSWORD or not DB_DSN:
        raise RuntimeError(
            "Missing Oracle credentials. Check ORACLE_USER, "
            "ORACLE_PASSWORD and ORACLE_DSN in your .env file."
        )

    try:
        return oracledb.connect(
            user=DB_USER,
            password=DB_PASSWORD,
            dsn=DB_DSN
        )
    except Exception as e:
        raise ConnectionError(f"Oracle connection failed: {e}") from e


@contextmanager
def get_db():
    """Provide a database connection and cursor."""
    conn = get_connection()
    cur = conn.cursor()

    try:
        yield conn, cur
        conn.commit()
    except Exception:
        conn.rollback()
        raise
    finally:
        cur.close()
        conn.close()


def execute_query(sql: str, params: dict = None, fetch_one: bool = False):
    """Execute SELECT queries."""
    params = params or {}

    with get_db() as (conn, cur):
        cur.execute(sql, params)

        columns = [
            col[0].lower() for col in cur.description
        ] if cur.description else []

        if fetch_one:
            row = cur.fetchone()
            return dict(zip(columns, row)) if row else None

        rows = cur.fetchall()
        return [dict(zip(columns, row)) for row in rows]


def execute_non_query(sql: str, params: dict = None):
    """Execute INSERT, UPDATE and DELETE queries."""
    params = params or {}

    with get_db() as (conn, cur):
        cur.execute(sql, params)
        return cur.rowcount


def call_procedure(proc_name: str, params: list = None):
    """Execute an Oracle PL/SQL stored procedure."""
    params = params or []

    with get_db() as (conn, cur):
        return cur.callproc(proc_name, params)


def test_connection():
    """Check whether Oracle database connection is working."""
    try:
        result = execute_query(
            """
            SELECT 1 AS status,
                   TO_CHAR(SYSDATE, 'YYYY-MM-DD HH24:MI:SS') AS db_time
            FROM DUAL
            """,
            fetch_one=True
        )
        return True, result
    except Exception as e:
        return False, str(e)

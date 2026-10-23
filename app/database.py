"""
Database connection and query abstraction module for SecureBank.
Supports cx_Oracle (primary for Oracle 11g XE) and python-oracledb.
"""

import os
from pathlib import Path
from contextlib import contextmanager
from dotenv import load_dotenv

# Load environment variables
dotenv_path = Path(__file__).resolve().parent.parent / ".env"
load_dotenv(dotenv_path=dotenv_path)

DB_USER = os.getenv("ORACLE_USER", "securebank")
DB_PASSWORD = os.getenv("ORACLE_PASSWORD", "securebank")
DB_DSN = os.getenv("ORACLE_DSN", "127.0.0.1:1521/XE")
ORACLE_CLIENT_DIR = os.getenv("ORACLE_CLIENT_DIR", r"C:\oraclexe\app\oracle\product\11.2.0\server\bin")

driver_type = None

# Attempt to initialize cx_Oracle (native 11g client support)
try:
    import cx_Oracle
    if os.path.exists(ORACLE_CLIENT_DIR):
        try:
            cx_Oracle.init_oracle_client(lib_dir=ORACLE_CLIENT_DIR)
        except Exception:
            pass  # Already initialized
    driver_type = "cx_Oracle"
    db_module = cx_Oracle
except Exception:
    try:
        import oracledb
        driver_type = "oracledb"
        db_module = oracledb
    except Exception as e:
        raise RuntimeError(f"Neither cx_Oracle nor oracledb could be imported: {e}")


def get_connection():
    """Establish and return a connection to the Oracle database."""
    try:
        if driver_type == "cx_Oracle":
            conn = db_module.connect(user=DB_USER, password=DB_PASSWORD, dsn=DB_DSN)
        else:
            conn = db_module.connect(user=DB_USER, password=DB_PASSWORD, dsn=DB_DSN)
        return conn
    except Exception as e:
        raise ConnectionError(f"Failed to connect to Oracle Database at {DB_DSN} as {DB_USER}: {e}")


@contextmanager
def get_db():
    """Context manager yielding (connection, cursor) with automatic commit and rollback."""
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
    """
    Execute a SELECT statement and return results as list of dicts or single dict.
    Column names in dictionaries are lower-cased.
    """
    params = params or {}
    with get_db() as (conn, cur):
        cur.execute(sql, params)
        columns = [col[0].lower() for col in cur.description] if cur.description else []
        
        if fetch_one:
            row = cur.fetchone()
            if not row:
                return None
            return dict(zip(columns, row))
        else:
            rows = cur.fetchall()
            return [dict(zip(columns, row)) for row in rows]


def execute_non_query(sql: str, params: dict = None):
    """Execute an INSERT, UPDATE, or DELETE SQL statement."""
    params = params or {}
    with get_db() as (conn, cur):
        cur.execute(sql, params)
        rowcount = cur.rowcount
        return rowcount


def call_procedure(proc_name: str, params: list = None):
    """Execute a PL/SQL stored procedure by name."""
    params = params or []
    with get_db() as (conn, cur):
        res = cur.callproc(proc_name, params)
        return res


def test_connection():
    """Utility function to test database connectivity."""
    try:
        row = execute_query("SELECT 1 AS status, TO_CHAR(SYSDATE, 'YYYY-MM-DD HH24:MI:SS') AS db_time FROM DUAL", fetch_one=True)
        return True, row
    except Exception as e:
        return False, str(e)


from app.database import get_connection

conn = None
cur = None

try:
    conn = get_connection()
    cur = conn.cursor()

    cur.execute("""
        SELECT
            USER AS DB_USER,
            SYS_CONTEXT('USERENV', 'DB_NAME') AS DB_NAME,
            SYS_CONTEXT('USERENV', 'SERVICE_NAME') AS SERVICE_NAME,
            SYS_CONTEXT('USERENV', 'SERVER_HOST') AS SERVER_HOST
        FROM DUAL
    """)

    row = cur.fetchone()

    print("\n========== ORACLE CONNECTION DETAILS ==========")
    print("Connection Status : SUCCESS")
    print("Database User     :", row[0])
    print("Database Name     :", row[1])
    print("Service Name      :", row[2])
    print("Server Host       :", row[3])
    print("================================================")

except Exception as e:
    print("\nCONNECTION FAILED")
    print("Error:", e)

finally:
    if cur:
        cur.close()
    if conn:
        conn.close()

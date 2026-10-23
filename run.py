"""
SecureBank - Application Launcher
Runs the FastAPI web server using Uvicorn.
"""

import os
import sys
from pathlib import Path

# Add project root to sys.path
PROJECT_ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(PROJECT_ROOT))

import uvicorn
from dotenv import load_dotenv

load_dotenv(Path(__file__).resolve().parent / ".env")

if __name__ == "__main__":
    host = os.getenv("APP_HOST", "127.0.0.1")
    port = int(os.getenv("APP_PORT", 8000))
    print("=" * 60)
    print("  SECUREBANK — Smart Banking Management System")
    print(f"  Starting web server at http://{host}:{port}")
    print("=" * 60)
    uvicorn.run("securebank.app.main:app", host=host, port=port, reload=False)

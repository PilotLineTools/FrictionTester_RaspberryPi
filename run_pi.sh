#!/bin/bash
set -e
cd "$(dirname "$0")"

export QT_QPA_PLATFORM=eglfs
export QT_QPA_EGLFS_HIDECURSOR=1

# same paths you used before
export QML_IMPORT_PATH="$PWD/imports:$PWD/content:$PWD/qmlmodules:$PWD"

# ---- Backend (FastAPI) ----
# Use project venv if present
if [ -f "$PWD/.venv/bin/activate" ]; then
  source "$PWD/.venv/bin/activate"
fi

BACKEND_LOG="$PWD/backend.log"

# Kill anything already using 8080 (optional but practical on reboot/relaunch)
fuser -k 8080/tcp >/dev/null 2>&1 || true

# Start backend in background
nohup python -m uvicorn backend.api:app --host 0.0.0.0 --port 8080 > "$BACKEND_LOG" 2>&1 &

# Give it a moment
sleep 1

# Optional quick check (won’t spam output)
if ! curl -s http://127.0.0.1:8080/protocols >/dev/null 2>&1; then
  echo "❌ Backend didn't start. Last 40 lines of log:"
  tail -n 40 "$BACKEND_LOG" || true
  exit 1
fi

# ---- UI ----
exec python3 "$PWD/main.py"

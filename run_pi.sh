#!/bin/bash
set -e
cd "$(dirname "$0")"

export QT_QPA_PLATFORM=eglfs
export QT_QPA_EGLFS_HIDECURSOR=1
export QML_IMPORT_PATH="$PWD/imports:$PWD/content:$PWD/qmlmodules:$PWD"

# ---- Backend ----
if [ -f "$PWD/.venv/bin/activate" ]; then
  source "$PWD/.venv/bin/activate"
fi

# ✅ ensure logs dir exists
mkdir -p "$PWD/logs"
BACKEND_LOG="$PWD/logs/backend.log"

# ✅ kill anything already using 8080
PID=$(ss -ltnp 2>/dev/null | awk '/:8080/ {print $NF}' | sed -n 's/.*pid=\([0-9]\+\).*/\1/p' | head -n 1)
if [ -n "$PID" ]; then
  echo "▶ Killing process on 8080 (pid=$PID)"
  kill -9 "$PID" 2>/dev/null || true
fi

sleep 0.3

# start backend
nohup python -m uvicorn backend.api:app \
  --host 127.0.0.1 \
  --port 8080 \
  > "$BACKEND_LOG" 2>&1 &

sleep 0.7

# health check
if ! curl -s http://127.0.0.1:8080/health >/dev/null 2>&1; then
  echo "❌ Backend didn't start. Last 120 lines:"
  tail -n 120 "$BACKEND_LOG" || true
  exit 1
fi

echo "✅ Backend OK"

# ---- UI ----
exec python3 "$PWD/main.py"

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

BACKEND_LOG="$PWD/backend.log"

# kill old server if it's already running
fuser -k 8080/tcp >/dev/null 2>&1 || true

# start backend
nohup python -m uvicorn backend.api:app \
  --host 127.0.0.1 \
  --port 8080 \
  > "$BACKEND_LOG" 2>&1 &

sleep 0.7

# health check
if ! curl -s http://127.0.0.1:8080/health >/dev/null 2>&1; then
  echo "❌ Backend didn't start. Last 80 lines:"
  tail -n 80 "$BACKEND_LOG" || true
  exit 1
fi

echo "✅ Backend OK"

# ---- UI ----
exec python3 "$PWD/main.py"

#!/bin/bash
set -e
cd "$(dirname "$0")"

export QT_QPA_PLATFORM=eglfs
export QT_QPA_EGLFS_HIDECURSOR=1

# same paths you used before
export QML_IMPORT_PATH="$PWD/imports:$PWD/content:$PWD/qmlmodules:$PWD"

exec python3 "$PWD/main.py"

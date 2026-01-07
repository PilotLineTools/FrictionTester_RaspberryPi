#!/bin/bash
set -e

cd "$(dirname "$0")"

export QML_IMPORT_PATH="$PWD/imports:$PWD/content:$PWD/qmlmodules:$PWD"

exec /usr/lib/qt6/bin/qmlscene -platform eglfs content/App.qml

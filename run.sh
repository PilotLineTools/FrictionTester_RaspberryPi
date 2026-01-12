#!/bin/bash
set -e

cd "$(dirname "$0")"

# Binary name
BINARY_NAME="PilotLine_FrictionTesterApp"

# Common build directory locations (check in order)
BUILD_DIRS=(
    "build/Qt_6_10_1_for_macOS-Debug"
    "build/Qt_6_10_1_for_macOS-Release"
    "build/Debug"
    "build/Release"
    "build"
    "."
)

# Find the binary
BINARY_PATH=""
for dir in "${BUILD_DIRS[@]}"; do
    if [ -f "$dir/$BINARY_NAME" ] && [ -x "$dir/$BINARY_NAME" ]; then
        BINARY_PATH="$dir/$BINARY_NAME"
        break
    fi
done

# If binary found, run it
if [ -n "$BINARY_PATH" ]; then
    echo "Found compiled application: $BINARY_PATH"
    echo "Running C++ application (with Uart support)..."
    exec "$BINARY_PATH" "$@"
else
    echo "Warning: Compiled binary '$BINARY_NAME' not found in any build directory."
    echo "Attempted locations:"
    for dir in "${BUILD_DIRS[@]}"; do
        echo "  - $dir/$BINARY_NAME"
    done
    echo ""
    echo "Falling back to qmlscene (Uart context property will NOT be available)."
    echo "To build the application, run:"
    echo "  mkdir -p build && cd build"
    echo "  cmake .."
    echo "  make"
    echo ""
    
    export QML_IMPORT_PATH="$PWD/imports:$PWD/content:$PWD/qmlmodules:$PWD"
    
    # Try to find qmlscene
    if command -v qmlscene &> /dev/null; then
        exec qmlscene -platform eglfs content/App.qml "$@"
    elif [ -f "/usr/lib/qt6/bin/qmlscene" ]; then
        exec /usr/lib/qt6/bin/qmlscene -platform eglfs content/App.qml "$@"
    else
        echo "Error: qmlscene not found. Please build the application first."
        exit 1
    fi
fi

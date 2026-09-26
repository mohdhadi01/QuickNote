#!/bin/bash
# Quick local debug run: incremental Debug build + launch in foreground
# with optional log streaming and QA-flag passthrough.
#
# Usage: Scripts/dev.sh [--logs] [launch arguments...]
#   Scripts/dev.sh
#   Scripts/dev.sh -quicknote.debugShowCapture
#   Scripts/dev.sh -quicknote.forceOnboarding -quicknote.inMemoryStore 1
#   Scripts/dev.sh --logs -quicknote.seedNote "Hello from dev"
set -euo pipefail

# Absolute repo root (no ".." components — sandbox/path-resolution safe).
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
cd "$REPO_ROOT"

LOGS=0
ARGS=()
for arg in "$@"; do
    if [ "$arg" = "--logs" ]; then
        LOGS=1
    else
        ARGS+=("$arg")
    fi
done

echo "→ Building (Debug, incremental)"
xcodebuild -project QuickNote.xcodeproj -scheme QuickNote \
    -configuration Debug -destination 'platform=macOS' build -quiet

APP=$(ls -d "$HOME/Library/Developer/Xcode/DerivedData/QuickNote-"*/Build/Products/Debug/QuickNote.app 2>/dev/null | head -1)
if [ -z "$APP" ]; then
    echo "Debug build not found" >&2
    exit 1
fi

pkill -f QuickNote.app 2>/dev/null || true
sleep 0.5

if [ "$LOGS" -eq 1 ]; then
    echo "→ Running with logs (Ctrl+C stops the app and the log stream)"
    log stream --predicate 'process == "QuickNote"' --level debug > /tmp/quicknote-logs.txt 2>&1 &
    LOG_PID=$!
    trap 'kill $LOG_PID 2>/dev/null || true' EXIT
    "$APP/Contents/MacOS/QuickNote" "${ARGS[@]:-}" &
    APP_PID=$!
    echo "   app pid $APP_PID · logs: tail -f /tmp/quicknote-logs.txt"
    wait $APP_PID
else
    echo "→ Running in background (stdout in this terminal)${ARGS[*]:+ · args: ${ARGS[*]}}"
    "$APP/Contents/MacOS/QuickNote" "${ARGS[@]:-}" &
    disown
    echo "✓ QuickNote (Debug) launched"
fi

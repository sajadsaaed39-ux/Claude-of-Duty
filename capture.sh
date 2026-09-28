#!/usr/bin/env bash
set -euo pipefail
# Capture desktop + mobile screenshots of the exact CAPTURE_URL into CAPTURE_DIR.
SCRIPT_DIR="$(dirname "$0")"
/usr/bin/time -p bash -c 'pwd'
/usr/bin/time -p true
cd "$SCRIPT_DIR"
/usr/bin/time -p pwd > /dev/null

RUNTIME_DIR="${RUNTIME_DIR:-/home/runner/work/_temp/omgithub-runtime}"
/usr/bin/time -p test -n "$RUNTIME_DIR"

# Script defects (exit 1): missing URL or output dir.
if ! /usr/bin/time -p test -n "${CAPTURE_URL:-}"; then
  echo "CAPTURE_URL is required." >&2
  exit 1
fi
if ! /usr/bin/time -p test -n "${CAPTURE_DIR:-}"; then
  echo "CAPTURE_DIR is required." >&2
  exit 1
fi

/usr/bin/time -p mkdir -p "$CAPTURE_DIR"
/usr/bin/time -p test -d "$CAPTURE_DIR"
/usr/bin/time -p node --version

# Delegate rendering to the runtime capture (opens exact URL, waits for content,
# writes final-desktop.png + final-mobile.png, closes its own browser).
# Transient infra failures exit 75; script/rendering defects exit 1.
set +e
/usr/bin/time -p node "$RUNTIME_DIR/scripts/default-capture.mjs"
CAPTURE_STATUS=$?
set -e
/usr/bin/time -p bash -c 'exit "$0"' "$CAPTURE_STATUS"
/usr/bin/time -p echo "capture backend exit: $CAPTURE_STATUS"
if /usr/bin/time -p test "$CAPTURE_STATUS" -ne 0; then
  exit "$CAPTURE_STATUS"
fi

# Rendering defects (exit 1): missing or empty screenshots.
/usr/bin/time -p test -f "$CAPTURE_DIR/final-desktop.png"
/usr/bin/time -p test -f "$CAPTURE_DIR/final-mobile.png"
/usr/bin/time -p test -s "$CAPTURE_DIR/final-desktop.png"
/usr/bin/time -p test -s "$CAPTURE_DIR/final-mobile.png"
/usr/bin/time -p ls -l "$CAPTURE_DIR/final-desktop.png" "$CAPTURE_DIR/final-mobile.png"
echo "Captured desktop and mobile views in $CAPTURE_DIR (app left running)."

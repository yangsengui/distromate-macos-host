#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
OUT="${1:-$SCRIPT_DIR/mac_squirrel_agent}"
FRAMEWORK_DIR="${SQUIRREL_FRAMEWORK_DIR:-/Library/Frameworks}"
REACTIVE_FRAMEWORK="${REACTIVE_FRAMEWORK:-ReactiveObjC}"

clang -fobjc-arc -ObjC "$SCRIPT_DIR/mac_squirrel_agent.m" \
  -F"$FRAMEWORK_DIR" \
  -framework Foundation \
  -framework Squirrel \
  -framework "$REACTIVE_FRAMEWORK" \
  -framework Mantle \
  -o "$OUT"

echo "built: $OUT"

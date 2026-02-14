#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
OUT="${1:-$SCRIPT_DIR/mac_squirrel_agent}"
FRAMEWORK_DIR="${SQUIRREL_FRAMEWORK_DIR:-/Library/Frameworks}"
REACTIVE_FRAMEWORK="${REACTIVE_FRAMEWORK:-ReactiveObjC}"
TARGET_ARCH="${MAC_SQUIRREL_AGENT_ARCH:-}"

ARCH_FLAGS=()
if [[ -n "$TARGET_ARCH" ]]; then
  ARCH_FLAGS=(-arch "$TARGET_ARCH")
fi

RPATH_FLAGS=(
  -Wl,-rpath,@executable_path/Frameworks
  -Wl,-rpath,@loader_path/Frameworks
  -Wl,-rpath,@executable_path/../Frameworks
  -Wl,-rpath,@loader_path/../Frameworks
  -Wl,-rpath,/Library/Frameworks
)

clang "${ARCH_FLAGS[@]}" -fobjc-arc -ObjC "$SCRIPT_DIR/mac_squirrel_agent.m" \
  -F"$FRAMEWORK_DIR" \
  -framework Foundation \
  -framework Squirrel \
  -framework "$REACTIVE_FRAMEWORK" \
  -framework Mantle \
  "${RPATH_FLAGS[@]}" \
  -o "$OUT"

echo "built: $OUT"

#!/bin/sh
#
# Shared Godot binary resolution logic.
# Source this from other scripts: . "$(dirname "$0")/resolve_godot.sh"
#
# Sets $GODOT to the resolved binary path, or "" if not found.
# Resolution order: .gdenv file > GODOT_BIN env var > 'godot' in PATH
#
# Expects $PROJECT_ROOT to be set by the calling script.

GODOT=""
if [ -f "$PROJECT_ROOT/.gdenv" ]; then
  GODOT=$(grep "^GODOT_BIN=" "$PROJECT_ROOT/.gdenv" | cut -d= -f2 | tr -d '"' | tr -d "'")
fi
if [ -z "$GODOT" ] && [ -n "${GODOT_BIN:-}" ]; then
  GODOT="$GODOT_BIN"
fi
if [ -z "$GODOT" ] && command -v godot > /dev/null 2>&1; then
  GODOT="godot"
fi

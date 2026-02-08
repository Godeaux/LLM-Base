#!/bin/sh
#
# Godot project validation script.
# Runs gdlint, gdformat --check, and headless Godot to catch errors.
#
# Usage:
#   ./scripts/godot_validate.sh           # Validate all .gd files
#   ./scripts/godot_validate.sh --lint    # Only run linting (gdlint + gdformat)
#   ./scripts/godot_validate.sh --headless # Only run headless Godot check
#
# Exit codes:
#   0 = all checks passed
#   1 = one or more checks failed

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$PROJECT_ROOT"

# Colors (only if terminal supports it)
if [ -t 1 ]; then
  RED='\033[0;31m'
  GREEN='\033[0;32m'
  YELLOW='\033[1;33m'
  NC='\033[0m'
else
  RED=''
  GREEN=''
  YELLOW=''
  NC=''
fi

FAILED=0
RUN_LINT=true
RUN_HEADLESS=true

# Parse arguments
case "${1:-}" in
  --lint)
    RUN_HEADLESS=false
    ;;
  --headless)
    RUN_LINT=false
    ;;
esac

# Find all .gd files (skip .godot-template/ and .godot/ cache)
GD_FILES=$(find . -name "*.gd" -not -path "./.godot-template/*" -not -path "./.godot/*" 2>/dev/null || true)

if [ -z "$GD_FILES" ]; then
  echo "${YELLOW}No GDScript files found. Skipping validation.${NC}"
  exit 0
fi

# --- Lint check ---
if [ "$RUN_LINT" = true ]; then
  echo "=== Running gdlint ==="
  if ! command -v gdlint > /dev/null 2>&1; then
    echo "${RED}ERROR: gdlint is not installed.${NC}"
    echo "Install it with: pip install gdtoolkit"
    echo "This is required — the project enforces linting on every commit."
    exit 1
  fi

  if echo "$GD_FILES" | xargs gdlint; then
    echo "${GREEN}gdlint passed.${NC}"
  else
    echo "${RED}gdlint failed.${NC}"
    FAILED=1
  fi

  echo ""
  echo "=== Running gdformat --check ==="
  if echo "$GD_FILES" | xargs gdformat --check; then
    echo "${GREEN}gdformat check passed.${NC}"
  else
    echo "${RED}gdformat check failed. Run 'gdformat .' to fix.${NC}"
    FAILED=1
  fi
fi

# --- Headless Godot check ---
if [ "$RUN_HEADLESS" = true ]; then
  echo ""
  echo "=== Running headless Godot validation ==="

  if ! [ -f "project.godot" ]; then
    echo "${YELLOW}No project.godot found. Skipping headless check.${NC}"
  elif ! command -v godot > /dev/null 2>&1; then
    echo "${YELLOW}WARNING: 'godot' binary not found in PATH.${NC}"
    echo "Headless validation skipped locally. CI will still enforce this."
    echo "To enable locally, add Godot to your PATH."
  else
    # Run Godot headless — loads project, parses all scripts, then quits.
    # Timeout after 30 seconds to prevent hangs.
    # Capture stderr where Godot reports errors.
    GODOT_OUTPUT=$(timeout 30 godot --headless --quit 2>&1 || true)
    GODOT_EXIT=$?

    # Check for error patterns in Godot output
    if echo "$GODOT_OUTPUT" | grep -qi "error\|SCRIPT ERROR\|Parse Error\|Cannot"; then
      echo "${RED}Headless Godot reported errors:${NC}"
      echo "$GODOT_OUTPUT" | grep -i "error\|SCRIPT ERROR\|Parse Error\|Cannot"
      FAILED=1
    elif [ "$GODOT_EXIT" -ne 0 ] && [ "$GODOT_EXIT" -ne 124 ]; then
      echo "${RED}Godot exited with code $GODOT_EXIT${NC}"
      echo "$GODOT_OUTPUT"
      FAILED=1
    else
      echo "${GREEN}Headless Godot check passed.${NC}"
    fi
  fi
fi

# --- Summary ---
echo ""
if [ "$FAILED" -ne 0 ]; then
  echo "${RED}=== VALIDATION FAILED ===${NC}"
  exit 1
else
  echo "${GREEN}=== ALL CHECKS PASSED ===${NC}"
  exit 0
fi

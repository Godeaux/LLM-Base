#!/bin/sh
#
# Godot project validation script.
# Runs gdlint, gdformat --check, and headless Godot to catch errors.
#
# Usage:
#   ./scripts/godot_validate.sh            # Validate all .gd files (lint + headless)
#   ./scripts/godot_validate.sh --lint     # Only run linting (gdlint + gdformat)
#   ./scripts/godot_validate.sh --headless # Only run headless Godot check
#   ./scripts/godot_validate.sh --all      # Lint + headless + GdUnit4 tests
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
RUN_TESTS=false

# Parse arguments
case "${1:-}" in
  --lint)
    RUN_HEADLESS=false
    ;;
  --headless)
    RUN_LINT=false
    ;;
  --all)
    RUN_TESTS=true
    ;;
esac

# Resolve Godot binary (shared logic)
. "$SCRIPT_DIR/resolve_godot.sh"

# Find all .gd files (skip .godot-template/, .godot/ cache, and addons/)
GD_FILES=$(find . -name "*.gd" -not -path "./.godot-template/*" -not -path "./.godot/*" -not -path "./addons/*" 2>/dev/null || true)

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
  elif [ -z "$GODOT" ]; then
    echo "${YELLOW}WARNING: Godot binary not found.${NC}"
    echo "Headless validation skipped. To enable it, create a .gdenv file:"
    echo "  echo 'GODOT_BIN=\"/path/to/godot\"' > .gdenv"
    echo "Or add 'godot' to your PATH. CI will still enforce this."
  else
    echo "Using Godot binary: $GODOT"
    # Run Godot headless — loads project, parses all scripts, then quits.
    # Timeout after 30 seconds to prevent hangs.
    # Capture stderr where Godot reports errors.
    GODOT_OUTPUT=$(timeout 30 "$GODOT" --headless --quit 2>&1) && GODOT_EXIT=0 || GODOT_EXIT=$?

    # Check for error patterns in Godot output
    if echo "$GODOT_OUTPUT" | grep -qE "SCRIPT ERROR|Parse Error|Cannot load source code|Failed loading resource"; then
      echo "${RED}Headless Godot reported errors:${NC}"
      echo "$GODOT_OUTPUT" | grep -E "SCRIPT ERROR|Parse Error|Cannot load source code|Failed loading resource"
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

# --- GdUnit4 tests (only with --all flag) ---
if [ "$RUN_TESTS" = true ]; then
  echo ""
  echo "=== Running GdUnit4 tests ==="

  if [ ! -d "addons/gdunit4" ]; then
    echo "${YELLOW}GdUnit4 not found at addons/gdunit4/. Skipping tests.${NC}"
    echo "Run: git submodule update --init --recursive"
  elif [ ! -d "tests" ]; then
    echo "${YELLOW}No tests/ directory found. Skipping tests.${NC}"
  elif [ -z "$GODOT" ]; then
    echo "${YELLOW}WARNING: Godot binary not found. Cannot run tests.${NC}"
  else
    if timeout 120 "$GODOT" --headless -s addons/gdunit4/bin/GdUnitCmdTool.gd --add "res://tests" --run-tests 2>&1; then
      echo "${GREEN}GdUnit4 tests passed.${NC}"
    else
      echo "${RED}GdUnit4 tests failed.${NC}"
      FAILED=1
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

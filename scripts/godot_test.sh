#!/bin/sh
#
# GdUnit4 test runner for Godot projects.
# Runs all tests in the tests/ directory using GdUnit4 headless.
#
# Usage:
#   ./scripts/godot_test.sh              # Run all tests
#   ./scripts/godot_test.sh res://tests/test_health.gd  # Run specific test
#
# Exit codes:
#   0 = all tests passed
#   1 = one or more tests failed or setup error

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

# Check for GdUnit4 addon
if [ ! -d "addons/gdunit4" ]; then
  echo "${RED}ERROR: GdUnit4 not found at addons/gdunit4/${NC}"
  echo ""
  echo "If you cloned without --recurse-submodules, run:"
  echo "  git submodule update --init --recursive"
  echo ""
  echo "If GdUnit4 was never added, run:"
  echo "  git submodule add https://github.com/MikeSchulze/gdUnit4.git addons/gdunit4"
  exit 1
fi

# Check for GdUnit4 command tool
if [ ! -f "addons/gdunit4/bin/GdUnitCmdTool.gd" ]; then
  echo "${RED}ERROR: GdUnit4 command tool not found.${NC}"
  echo "The addons/gdunit4/ directory exists but appears incomplete."
  echo "Try: git submodule update --init --recursive"
  exit 1
fi

# Resolve Godot binary (shared logic)
. "$SCRIPT_DIR/resolve_godot.sh"

if [ -z "$GODOT" ]; then
  echo "${YELLOW}WARNING: Godot binary not found.${NC}"
  echo "Cannot run tests without Godot. To configure:"
  echo "  echo 'GODOT_BIN=\"/path/to/godot\"' > .gdenv"
  echo "Or add 'godot' to your PATH."
  exit 1
fi

# Check for test files
TEST_DIR="${1:-res://tests}"
if [ "$TEST_DIR" = "res://tests" ] && [ ! -d "tests" ]; then
  echo "${YELLOW}No tests/ directory found. Skipping tests.${NC}"
  exit 0
fi

echo "=== Running GdUnit4 tests ==="
echo "Using Godot binary: $GODOT"
echo "Test directory: $TEST_DIR"
echo ""

# Run GdUnit4 headless
# --add: directory to scan for test suites
# Timeout after 120 seconds to prevent hangs on stuck tests
timeout 120 "$GODOT" --headless -s addons/gdunit4/bin/GdUnitCmdTool.gd --add "$TEST_DIR" --run-tests 2>&1
EXIT_CODE=$?

echo ""
if [ "$EXIT_CODE" -eq 0 ]; then
  echo "${GREEN}=== ALL TESTS PASSED ===${NC}"
else
  echo "${RED}=== TESTS FAILED (exit code: $EXIT_CODE) ===${NC}"
fi

exit $EXIT_CODE

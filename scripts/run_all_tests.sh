#!/bin/bash
################################################################################
# Run All Tests - Local Convenience Script
################################################################################
#
# PURPOSE:
#   Runs all Verilog testbenches locally before pushing to GitHub.
#   This is a convenience wrapper around run_test.sh that tests all
#   testbenches sequentially and provides a summary.
#
# USAGE:
#   ./run_all_tests.sh
#
# WHAT IT DOES:
#   1. Runs each testbench one at a time
#   2. Tracks which tests pass and which fail
#   3. Prints a summary at the end
#   4. Returns exit code 0 if all pass, 1 if any fail
#
# USE CASES:
#   - Pre-commit testing to ensure your changes don't break anything
#   - Local debugging before creating a pull request
#   - Quick validation after making changes
#
################################################################################

# Get script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Define all testbenches (same as in GitHub Actions)
TESTBENCHES=(
    "ualink_turbo64_tb"
    "ualink_turbordwr_tb"
    "ualink_dpmem_tb"
)

# Track results
PASSED=()
FAILED=()
TOTAL=${#TESTBENCHES[@]}

echo "============================================================"
echo "Running All Verilog Testbenches"
echo "============================================================"
echo "Total testbenches: $TOTAL"
echo ""

# Run each testbench
for i in "${!TESTBENCHES[@]}"; do
    TB="${TESTBENCHES[$i]}"
    NUM=$((i + 1))

    echo ""
    echo "------------------------------------------------------------"
    echo "[$NUM/$TOTAL] Testing: $TB"
    echo "------------------------------------------------------------"

    # Run the test
    if "$SCRIPT_DIR/run_test.sh" "$TB"; then
        PASSED+=("$TB")
        echo "✓ PASSED: $TB"
    else
        FAILED+=("$TB")
        echo "✗ FAILED: $TB"
    fi
done

# Print summary
echo ""
echo "============================================================"
echo "SUMMARY"
echo "============================================================"
echo "Total:  $TOTAL"
echo "Passed: ${#PASSED[@]}"
echo "Failed: ${#FAILED[@]}"
echo ""

# Show which tests passed
if [ ${#PASSED[@]} -gt 0 ]; then
    echo "✓ PASSED TESTS:"
    for tb in "${PASSED[@]}"; do
        echo "  - $tb"
    done
    echo ""
fi

# Show which tests failed
if [ ${#FAILED[@]} -gt 0 ]; then
    echo "✗ FAILED TESTS:"
    for tb in "${FAILED[@]}"; do
        echo "  - $tb"
    done
    echo ""
fi

# Final verdict
echo "============================================================"
if [ ${#FAILED[@]} -eq 0 ]; then
    echo "✓ ALL TESTS PASSED!"
    echo "============================================================"
    exit 0
else
    echo "✗ SOME TESTS FAILED"
    echo "============================================================"
    echo ""
    echo "Tips for debugging:"
    echo "  1. Check the log files in the testbench directories"
    echo "  2. Open waveforms with: gtkwave <testbench>.vcd"
    echo "  3. Review error messages above"
    exit 1
fi

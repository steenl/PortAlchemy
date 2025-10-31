#!/usr/bin/env python3
################################################################################
# Result Parser Script for Verilog Simulation Logs
################################################################################
#
# PURPOSE:
#   Analyzes Verilog simulation log files to determine pass/fail status.
#   Verilog simulations don't always have explicit pass/fail indicators,
#   so this script looks for error patterns and completion signals.
#
# USAGE:
#   python3 parse_results.py <log_file_path>
#
#   Example: python3 parse_results.py ualink_turbo64_tb.log
#
# EXIT CODES:
#   0 = Test passed (no errors, simulation completed)
#   1 = Test failed (errors found OR simulation incomplete)
#
# OUTPUT:
#   Prints a formatted summary showing:
#   - Errors found (with line numbers)
#   - Warnings found (informational only)
#   - Pass/Fail determination
#
################################################################################

import sys
import re
from pathlib import Path


################################################################################
# Detection Patterns
################################################################################

# Critical patterns that indicate test failure
ERROR_PATTERNS = [
    re.compile(r'ERROR', re.IGNORECASE),
    re.compile(r'\bFAIL\b', re.IGNORECASE),
    re.compile(r'FATAL', re.IGNORECASE),
    re.compile(r'timeout', re.IGNORECASE),
    re.compile(r'SIMULATION.*FAILED', re.IGNORECASE),
    re.compile(r'syntax error', re.IGNORECASE),
    re.compile(r'cannot open', re.IGNORECASE),
    re.compile(r'undefined', re.IGNORECASE),
    re.compile(r'assertion.*failed', re.IGNORECASE),
    re.compile(r'mismatch', re.IGNORECASE),
]

# Warning patterns (informational - do not cause failure)
WARNING_PATTERNS = [
    re.compile(r'WARNING', re.IGNORECASE),
    re.compile(r'CAUTION', re.IGNORECASE),
]

# Success patterns (indicate simulation completed normally)
SUCCESS_PATTERNS = [
    re.compile(r'All tests completed', re.IGNORECASE),
    re.compile(r'Test.*PASSED', re.IGNORECASE),
    re.compile(r'PASSED', re.IGNORECASE),
    re.compile(r'\$finish called'),
    re.compile(r'completed successfully', re.IGNORECASE),
]

# Patterns to ignore (false positives)
IGNORE_PATTERNS = [
    re.compile(r'^\s*//'),                              # Comments
    re.compile(r'^\s*#'),                               # Comments
    re.compile(r'No errors', re.IGNORECASE),            # "No errors" is good
    re.compile(r'error.*expected', re.IGNORECASE),      # Intentional errors in tests
]


################################################################################
# Helper Functions
################################################################################

def should_ignore_line(line):
    """Check if a line should be ignored (is a false positive)"""
    for pattern in IGNORE_PATTERNS:
        if pattern.search(line):
            return True
    return False


def check_for_errors(lines):
    """
    Scan log lines for error patterns.
    Returns: list of (line_number, line_text) tuples for errors found
    """
    errors = []
    for i, line in enumerate(lines, start=1):
        if should_ignore_line(line):
            continue

        for pattern in ERROR_PATTERNS:
            if pattern.search(line):
                errors.append((i, line.strip()))
                break  # Only count each line once

    return errors


def check_for_warnings(lines):
    """
    Scan log lines for warning patterns.
    Returns: list of (line_number, line_text) tuples for warnings found
    """
    warnings = []
    for i, line in enumerate(lines, start=1):
        if should_ignore_line(line):
            continue

        for pattern in WARNING_PATTERNS:
            if pattern.search(line):
                warnings.append((i, line.strip()))
                break  # Only count each line once

    return warnings


def check_for_completion(log_text):
    """
    Check if simulation completed successfully.
    Returns: True if any success pattern is found in the entire log
    """
    for pattern in SUCCESS_PATTERNS:
        if pattern.search(log_text):
            return True
    return False


def print_summary(log_file, errors, warnings, completed):
    """Print a formatted summary of the analysis"""
    separator = "=" * 60

    print(separator)
    print(f"Analyzing: {log_file}")
    print(separator)
    print()

    # Report errors
    if errors:
        print(f"✗ ERRORS FOUND: {len(errors)}")
        for line_num, line_text in errors:
            print(f"  Line {line_num}: {line_text}")
        print()
    else:
        print("✓ No errors detected")

    # Report warnings (informational only)
    if warnings:
        print(f"⚠ WARNINGS: {len(warnings)}")
        for line_num, line_text in warnings[:5]:  # Limit to first 5 warnings
            print(f"  Line {line_num}: {line_text}")
        if len(warnings) > 5:
            print(f"  ... and {len(warnings) - 5} more warnings")
        print()

    # Report completion status
    if not errors:
        if completed:
            print("✓ Simulation completed normally")
        else:
            print("✗ Simulation did not reach completion")
            print("  (No $finish or success message found)")
        print()

    # Final verdict
    if errors:
        print("RESULT: FAILED")
    elif not completed:
        print("RESULT: FAILED (incomplete)")
    else:
        print("RESULT: PASSED")

    print(separator)


################################################################################
# Main Analysis Logic
################################################################################

def analyze_log(log_file_path):
    """
    Main function to analyze a simulation log file.
    Returns: 0 if passed, 1 if failed
    """
    # Validate input
    log_path = Path(log_file_path)
    if not log_path.exists():
        print(f"ERROR: Log file not found: {log_file_path}")
        return 1

    if not log_path.is_file():
        print(f"ERROR: Not a file: {log_file_path}")
        return 1

    # Read log file
    try:
        with open(log_path, 'r', encoding='utf-8', errors='replace') as f:
            log_text = f.read()
            lines = log_text.split('\n')
    except Exception as e:
        print(f"ERROR: Failed to read log file: {e}")
        return 1

    # Check if log file is empty
    if not log_text.strip():
        print(f"ERROR: Log file is empty: {log_file_path}")
        return 1

    # Analyze the log
    errors = check_for_errors(lines)
    warnings = check_for_warnings(lines)
    completed = check_for_completion(log_text)

    # Print summary
    print_summary(log_path.name, errors, warnings, completed)

    # Determine pass/fail
    if errors:
        return 1  # Errors found = FAIL
    if not completed:
        return 1  # Didn't complete = FAIL

    return 0  # No errors and completed = PASS


################################################################################
# Entry Point
################################################################################

def main():
    """Script entry point"""
    if len(sys.argv) != 2:
        print("Usage: python3 parse_results.py <log_file>")
        print()
        print("Example:")
        print("  python3 parse_results.py ualink_turbo64_tb.log")
        sys.exit(1)

    log_file = sys.argv[1]
    exit_code = analyze_log(log_file)
    sys.exit(exit_code)


if __name__ == "__main__":
    main()

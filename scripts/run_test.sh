#!/bin/bash
################################################################################
# Test Runner Script for PortAlchemy Verilog Testbenches
################################################################################
#
# PURPOSE:
#   This script automates the process of compiling and running a single
#   Verilog testbench using Icarus Verilog (iverilog). It's designed to be
#   called by GitHub Actions for continuous integration testing.
#
# USAGE:
#   ./run_test.sh <testbench_name>
#
#   Example: ./run_test.sh ualink_turbo64_tb
#
# WHAT IT DOES:
#   1. Takes a testbench name as input
#   2. Looks up which files are needed for that testbench
#   3. Navigates to the correct directory
#   4. Compiles the Verilog code using iverilog
#   5. Runs the simulation using vvp (Verilog simulation engine)
#   6. Calls a Python script to check if the test passed or failed
#   7. Returns exit code 0 (success) or 1 (failure) for CI systems
#
# EXIT CODES:
#   0 = Test passed successfully
#   1 = Test failed (compilation error, simulation error, or functional failure)
#
################################################################################

# Exit immediately if any command fails (important for CI - we want to catch errors)
set -e

# Capture the testbench name from command line argument
TESTBENCH=$1

# Figure out where this script is located (even if called from another directory)
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Project root is one level up from the scripts directory
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

################################################################################
# Input Validation
################################################################################

# Check if user provided a testbench name
if [ -z "$TESTBENCH" ]; then
    echo "Error: No testbench specified"
    echo "Usage: $0 <testbench_name>"
    echo ""
    echo "Available testbenches:"
    echo "  - ualink_turbo64_tb"
    echo "  - ualink_turbordwr_tb"
    echo "  - ualink_mac_tb"
    echo "  - ualink_dpmem_tb"
    echo "  - nf10_bram_output_queues_tb"
    echo "  - nf10_nic_output_port_lookup_tb"
    exit 1
fi

echo "========================================="
echo "Running testbench: $TESTBENCH"
echo "========================================="

################################################################################
# Testbench Configuration
################################################################################
#
# Each testbench needs to know:
#   - TB_DIR: Which directory contains the testbench files
#   - TB_FILE: The main testbench file (the one with the test stimulus)
#   - SOURCES: All the design files that the testbench needs to compile against
#
# Think of it like this:
#   - TB_FILE = Your test program
#   - SOURCES = The actual hardware you're testing + supporting modules
#
################################################################################

case $TESTBENCH in
    "ualink_turbo64_tb")
        # Main UALink testbench - tests the full arbitration and packet processing
        TB_DIR="$PROJECT_ROOT/ualink_turbo64_v1_00_a/hdl/verilog"
        TB_FILE="ualink_turbo64_tb.v"
        # Need the main module + all its dependencies (FIFOs and memory)
        SOURCES="ualink_turbo64.v fallthrough_small_fifo_v2.v small_fifo_v3.v ualink_dpmem.v ualink_fma.v"
        ;;

    "ualink_turbordwr_tb")
        # Tests read/write operations to dual-port memory via AXI Stream
        TB_DIR="$PROJECT_ROOT/ualink_turbo64_v1_00_a/hdl/verilog"
        TB_FILE="ualink_turbordwr_tb.v"
        # Same dependencies as above (reuses the same hardware)
        SOURCES="ualink_turbo64.v fallthrough_small_fifo_v2.v small_fifo_v3.v ualink_dpmem.v ualink_fma.v"
        ;;

    "ualink_mac_tb")
        # Tests the MAC (Multiply-Accumulate) unit in isolation
        TB_DIR="$PROJECT_ROOT/ualink_turbo64_v1_00_a/hdl/verilog"
        TB_FILE="ualink_mac_tb.sv"  # Note: .sv extension (SystemVerilog)
        # Only needs the MAC module (standalone test)
        SOURCES="ualink_mac.sv"
        ;;

    "ualink_dpmem_tb")
        # Tests the dual-port RAM in isolation
        TB_DIR="$PROJECT_ROOT/ualink_turbo64_v1_00_a/hdl/verilog"
        TB_FILE="ualink_dpmem_tb.v"
        # Only needs the memory module
        SOURCES="ualink_dpmem.v"
        ;;

    "nf10_bram_output_queues_tb")
        # Tests the output queue management (5-port buffering)
        TB_DIR="$PROJECT_ROOT/nf10_bram_output_queues_v1_00_a/hdl/verilog"
        TB_FILE="nf10_bram_output_queues_tb.v"
        # Needs the queue module + FIFOs it uses internally
        SOURCES="nf10_bram_output_queues.v fallthrough_small_fifo_v2.v small_fifo_v3.v"
        ;;

    "nf10_nic_output_port_lookup_tb")
        # Tests the port routing logic
        TB_DIR="$PROJECT_ROOT/nf10_nic_output_port_lookup_v1_00_a/hdl/verilog"
        TB_FILE="nf10_nic_output_port_lookup_tb.v"
        # Needs the lookup module + FIFOs
        SOURCES="nf10_nic_output_port_lookup.v fallthrough_small_fifo_v2.v small_fifo_v3.v"
        ;;

    *)
        # User typed an invalid testbench name
        echo "Error: Unknown testbench '$TESTBENCH'"
        echo ""
        echo "Valid options:"
        echo "  - ualink_turbo64_tb          (Main arbitration test)"
        echo "  - ualink_turbordwr_tb        (Memory read/write test)"
        echo "  - ualink_mac_tb              (MAC unit test)"
        echo "  - ualink_dpmem_tb            (Dual-port RAM test)"
        echo "  - nf10_bram_output_queues_tb (Output queues test)"
        echo "  - nf10_nic_output_port_lookup_tb (Port routing test)"
        exit 1
        ;;
esac

################################################################################
# Directory Verification
################################################################################

# Make sure the testbench directory actually exists
if [ ! -d "$TB_DIR" ]; then
    echo "Error: Testbench directory not found: $TB_DIR"
    echo "This usually means the project structure has changed."
    exit 1
fi

# Navigate to the testbench directory
# (Icarus Verilog expects to be run from the same directory as the source files)
cd "$TB_DIR"
echo "Working directory: $(pwd)"

################################################################################
# Cleanup Previous Artifacts
################################################################################
#
# Remove old files from previous test runs to ensure we're starting fresh:
#   - .vvp = Compiled simulation binary
#   - .vcd = Waveform dump file
#   - .log = Simulation output log
#
################################################################################

echo ""
echo "Cleaning previous artifacts..."
rm -f ${TESTBENCH}.vvp ${TESTBENCH}.vcd ${TESTBENCH}.log
echo "  Removed: ${TESTBENCH}.vvp (if existed)"
echo "  Removed: ${TESTBENCH}.vcd (if existed)"
echo "  Removed: ${TESTBENCH}.log (if existed)"

################################################################################
# Compilation Phase
################################################################################
#
# iverilog = Icarus Verilog compiler
# -g2012 = Use SystemVerilog-2012 standard (supports both Verilog and SystemVerilog)
# -o = Output file name
#
# This step is like compiling C code with gcc - it checks syntax and creates
# an executable simulation file (.vvp)
#
################################################################################

echo ""
echo "Compiling testbench..."
echo "Command: iverilog -g2012 -o ${TESTBENCH}.vvp ${TB_FILE} ${SOURCES}"

iverilog -g2012 -o ${TESTBENCH}.vvp ${TB_FILE} ${SOURCES}

# Check if compilation succeeded
if [ $? -ne 0 ]; then
    echo ""
    echo "ERROR: Compilation failed!"
    echo "This means there's a syntax error or missing file."
    exit 1
fi

echo "✓ Compilation successful"

################################################################################
# Simulation Phase
################################################################################
#
# vvp = VVP (Verilog simulation engine) - runs the compiled .vvp file
# This is like running the executable after compilation
#
# The testbench will:
#   1. Generate clock signals
#   2. Apply stimulus (send test data)
#   3. Check outputs
#   4. Print messages via $display statements
#   5. Generate waveform data (.vcd file)
#
# We capture all output to a log file for later analysis
#
################################################################################

echo ""
echo "Running simulation..."
echo "Command: vvp ${TESTBENCH}.vvp > ${TESTBENCH}.log 2>&1"

vvp ${TESTBENCH}.vvp > ${TESTBENCH}.log 2>&1

# Check if simulation ran without crashing
if [ $? -ne 0 ]; then
    echo ""
    echo "ERROR: Simulation crashed!"
    echo "--- Simulation Log ---"
    cat ${TESTBENCH}.log
    exit 1
fi

echo "✓ Simulation completed"

################################################################################
# Result Parsing Phase
################################################################################
#
# The simulation ran, but did it PASS or FAIL?
# We need to check the log file for error messages.
#
# This calls a Python script that looks for patterns like:
#   - "ERROR"
#   - "FAIL"
#   - "timeout"
#   - Missing expected outputs
#
# The Python script returns:
#   - Exit code 0 if test passed
#   - Exit code 1 if test failed
#
################################################################################

echo ""
echo "Checking simulation results..."
python3 "$SCRIPT_DIR/parse_results.py" ${TESTBENCH}.log

if [ $? -ne 0 ]; then
    echo ""
    echo "ERROR: Test failed (check log for details)"
    echo ""
    echo "--- Full Simulation Log ---"
    cat ${TESTBENCH}.log
    exit 1
fi

################################################################################
# Success!
################################################################################

echo ""
echo "========================================="
echo "✓ Test PASSED: $TESTBENCH"
echo "========================================="
echo ""

exit 0

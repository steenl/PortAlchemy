# CI/CD Technical Specification for PortAlchemy
## Automated Verilog Regression Testing with GitHub Actions

---

**Document Version:** 1.0
**Last Updated:** 2025-10-27
**Status:** Implementation Ready
**Target Platform:** GitHub Actions on Ubuntu 22.04

---

## Table of Contents

1. [Overview](#overview)
2. [System Architecture](#system-architecture)
3. [Technical Requirements](#technical-requirements)
4. [Component Specifications](#component-specifications)
5. [File Structure](#file-structure)
6. [Implementation Details](#implementation-details)
7. [Testing Strategy](#testing-strategy)
8. [Adding New Testbenches](#adding-new-testbenches)
9. [Error Handling](#error-handling)
10. [Performance Targets](#performance-targets)
11. [Appendices](#appendices)

---

## 1. Overview

### 1.1 Purpose
Implement automated regression testing for the PortAlchemy Verilog project to:
- Catch bugs before code is merged
- Prevent regressions in existing functionality
- Provide immediate feedback to developers on PRs
- Maintain code quality standards

### 1.2 Scope
- **In Scope:**
  - All 6 existing Verilog/SystemVerilog testbenches
  - Automated compilation with Icarus Verilog
  - Simulation execution and result parsing
  - Waveform artifact storage on failures
  - Pull request status checks

- **Out of Scope (Future Work):**
  - Code coverage analysis
  - FPGA synthesis checks
  - Timing analysis
  - Power consumption estimates

### 1.3 Success Metrics
- CI pipeline completes in < 10 minutes
- All 6 tests run in parallel
- 100% test pass rate on main branch
- Zero false positives/negatives
- Artifacts available for 7 days

---

## 2. System Architecture

### 2.1 High-Level Flow

```
┌─────────────────────────────────────────────────────────────────┐
│  Developer creates Pull Request                                 │
└────────────────┬────────────────────────────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────────────────────────────┐
│  GitHub Actions Workflow Triggered                              │
│  - Event: pull_request, push to main                            │
└────────────────┬────────────────────────────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────────────────────────────┐
│  Allocate 6 Ubuntu VMs (parallel matrix strategy)               │
│  - One VM per testbench                                         │
│  - Ubuntu 22.04 LTS                                             │
└────────────────┬────────────────────────────────────────────────┘
                 │
                 ▼
         ┌───────┴────────┐
         │  For Each VM:  │
         └───────┬────────┘
                 │
    ┌────────────┼────────────┬──────────────┬──────────────┐
    ▼            ▼            ▼              ▼              ▼
┌────────┐  ┌────────┐  ┌────────┐     ┌────────┐    ┌────────┐
│ Test 1 │  │ Test 2 │  │ Test 3 │ ... │ Test 5 │    │ Test 6 │
└───┬────┘  └───┬────┘  └───┬────┘     └───┬────┘    └───┬────┘
    │           │           │              │             │
    ▼           ▼           ▼              ▼             ▼
┌─────────────────────────────────────────────────────────────────┐
│  VM Setup Steps (per testbench):                                │
│  1. Checkout code                                               │
│  2. Install Icarus Verilog (apt-get)                            │
│  3. Setup Python 3.x                                            │
│  4. Run scripts/run_test.sh <testbench_name>                    │
│     ├─ Compile with iverilog                                    │
│     ├─ Simulate with vvp                                        │
│     └─ Parse results with Python                                │
│  5. Upload artifacts if failed                                  │
└────────────────┬────────────────────────────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────────────────────────────┐
│  Aggregate Results                                               │
│  - All tests pass → PR check: ✅ Pass                           │
│  - Any test fails → PR check: ❌ Fail                           │
│  - Artifacts uploaded for debugging                             │
└─────────────────────────────────────────────────────────────────┘
```

### 2.2 Component Interaction Diagram

```
┌──────────────────┐
│  GitHub Actions  │
│   Workflow File  │
│  (regression.yml)│
└────────┬─────────┘
         │ triggers
         ▼
┌──────────────────┐         ┌──────────────────┐
│  run_test.sh     │ calls   │ parse_results.py │
│  (Bash Script)   ├────────▶│  (Python Script) │
└────────┬─────────┘         └──────────┬───────┘
         │                              │
         │ compiles/runs               │ analyzes
         ▼                              ▼
┌──────────────────┐         ┌──────────────────┐
│ Icarus Verilog   │ creates │  Simulation Log  │
│ (iverilog + vvp) │────────▶│   (.log file)    │
└────────┬─────────┘         └──────────────────┘
         │ produces
         ▼
┌──────────────────┐
│  Waveform Data   │
│   (.vcd file)    │
└──────────────────┘
```

---

## 3. Technical Requirements

### 3.1 Software Dependencies

| Component | Version | Source | Installation Method |
|-----------|---------|--------|---------------------|
| **Icarus Verilog** | v11.0 (stable) | Ubuntu APT | `apt-get install iverilog` |
| **Python** | 3.10+ | GitHub Actions pre-installed | `actions/setup-python@v4` |
| **Git** | 2.34+ | GitHub Actions pre-installed | Pre-installed on runner |
| **Bash** | 4.4+ | GitHub Actions pre-installed | Pre-installed on runner |

### 3.2 GitHub Actions Environment

- **Runner OS:** `ubuntu-latest` (currently Ubuntu 22.04 LTS)
- **VM Resources:**
  - CPU: 2 cores
  - RAM: 7 GB
  - Disk: 14 GB SSD
- **Concurrency:** 6 parallel jobs (one per testbench)
- **Timeout:** 60 minutes (per job, configurable)

### 3.3 Testbench Inventory

| # | Testbench Name | File Path | DUT | Dependencies | Est. Runtime |
|---|----------------|-----------|-----|--------------|--------------|
| 1 | `ualink_turbo64_tb` | `ualink_turbo64_v1_00_a/hdl/verilog/` | Main arbitrator | ualink_turbo64.v, FIFOs, DPMEM | 30-60s |
| 2 | `ualink_turbordwr_tb` | `ualink_turbo64_v1_00_a/hdl/verilog/` | Read/Write ops | Same as above | 30-60s |
| 3 | `ualink_mac_tb` | `ualink_turbo64_v1_00_a/hdl/verilog/` | MAC unit | ualink_mac.sv | 10-20s |
| 4 | `ualink_dpmem_tb` | `ualink_turbo64_v1_00_a/hdl/verilog/` | Dual-port RAM | ualink_dpmem.v | 10-20s |
| 5 | `nf10_bram_output_queues_tb` | `nf10_bram_output_queues_v1_00_a/hdl/verilog/` | Output queues | nf10_bram_output_queues.v, FIFOs | 30-60s |
| 6 | `nf10_nic_output_port_lookup_tb` | `nf10_nic_output_port_lookup_v1_00_a/hdl/verilog/` | Port lookup | nf10_nic_output_port_lookup.v, FIFOs | 30-60s |

**Total Sequential Time:** ~2.5 - 5 minutes
**Total Parallel Time:** ~1 - 1.5 minutes (with overhead: ~2-3 minutes)

---

## 4. Component Specifications

### 4.1 GitHub Actions Workflow (`.github/workflows/regression.yml`)

#### 4.1.1 Trigger Configuration
```yaml
on:
  pull_request:
    branches: [ main ]
  push:
    branches: [ main ]
```

**Explanation:**
- Runs on every pull request targeting `main` branch
- Runs on every direct push to `main` (e.g., after merge)
- Does NOT run on pushes to feature branches (only on PRs)

#### 4.1.2 Workflow Structure
```yaml
name: Verilog Regression Tests

jobs:
  test-verilog:
    name: Test ${{ matrix.testbench }}
    runs-on: ubuntu-latest

    strategy:
      fail-fast: false  # Continue running other tests even if one fails
      matrix:
        testbench:
          - ualink_turbo64_tb
          - ualink_turbordwr_tb
          - ualink_mac_tb
          - ualink_dpmem_tb
          - nf10_bram_output_queues_tb
          - nf10_nic_output_port_lookup_tb
```

**Key Configuration:**
- `fail-fast: false` ensures all tests run even if one fails
- Matrix creates 6 parallel jobs automatically
- Each job gets a unique `matrix.testbench` value

#### 4.1.3 Job Steps

**Step 1: Checkout Repository**
```yaml
- name: Checkout repository
  uses: actions/checkout@v3
```
- Action: Clones the repository
- Version: v3 (latest stable)
- Options: Default (full clone, no submodules)

**Step 2: Install Icarus Verilog**
```yaml
- name: Install Icarus Verilog
  run: |
    sudo apt-get update
    sudo apt-get install -y iverilog
    iverilog -v
```
- **Package:** `iverilog` from Ubuntu repos
- **Version:** 11.0 (stable)
- **Install Time:** ~10-15 seconds
- **Why print version:** Debugging aid, confirms installation

**Step 3: Setup Python**
```yaml
- name: Setup Python
  uses: actions/setup-python@v4
  with:
    python-version: '3.x'
```
- Action: Installs Python (if not present)
- Version: Latest 3.x (currently 3.11)
- Cache: pip cache enabled by default

**Step 4: Run Test**
```yaml
- name: Run ${{ matrix.testbench }}
  run: ./scripts/run_test.sh ${{ matrix.testbench }}
```
- Executes the main test script
- Passes testbench name as argument
- Script handles compilation, simulation, and parsing

**Step 5: Upload Artifacts on Failure**
```yaml
- name: Upload waveforms on failure
  if: failure()
  uses: actions/upload-artifact@v3
  with:
    name: ${{ matrix.testbench }}-waveforms
    path: '**/*.vcd'
    retention-days: 7
```
- **Condition:** Only runs if previous step failed
- **Artifact Name:** Unique per testbench (e.g., `ualink_turbo64_tb-waveforms`)
- **Files:** All `.vcd` waveform files
- **Retention:** 7 days (adjustable: 1-90 days)

---

### 4.2 Test Runner Script (`scripts/run_test.sh`)

#### 4.2.1 Purpose
Automate the process of compiling and running a single Verilog testbench.

#### 4.2.2 Input
- **Argument 1:** Testbench name (e.g., `ualink_turbo64_tb`)

#### 4.2.3 Output
- **Exit Code 0:** Test passed
- **Exit Code 1:** Test failed
- **Files Created:**
  - `<testbench>.vvp` - Compiled simulation binary
  - `<testbench>.log` - Simulation output
  - `<testbench>.vcd` - Waveform data (optional, testbench-dependent)

#### 4.2.4 Algorithm Flow
```
1. Validate input (testbench name provided?)
2. Lookup testbench configuration (case statement)
   - Determine: TB_DIR, TB_FILE, SOURCES
3. Navigate to testbench directory (cd $TB_DIR)
4. Clean previous artifacts (rm *.vvp *.vcd *.log)
5. Compile with Icarus:
   iverilog -g2012 -o ${TB}.vvp ${TB_FILE} ${SOURCES}
   - Check exit code, fail if non-zero
6. Simulate:
   vvp ${TB}.vvp > ${TB}.log 2>&1
   - Check exit code, fail if non-zero
7. Parse results:
   python3 parse_results.py ${TB}.log
   - Check exit code, fail if non-zero
8. Exit with success (0)
```

#### 4.2.5 Testbench Configuration Mapping
```bash
case $TESTBENCH in
    "ualink_turbo64_tb")
        TB_DIR="$PROJECT_ROOT/ualink_turbo64_v1_00_a/hdl/verilog"
        TB_FILE="ualink_turbo64_tb.v"
        SOURCES="ualink_turbo64.v fallthrough_small_fifo_v2.v small_fifo_v3.v ualink_dpmem.v"
        ;;
    # ... (similar for other 5 testbenches)
esac
```

**Rationale:** Centralized configuration makes it easy to update file paths or dependencies.

#### 4.2.6 Compilation Options
```bash
iverilog -g2012 -o ${TESTBENCH}.vvp ${TB_FILE} ${SOURCES}
```

- **`-g2012`:** Use SystemVerilog-2012 standard
  - Supports both Verilog and SystemVerilog (.v and .sv)
  - Required for `ualink_mac_tb.sv`
- **`-o`:** Output file name
- **Order matters:** Testbench file first, then design files

---

### 4.3 Result Parser Script (`scripts/parse_results.py`)

#### 4.3.1 Purpose
Analyze simulation log to determine pass/fail status (Verilog simulations don't always have explicit pass/fail).

#### 4.3.2 Input
- **Argument 1:** Path to log file (e.g., `ualink_turbo64_tb.log`)

#### 4.3.3 Output
- **Exit Code 0:** Test passed (no errors, simulation completed)
- **Exit Code 1:** Test failed (errors found OR incomplete simulation)
- **Console Output:** Summary of findings (errors, warnings, completion status)

#### 4.3.4 Detection Patterns

**Error Patterns (Critical - Cause Failure):**
```python
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
```

**Warning Patterns (Informational - No Failure):**
```python
WARNING_PATTERNS = [
    re.compile(r'WARNING', re.IGNORECASE),
    re.compile(r'CAUTION', re.IGNORECASE),
]
```

**Success Patterns (Indicate Completion):**
```python
SUCCESS_PATTERNS = [
    re.compile(r'All tests completed', re.IGNORECASE),
    re.compile(r'Test.*PASSED', re.IGNORECASE),
    re.compile(r'PASSED', re.IGNORECASE),
    re.compile(r'\$finish called'),
    re.compile(r'completed successfully', re.IGNORECASE),
]
```

**Ignore Patterns (False Positives):**
```python
IGNORE_PATTERNS = [
    re.compile(r'^\s*//'),         # Comments
    re.compile(r'^\s*#'),          # Comments
    re.compile(r'No errors', re.IGNORECASE),
    re.compile(r'error.*expected', re.IGNORECASE),  # Intentional errors
]
```

#### 4.3.5 Analysis Algorithm
```python
1. Read log file into memory
2. Split into lines
3. For each line:
   a. Check if should be ignored (comments, false positives)
   b. If not ignored:
      - Check against ERROR_PATTERNS → collect errors
      - Check against WARNING_PATTERNS → collect warnings
4. Check entire log against SUCCESS_PATTERNS
5. Evaluate results:
   - IF errors found → FAIL (exit 1)
   - ELSE IF no completion pattern found → FAIL (exit 1)
   - ELSE → PASS (exit 0)
6. Print summary with line numbers
```

#### 4.3.6 Example Output (Pass)
```
============================================================
Analyzing: ualink_turbo64_tb.log
============================================================

✓ No errors detected
✓ Simulation completed normally

RESULT: PASSED
============================================================
```

#### 4.3.7 Example Output (Fail)
```
============================================================
Analyzing: ualink_turbo64_tb.log
============================================================

✗ ERRORS FOUND: 2
  Line 145: ERROR: Timeout occurred at time 3000
  Line 167: ERROR: Unexpected value on m_axis_tdata

RESULT: FAILED
============================================================
```

---

## 5. File Structure

### 5.1 Repository Layout (After Implementation)

```
PortAlchemy/
├── .github/
│   └── workflows/
│       └── regression.yml              # GitHub Actions workflow (NEW)
│
├── scripts/
│   ├── run_test.sh                     # Main test runner (NEW)
│   ├── parse_results.py                # Log analyzer (NEW)
│   └── run_all_tests.sh                # Local convenience script (NEW, OPTIONAL)
│
├── ualink_turbo64_v1_00_a/
│   └── hdl/verilog/
│       ├── ualink_turbo64_tb.v         # Testbench
│       ├── ualink_turbordwr_tb.v       # Testbench
│       ├── ualink_mac_tb.sv            # Testbench
│       ├── ualink_dpmem_tb.v           # Testbench
│       ├── ualink_turbo64.v            # Design file
│       ├── ualink_mac.sv               # Design file
│       ├── ualink_dpmem.v              # Design file
│       ├── fallthrough_small_fifo_v2.v # Design file
│       └── small_fifo_v3.v             # Design file
│
├── nf10_bram_output_queues_v1_00_a/
│   └── hdl/verilog/
│       ├── nf10_bram_output_queues_tb.v      # Testbench
│       ├── nf10_bram_output_queues.v         # Design file
│       ├── fallthrough_small_fifo_v2.v       # Design file
│       └── small_fifo_v3.v                   # Design file
│
├── nf10_nic_output_port_lookup_v1_00_a/
│   └── hdl/verilog/
│       ├── nf10_nic_output_port_lookup_tb.v  # Testbench
│       ├── nf10_nic_output_port_lookup.v     # Design file
│       ├── fallthrough_small_fifo_v2.v       # Design file
│       └── small_fifo_v3.v                   # Design file
│
├── CI_CD_IMPLEMENTATION_PLAN.md        # Implementation checklist (NEW)
├── CI_CD_SPECIFICATION.md              # This document (NEW)
└── README.md                           # Updated with CI badge (MODIFIED)
```

### 5.2 File Permissions

| File | Permissions | Owner |
|------|-------------|-------|
| `scripts/run_test.sh` | `755` (rwxr-xr-x) | repo owner |
| `scripts/parse_results.py` | `755` (rwxr-xr-x) | repo owner |
| `scripts/run_all_tests.sh` | `755` (rwxr-xr-x) | repo owner |
| `.github/workflows/regression.yml` | `644` (rw-r--r--) | repo owner |

**Set with:**
```bash
chmod +x scripts/*.sh scripts/*.py
```

---

## 6. Implementation Details

### 6.1 Icarus Verilog Installation (Option 1: Direct Installation)

#### 6.1.1 Rationale
- **Simplicity:** Single command installation
- **Reliability:** Official Ubuntu package, well-tested
- **Maintainability:** No custom Docker images to update
- **Transparency:** Easy for contributors to understand

#### 6.1.2 Installation Command
```bash
sudo apt-get update && sudo apt-get install -y iverilog
```

#### 6.1.3 Installation Time
- **apt-get update:** ~5 seconds
- **iverilog install:** ~8-10 seconds
- **Total:** ~15 seconds per job

#### 6.1.4 Installed Components
- `iverilog` - Verilog compiler (CLI: `/usr/bin/iverilog`)
- `vvp` - Verilog simulation runtime (CLI: `/usr/bin/vvp`)
- Libraries: `/usr/lib/ivl/`

#### 6.1.5 Version Verification
```bash
$ iverilog -v
Icarus Verilog version 11.0 (stable) ()
```

#### 6.1.6 Alternative Options (Not Selected)

**Option 2: Docker Container**
```yaml
container: hdlc/sim:osvb
```
- Pros: Faster (no install), version control
- Cons: Complexity, larger download (~200MB)
- Reason not chosen: Unnecessary complexity for this project

**Option 3: Build from Source**
```bash
git clone https://github.com/steveicarus/iverilog.git
cd iverilog && ./configure && make && sudo make install
```
- Pros: Latest features, custom configuration
- Cons: 3-5 minute build time, potential instability
- Reason not chosen: Too slow for CI

### 6.2 Parallel Execution Strategy

#### 6.2.1 Matrix Configuration
```yaml
strategy:
  fail-fast: false
  matrix:
    testbench: [test1, test2, test3, test4, test5, test6]
```

#### 6.2.2 Resource Allocation
- **Free tier limit:** 20 concurrent jobs
- **Our usage:** 6 concurrent jobs (30% of limit)
- **VM per job:** 2 cores, 7GB RAM
- **No resource contention expected**

#### 6.2.3 Execution Timeline
```
Time 0s:   Workflow triggered
Time 5s:   6 VMs allocated
Time 20s:  Icarus installed on all VMs
Time 25s:  Tests start executing
Time 90s:  Longest test completes (ualink_turbo64_tb)
Time 95s:  Results aggregated, artifacts uploaded
Time 100s: Workflow completes
```

**Total Time:** ~100 seconds (1.5 minutes) under ideal conditions
**Expected Time:** 2-3 minutes (accounting for GitHub Actions overhead)

### 6.3 Artifact Management

#### 6.3.1 What Gets Uploaded
- **Waveform files:** `*.vcd`
- **Log files:** Included in waveform zip (optional)
- **Only on failure:** Conditional upload with `if: failure()`

#### 6.3.2 Storage Configuration
```yaml
uses: actions/upload-artifact@v3
with:
  name: ${{ matrix.testbench }}-waveforms
  path: '**/*.vcd'
  retention-days: 7
```

#### 6.3.3 Artifact Naming Convention
- Format: `<testbench_name>-waveforms`
- Example: `ualink_turbo64_tb-waveforms.zip`
- Includes: All `.vcd` files from testbench directory

#### 6.3.4 Retention Policy
- **Duration:** 7 days
- **Rationale:** Enough time to debug issues, not too long to waste storage
- **Cost:** Free on public repos, minimal on private repos

#### 6.3.5 Download Instructions
```bash
# Via GitHub UI:
1. Go to Actions tab
2. Click on failed workflow run
3. Scroll to "Artifacts" section
4. Download ZIP file

# Via gh CLI:
gh run download <run-id> -n ualink_turbo64_tb-waveforms
```

---

## 7. Testing Strategy

### 7.1 Test Levels

#### 7.1.1 Local Testing (Pre-commit)
**Who:** Developers before pushing
**When:** Before creating PR
**How:**
```bash
# Test single testbench
./scripts/run_test.sh ualink_turbo64_tb

# Test all testbenches
./scripts/run_all_tests.sh
```

#### 7.1.2 CI Testing (Automated)
**Who:** GitHub Actions
**When:** On PR creation/update, push to main
**How:** Automatic via workflow

#### 7.1.3 Manual Testing (Ad-hoc)
**Who:** Maintainers
**When:** Investigating specific issues
**How:** Re-run workflow or test locally with modified testbench

### 7.2 Pass/Fail Criteria

#### 7.2.1 Pass Criteria (All Must Be True)
1. ✅ Compilation succeeds (iverilog exit code 0)
2. ✅ Simulation completes (vvp exit code 0)
3. ✅ No ERROR patterns in log
4. ✅ Simulation reaches `$finish` or success message
5. ✅ Log file is non-empty

#### 7.2.2 Fail Criteria (Any Can Trigger)
1. ❌ Compilation error (syntax, missing file, etc.)
2. ❌ Simulation crash (segfault, runtime error)
3. ❌ ERROR message in log
4. ❌ Simulation timeout (doesn't reach $finish)
5. ❌ Log file empty or missing

#### 7.2.3 Warnings Policy
- Warnings do NOT cause test failure
- Warnings are reported in console output
- Consider promoting specific warnings to errors if needed

### 7.3 Regression Detection

#### 7.3.1 What Constitutes a Regression
- Test that previously passed now fails on new code
- New compilation errors in existing files
- New simulation errors or timeouts

#### 7.3.2 Baseline
- **Golden Standard:** Latest commit on `main` branch
- All tests must pass before merging to main
- PRs cannot be merged with failing tests

#### 7.3.3 Regression Handling
1. CI fails on PR
2. Developer investigates using logs/waveforms
3. Developer fixes code
4. Developer pushes update to PR
5. CI re-runs automatically
6. Repeat until green

---

## 8. Adding New Testbenches

### 8.1 Overview

The CI/CD system is designed to be easily extensible. Adding a new testbench requires updates to **2 files** and takes approximately **5-10 minutes**.

### 8.2 Scalability Limits

| Aspect | Current | Practical Limit | Notes |
|--------|---------|-----------------|-------|
| **Testbenches** | 6 | 20-30 | Before needing workflow optimization |
| **Parallel Jobs** | 6 | 20 | GitHub Actions free tier concurrent limit |
| **Total CI Time** | ~2-3 min | ~10 min | User experience threshold |
| **Matrix Size** | 6 | 256 | GitHub Actions hard limit (unlikely to hit) |

### 8.3 Step-by-Step Guide

#### 8.3.1 Prerequisites
Before adding a new testbench to CI, ensure:
- ✅ Testbench file exists and is tested locally
- ✅ All dependencies (design files) are identified
- ✅ Testbench follows naming convention: `*_tb.v` or `*_tb.sv`
- ✅ Testbench uses `$finish` or prints success message

#### 8.3.2 Step 1: Update `scripts/run_test.sh`

**Location:** Line ~60 (inside the `case` statement)

**Action:** Add a new case entry for your testbench

**Example:** Adding `ualink_ethernet_mac_tb`

```bash
################################################################################
# Testbench Configuration
################################################################################

case $TESTBENCH in
    "ualink_turbo64_tb")
        TB_DIR="$PROJECT_ROOT/ualink_turbo64_v1_00_a/hdl/verilog"
        TB_FILE="ualink_turbo64_tb.v"
        SOURCES="ualink_turbo64.v fallthrough_small_fifo_v2.v small_fifo_v3.v ualink_dpmem.v"
        ;;

    # ... existing testbenches ...

    # ========== NEW TESTBENCH ENTRY ==========
    "ualink_ethernet_mac_tb")
        # Directory containing the testbench file
        TB_DIR="$PROJECT_ROOT/ualink_ethernet_v1_00_a/hdl/verilog"

        # Testbench file name (the test itself)
        TB_FILE="ualink_ethernet_mac_tb.v"

        # Space-separated list of design files needed by the testbench
        # Order: main design file first, then dependencies
        SOURCES="ualink_ethernet_mac.v ethernet_crc.v fifo_wrapper.v"
        ;;
    # =========================================

    *)
        echo "Error: Unknown testbench '$TESTBENCH'"
        # ... existing error handling ...
        ;;
esac
```

**Template to Copy:**
```bash
"your_testbench_name_tb")
    TB_DIR="$PROJECT_ROOT/path/to/testbench/directory"
    TB_FILE="your_testbench_name_tb.v"   # or .sv for SystemVerilog
    SOURCES="design_file1.v design_file2.v dependency.v"
    ;;
```

**Important Notes:**
- **Naming:** Testbench name must match exactly (case-sensitive)
- **TB_DIR:** Relative to `PROJECT_ROOT`, no trailing slash
- **SOURCES:** List all files except the testbench itself
- **Order:** Testbench file is specified separately in `TB_FILE`
- **Spacing:** Use spaces (not tabs) in the SOURCES list

#### 8.3.3 Step 2: Update `.github/workflows/regression.yml`

**Location:** Line ~30 (inside the `matrix.testbench` list)

**Action:** Add the testbench name to the matrix array

**Before:**
```yaml
strategy:
  fail-fast: false
  matrix:
    testbench:
      - ualink_turbo64_tb
      - ualink_turbordwr_tb
      - ualink_mac_tb
      - ualink_dpmem_tb
      - nf10_bram_output_queues_tb
      - nf10_nic_output_port_lookup_tb
```

**After:**
```yaml
strategy:
  fail-fast: false
  matrix:
    testbench:
      - ualink_turbo64_tb
      - ualink_turbordwr_tb
      - ualink_mac_tb
      - ualink_dpmem_tb
      - nf10_bram_output_queues_tb
      - nf10_nic_output_port_lookup_tb
      - ualink_ethernet_mac_tb              # ← NEW ENTRY
```

**Important Notes:**
- Add the new entry at the end of the list
- Use exact same name as in `run_test.sh`
- Maintain consistent indentation (6 spaces before the dash)
- No quotes needed around the testbench name

#### 8.3.4 Step 3: Test Locally

Before committing, verify the testbench works:

```bash
# Navigate to project root
cd /path/to/PortAlchemy

# Test the new testbench
./scripts/run_test.sh ualink_ethernet_mac_tb

# Expected output:
# =========================================
# Running testbench: ualink_ethernet_mac_tb
# =========================================
# Working directory: /path/to/testbench
# Cleaning previous artifacts...
# Compiling testbench...
# ✓ Compilation successful
# Running simulation...
# ✓ Simulation completed
# Checking simulation results...
# ============================================================
# Analyzing: ualink_ethernet_mac_tb.log
# ============================================================
# ✓ No errors detected
# ✓ Simulation completed normally
# RESULT: PASSED
# ============================================================
# =========================================
# ✓ Test PASSED: ualink_ethernet_mac_tb
# =========================================
```

**If test fails:**
1. Check error messages carefully
2. Verify all source files are listed correctly in `SOURCES`
3. Ensure file paths are correct (case-sensitive on Linux)
4. Confirm testbench compiles manually:
   ```bash
   cd /path/to/testbench/directory
   iverilog -g2012 -o test.vvp testbench.v design.v dependencies.v
   vvp test.vvp
   ```

#### 8.3.5 Step 4: Commit Changes

```bash
# Check what changed
git diff scripts/run_test.sh
git diff .github/workflows/regression.yml

# Stage the changes
git add scripts/run_test.sh .github/workflows/regression.yml

# Commit with descriptive message
git commit -m "ci: Add ualink_ethernet_mac_tb to regression suite

- Added testbench configuration to run_test.sh
- Added testbench to GitHub Actions matrix
- Verified local execution passes
"

# Push to remote
git push origin your-branch-name
```

#### 8.3.6 Step 5: Verify CI Execution

After pushing:

1. **Check GitHub Actions:**
   - Go to repository → Actions tab
   - Find your workflow run
   - Verify **7 jobs** appear (not 6)
   - Confirm new testbench shows in job list

2. **Monitor Execution:**
   - Click on the new job: `Test ualink_ethernet_mac_tb`
   - Watch the build log
   - Ensure all steps pass (green checkmarks)

3. **Verify Timing:**
   - Check total workflow time
   - Ensure it's still under 10 minutes
   - New test runs in parallel, so total time ≈ max(individual test times)

#### 8.3.7 Step 6: Update Documentation (Optional but Recommended)

Update the following files to keep documentation current:

**A. `CI_CD_IMPLEMENTATION_PLAN.md`**
```markdown
### Testbenches Coverage
| Testbench | What It Tests | Priority |
|-----------|---------------|----------|
| ualink_turbo64_tb | Main arbitration & packet processing | HIGH |
| ... existing entries ...
| ualink_ethernet_mac_tb | Ethernet MAC unit | MEDIUM |  ← ADD THIS
```

**B. `CI_CD_SPECIFICATION.md`** (Section 3.3)
```markdown
| # | Testbench Name | File Path | DUT | Dependencies | Est. Runtime |
|---|----------------|-----------|-----|--------------|--------------|
| 1 | `ualink_turbo64_tb` | ... | ... | ... | 30-60s |
| ... existing entries ...
| 7 | `ualink_ethernet_mac_tb` | `ualink_ethernet_v1_00_a/hdl/verilog/` | Ethernet MAC | ualink_ethernet_mac.v, ... | 20-40s |  ← ADD THIS
```

**C. `README.md`** (if it mentions test count)
```markdown
## Testing
This project includes 7 automated testbenches that run on every pull request.  ← UPDATE COUNT
```

### 8.4 Troubleshooting New Testbenches

#### 8.4.1 Common Issues

**Issue 1: "Unknown testbench" Error**
```
Error: Unknown testbench 'ualink_ethernet_mac_tb'
Valid options: ualink_turbo64_tb, ...
```

**Cause:** Testbench name in GitHub Actions doesn't match `run_test.sh` case statement

**Solution:**
- Ensure exact name match (case-sensitive)
- Check for typos in both files
- Verify no extra spaces or special characters

---

**Issue 2: "File not found" During Compilation**
```
ualink_ethernet_mac.v: error: Unable to open source file
```

**Cause:** Missing file or incorrect path in `SOURCES`

**Solution:**
- List all files in the testbench directory:
  ```bash
  ls -la /path/to/testbench/directory
  ```
- Verify file names match exactly (case-sensitive)
- Check that all dependencies are included in `SOURCES`

---

**Issue 3: Compilation Succeeds Locally but Fails in CI**
```
iverilog: syntax error (locally works fine)
```

**Cause:** Path differences or missing `-g2012` flag

**Solution:**
- CI uses absolute paths via `$PROJECT_ROOT`
- Ensure `TB_DIR` is correct relative to project root
- Test locally from project root:
  ```bash
  cd /path/to/PortAlchemy  # Project root, not testbench dir
  ./scripts/run_test.sh your_testbench_tb
  ```

---

**Issue 4: Test Doesn't Appear in CI**
```
GitHub Actions shows 6 jobs instead of 7
```

**Cause:** Workflow file not updated or syntax error in YAML

**Solution:**
- Verify workflow file was committed and pushed
- Check YAML syntax:
  ```bash
  # Install yamllint
  pip install yamllint

  # Validate syntax
  yamllint .github/workflows/regression.yml
  ```
- Ensure indentation is correct (spaces, not tabs)

### 8.5 Advanced: Dependencies Between Testbenches

If a new testbench depends on files from another module:

**Scenario:** `ualink_system_tb` needs files from multiple directories

**Solution:** Use absolute paths or relative navigation

```bash
"ualink_system_tb")
    TB_DIR="$PROJECT_ROOT/ualink_system_v1_00_a/hdl/verilog"
    TB_FILE="ualink_system_tb.v"

    # Reference files from other directories
    SOURCES="ualink_system.v \
             ../../ualink_turbo64_v1_00_a/hdl/verilog/ualink_turbo64.v \
             ../../ualink_ethernet_v1_00_a/hdl/verilog/ualink_ethernet_mac.v \
             fallthrough_small_fifo_v2.v"
    ;;
```

**Note:** Use `\` for line continuation in bash strings for readability

### 8.6 Example: Complete Pull Request

**PR Title:** Add CI support for new Ethernet MAC testbench

**Files Changed:**
- `scripts/run_test.sh` (+7 lines)
- `.github/workflows/regression.yml` (+1 line)
- `CI_CD_SPECIFICATION.md` (+1 line, optional)

**PR Description:**
```markdown
## Summary
Adds `ualink_ethernet_mac_tb` to the CI/CD regression suite.

## Changes
- ✅ Added testbench configuration to `run_test.sh`
- ✅ Added testbench to GitHub Actions matrix
- ✅ Updated CI specification documentation

## Testing
- ✅ Tested locally: `./scripts/run_test.sh ualink_ethernet_mac_tb`
- ✅ Compilation passes
- ✅ Simulation completes successfully
- ✅ CI shows 7 jobs (was 6)
- ✅ All tests pass in CI

## Screenshot
![image](https://user-images.../ci-7-jobs.png)

## Checklist
- [x] Testbench works locally
- [x] CI configuration updated
- [x] Documentation updated
- [x] All CI checks pass
```

### 8.7 Quick Reference Checklist

When adding a new testbench:

- [ ] Create and test the Verilog testbench locally
- [ ] Identify all source file dependencies
- [ ] Add case entry to `scripts/run_test.sh`
  - [ ] Set `TB_DIR` (testbench directory path)
  - [ ] Set `TB_FILE` (testbench filename)
  - [ ] Set `SOURCES` (space-separated design files)
- [ ] Add testbench name to `.github/workflows/regression.yml` matrix
- [ ] Test locally: `./scripts/run_test.sh your_testbench_tb`
- [ ] Commit both files with descriptive message
- [ ] Push and verify CI shows N+1 jobs
- [ ] Update documentation (optional)
  - [ ] CI_CD_IMPLEMENTATION_PLAN.md
  - [ ] CI_CD_SPECIFICATION.md
  - [ ] README.md (if test count mentioned)

**Estimated Time:** 5-10 minutes per testbench

---

## 9. Error Handling

### 9.1 Compilation Errors

#### 9.1.1 Detection
```bash
iverilog -g2012 -o test.vvp test.v design.v
if [ $? -ne 0 ]; then
    echo "ERROR: Compilation failed"
    exit 1
fi
```

#### 9.1.2 Common Causes
- Syntax errors in Verilog code
- Missing files (incorrect SOURCES list)
- Incompatible language features (e.g., using SystemVerilog in .v file)
- Module/port name mismatches

#### 9.1.3 Resolution
- Check iverilog error messages (printed to console)
- Verify all source files are listed in `run_test.sh`
- Ensure `-g2012` flag is present for SystemVerilog files

### 9.2 Simulation Errors

#### 9.2.1 Detection
```bash
vvp test.vvp > test.log 2>&1
if [ $? -ne 0 ]; then
    echo "ERROR: Simulation crashed"
    exit 1
fi
```

#### 9.2.2 Common Causes
- Divide by zero
- Out-of-bounds array access
- X/Z propagation in critical logic
- Infinite loops

#### 9.2.3 Resolution
- Review simulation log for runtime errors
- Check waveforms (if simulation partially completed)
- Add debug $display statements

### 9.3 Functional Errors

#### 9.3.1 Detection
```python
# parse_results.py
if pattern.search(line):
    errors_found.append((line_num, line))
```

#### 9.3.2 Common Causes
- Design bug (wrong behavior)
- Testbench bug (incorrect expected values)
- Timing issues (race conditions)

#### 9.3.3 Resolution
- Download waveform artifact from GitHub
- Open in GTKWave locally:
  ```bash
  gtkwave testbench.vcd
  ```
- Compare actual vs. expected signals
- Fix design or testbench accordingly

### 9.4 Timeout Errors

#### 9.4.1 Detection
- Simulation doesn't reach `$finish`
- No success pattern in log
- `parse_results.py` returns exit code 1

#### 9.4.2 Common Causes
- Infinite loop in design
- Clock not toggling
- Testbench waiting on signal that never arrives
- Simulation takes longer than expected

#### 9.4.3 Resolution
- Add timeout to vvp command (optional):
  ```bash
  timeout 300 vvp test.vvp  # 5 minute limit
  ```
- Check testbench for infinite wait conditions
- Verify clock generation logic

### 9.5 Script Errors

#### 9.5.1 Common Issues
- **Permission Denied:** Scripts not executable
  ```bash
  chmod +x scripts/*.sh scripts/*.py
  ```
- **File Not Found:** Incorrect path in script
  - Check `TB_DIR` in case statement
  - Verify relative paths
- **Python Module Missing:** Missing standard library
  - Unlikely (only uses `sys`, `re`, `pathlib`)

---

## 10. Performance Targets

### 10.1 Time Budgets

| Phase | Target | Maximum | Current Estimate |
|-------|--------|---------|------------------|
| **Workflow Trigger** | < 5s | 30s | ~5s |
| **VM Allocation** | < 10s | 60s | ~10s |
| **Checkout Code** | < 5s | 30s | ~3s |
| **Install Icarus** | < 15s | 60s | ~15s |
| **Compile Testbench** | < 10s | 120s | ~5s |
| **Run Simulation** | < 60s | 300s | ~30s |
| **Parse Results** | < 5s | 30s | ~1s |
| **Upload Artifacts** | < 10s | 60s | ~5s (on failure) |
| **Total (per job)** | < 120s | 600s | ~74s |
| **Total (parallel)** | < 150s | 600s | ~90s |

### 10.2 Optimization Opportunities

#### 10.2.1 Current Bottlenecks
1. Icarus installation (~15s) - unavoidable with apt-get
2. Longest simulation (~60s) - depends on testbench design

#### 10.2.2 Future Optimizations
- **Caching:** Cache Icarus binaries (save ~10s per job)
- **Docker:** Pre-built image (save ~15s, add ~5s pull time)
- **Compilation:** Pre-compile common modules (marginal benefit)

#### 10.2.3 Not Worth Optimizing
- Checkout time (already fast at ~3s)
- Parse script (negligible at ~1s)
- GitHub overhead (out of our control)

### 10.3 Resource Usage

#### 10.3.1 GitHub Actions Minutes
- **Per PR:** ~15 minutes (6 jobs × 2.5 minutes each)
- **Free tier:** 2,000 minutes/month
- **Estimated usage:** ~20 PRs/month = 300 minutes/month
- **Remaining:** 1,700 minutes for other workflows

#### 10.3.2 Storage (Artifacts)
- **Per failed test:** ~1-5 MB (waveform file)
- **Retention:** 7 days
- **Max scenario:** All 6 tests fail = ~30 MB
- **Free tier:** 500 MB storage
- **Impact:** Minimal (~6% if all tests fail)

---

## 11. Appendices

### 11.1 Complete GitHub Actions Workflow File

**File:** `.github/workflows/regression.yml`

```yaml
################################################################################
# GitHub Actions Workflow: Verilog Regression Tests
################################################################################
#
# PURPOSE:
#   Automated testing of all Verilog testbenches on pull requests and pushes
#   to main branch. Ensures code quality and prevents regressions.
#
# TRIGGERS:
#   - Pull requests targeting 'main' branch
#   - Direct pushes to 'main' branch (e.g., after merge)
#
# STRATEGY:
#   - Parallel execution: 6 testbenches run simultaneously
#   - Independent jobs: One failure doesn't stop others
#   - Artifact collection: Waveforms saved on failures for debugging
#
# DURATION:
#   - Expected: 2-3 minutes (parallel execution)
#   - Maximum: 10 minutes per job (timeout)
#
################################################################################

name: Verilog Regression Tests

# When to run this workflow
on:
  pull_request:
    branches: [ main ]
  push:
    branches: [ main ]

# Define the jobs
jobs:
  test-verilog:
    # Job name shown in GitHub UI (includes testbench name)
    name: Test ${{ matrix.testbench }}

    # Use latest Ubuntu (currently 22.04 LTS)
    runs-on: ubuntu-latest

    # Timeout after 60 minutes (safety net, should never be reached)
    timeout-minutes: 60

    # Matrix strategy: Create 6 parallel jobs
    strategy:
      # Don't cancel other tests if one fails
      fail-fast: false

      # Define the matrix dimension
      matrix:
        testbench:
          - ualink_turbo64_tb
          - ualink_turbordwr_tb
          - ualink_mac_tb
          - ualink_dpmem_tb
          - nf10_bram_output_queues_tb
          - nf10_nic_output_port_lookup_tb

    # Steps to execute for each matrix job
    steps:
      ############################################################################
      # Step 1: Get the code
      ############################################################################
      - name: Checkout repository
        uses: actions/checkout@v3
        # This clones your repository into the runner's workspace
        # Default: Full clone, no submodules, main branch (or PR branch)

      ############################################################################
      # Step 2: Install Icarus Verilog simulator
      ############################################################################
      - name: Install Icarus Verilog
        run: |
          echo "Installing Icarus Verilog..."
          sudo apt-get update
          sudo apt-get install -y iverilog
          echo "Verifying installation..."
          iverilog -v
          which iverilog
          which vvp
        # This installs iverilog v11.0 from Ubuntu repositories
        # Takes ~10-15 seconds
        # Includes both compiler (iverilog) and simulator (vvp)

      ############################################################################
      # Step 3: Setup Python for result parsing
      ############################################################################
      - name: Setup Python
        uses: actions/setup-python@v4
        with:
          python-version: '3.x'
        # Installs latest Python 3 (currently 3.11)
        # Usually already available on ubuntu-latest, this ensures it's present

      ############################################################################
      # Step 4: Make scripts executable
      ############################################################################
      - name: Make scripts executable
        run: chmod +x scripts/*.sh scripts/*.py
        # Ensures our scripts can be executed
        # Needed because git doesn't always preserve execute permissions

      ############################################################################
      # Step 5: Run the testbench
      ############################################################################
      - name: Run ${{ matrix.testbench }}
        run: |
          echo "=========================================="
          echo "Running testbench: ${{ matrix.testbench }}"
          echo "=========================================="
          ./scripts/run_test.sh ${{ matrix.testbench }}
        # This is the main test execution
        # Script handles: compile → simulate → parse results
        # Exit code 0 = pass, exit code 1 = fail

      ############################################################################
      # Step 6: Upload waveforms if test failed
      ############################################################################
      - name: Upload waveforms on failure
        if: failure()
        uses: actions/upload-artifact@v3
        with:
          name: ${{ matrix.testbench }}-waveforms
          path: '**/*.vcd'
          retention-days: 7
        # Only runs if previous step failed (if: failure())
        # Uploads all .vcd files for debugging
        # Artifacts available for 7 days
        # Download from GitHub Actions UI → "Artifacts" section
```

### 11.2 Testbench Dependency Matrix

| Testbench | TB File | Design Files | FIFO Files | Memory Files | Total Files |
|-----------|---------|--------------|------------|--------------|-------------|
| ualink_turbo64_tb | ualink_turbo64_tb.v | ualink_turbo64.v | fallthrough_small_fifo_v2.v, small_fifo_v3.v | ualink_dpmem.v | 5 |
| ualink_turbordwr_tb | ualink_turbordwr_tb.v | ualink_turbo64.v | fallthrough_small_fifo_v2.v, small_fifo_v3.v | ualink_dpmem.v | 5 |
| ualink_mac_tb | ualink_mac_tb.sv | ualink_mac.sv | - | - | 2 |
| ualink_dpmem_tb | ualink_dpmem_tb.v | ualink_dpmem.v | - | - | 2 |
| nf10_bram_output_queues_tb | nf10_bram_output_queues_tb.v | nf10_bram_output_queues.v | fallthrough_small_fifo_v2.v, small_fifo_v3.v | - | 4 |
| nf10_nic_output_port_lookup_tb | nf10_nic_output_port_lookup_tb.v | nf10_nic_output_port_lookup.v | fallthrough_small_fifo_v2.v, small_fifo_v3.v | - | 4 |

### 11.3 Exit Code Reference

| Component | Exit 0 (Success) | Exit 1 (Failure) |
|-----------|------------------|------------------|
| `run_test.sh` | Test passed | Compilation error, simulation error, or functional failure |
| `parse_results.py` | No errors in log, simulation completed | Errors found OR simulation incomplete |
| `iverilog` | Compilation successful | Syntax error, missing file |
| `vvp` | Simulation ran to completion | Runtime error, segfault |
| GitHub Actions Job | All steps succeeded | Any step failed |
| GitHub Actions Workflow | All jobs succeeded | Any job failed |

### 11.4 Useful Commands

#### Local Testing
```bash
# Run single test
./scripts/run_test.sh ualink_turbo64_tb

# Run all tests
for tb in ualink_turbo64_tb ualink_turbordwr_tb ualink_mac_tb ualink_dpmem_tb nf10_bram_output_queues_tb nf10_nic_output_port_lookup_tb; do
    ./scripts/run_test.sh $tb
done

# View waveform
gtkwave ualink_turbo64_v1_00_a/hdl/verilog/ualink_turbo64_tb.vcd
```

#### GitHub Actions
```bash
# View workflow runs
gh run list

# View specific run details
gh run view <run-id>

# Download artifacts
gh run download <run-id>

# Re-run failed jobs
gh run rerun <run-id> --failed

# Watch a running workflow
gh run watch
```

#### Debugging
```bash
# Check script permissions
ls -la scripts/

# Manually compile testbench
cd ualink_turbo64_v1_00_a/hdl/verilog
iverilog -g2012 -o test.vvp ualink_turbo64_tb.v ualink_turbo64.v fallthrough_small_fifo_v2.v small_fifo_v3.v ualink_dpmem.v

# Manually run simulation
vvp test.vvp | tee test.log

# Parse results manually
python3 ../../scripts/parse_results.py test.log
```

### 11.5 Glossary

| Term | Definition |
|------|------------|
| **CI/CD** | Continuous Integration / Continuous Deployment |
| **DUT** | Device Under Test (the Verilog module being tested) |
| **Icarus Verilog** | Open-source Verilog simulator (iverilog + vvp) |
| **iverilog** | Icarus Verilog compiler (converts .v to .vvp) |
| **vvp** | Icarus Verilog runtime (executes .vvp simulation) |
| **VCD** | Value Change Dump (waveform file format) |
| **Testbench** | Verilog code that tests a design (provides stimulus, checks outputs) |
| **Regression** | Previously working code breaks due to new changes |
| **Artifact** | File uploaded by CI for later download (e.g., waveforms) |
| **Matrix** | GitHub Actions feature to run same job with different parameters |
| **Runner** | Virtual machine that executes GitHub Actions jobs |
| **Workflow** | YAML file defining CI/CD automation |

### 11.6 References

- **GitHub Actions Documentation:** https://docs.github.com/en/actions
- **Icarus Verilog Manual:** http://iverilog.icarus.com/
- **Icarus Verilog GitHub:** https://github.com/steveicarus/iverilog
- **VCD Format Spec:** https://en.wikipedia.org/wiki/Value_change_dump
- **Python Regular Expressions:** https://docs.python.org/3/library/re.html
- **Bash Scripting Guide:** https://www.gnu.org/software/bash/manual/

---

## Document Control

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | 2025-10-27 | Claude | Initial specification document with new testbench guide |

---

**END OF SPECIFICATION**

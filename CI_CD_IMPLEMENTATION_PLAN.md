# GitHub Actions CI/CD Implementation Plan for PortAlchemy

## Overview
This document outlines the complete implementation plan for adding automated regression testing to the PortAlchemy project using GitHub Actions. The CI/CD pipeline will run on every pull request to ensure code quality and prevent regressions.

---

## Implementation Steps

### Phase 1: Setup and Preparation
- [x] **Step 1.1:** Create feature branch `add-github-actions-ci` from main
- [x] **Step 1.2:** Create `scripts/` directory in project root
- [x] **Step 1.3:** Create `scripts/run_test.sh` - Main test runner script
  - Location: `/scripts/run_test.sh`
  - Purpose: Compiles and runs individual testbenches with Icarus Verilog
  - Status: ✅ Created and documented

---

### Phase 2: Core Scripts Development
- [ ] **Step 2.1:** Create `scripts/parse_results.py` - Log analyzer
  - Location: `/scripts/parse_results.py`
  - Purpose: Parses simulation logs to determine pass/fail status
  - Checks for: ERROR patterns, warnings, completion status
  - Exit codes: 0 (pass) or 1 (fail)

- [ ] **Step 2.2:** Make scripts executable
  ```bash
  chmod +x scripts/run_test.sh
  chmod +x scripts/parse_results.py
  ```

- [ ] **Step 2.3:** Create `scripts/run_all_tests.sh` - Convenience wrapper
  - Purpose: Run all testbenches locally
  - Useful for pre-commit testing

---

### Phase 3: GitHub Actions Configuration
- [ ] **Step 3.1:** Create `.github/workflows/` directory structure
  ```
  .github/
    └── workflows/
        └── regression.yml
  ```

- [ ] **Step 3.2:** Create main workflow file `.github/workflows/regression.yml`
  - Trigger: On pull requests and pushes to main
  - Runner: Ubuntu latest (22.04)
  - Matrix strategy: Run all 6 testbenches in parallel
  - Artifacts: Store waveforms (.vcd) on failure
  - **Icarus Verilog Installation: Option 1 - Direct Installation**
    - Method: `sudo apt-get install -y iverilog`
    - Why: Simple, reliable, easy to maintain
    - Install time: ~10-15 seconds per job
    - Version: Icarus v11.0 (from Ubuntu repos)

- [ ] **Step 3.3:** Define testbench matrix
  - ualink_turbo64_tb
  - ualink_turbordwr_tb
  - ualink_mac_tb
  - ualink_dpmem_tb
  - nf10_bram_output_queues_tb
  - nf10_nic_output_port_lookup_tb

- [ ] **Step 3.4:** Configure Icarus Verilog installation step
  ```yaml
  - name: Install Icarus Verilog
    run: |
      sudo apt-get update
      sudo apt-get install -y iverilog
      iverilog -v
  ```

---

### Phase 4: Local Testing & Validation
- [ ] **Step 4.1:** Test `run_test.sh` locally with one testbench
  ```bash
  cd scripts/
  ./run_test.sh ualink_turbo64_tb
  ```

- [ ] **Step 4.2:** Verify parse_results.py works correctly
  - Test with a passing simulation log
  - Test with a failing simulation log (if available)

- [ ] **Step 4.3:** Run all testbenches locally
  ```bash
  ./scripts/run_all_tests.sh
  ```

- [ ] **Step 4.4:** Fix any issues discovered during local testing

---

### Phase 5: Documentation
- [ ] **Step 5.1:** Update main README.md
  - Add CI/CD status badge
  - Document how to run tests locally
  - Explain what the CI checks do

- [ ] **Step 5.2:** Create `docs/CI_CD_GUIDE.md` (optional but recommended)
  - Detailed explanation for contributors
  - Troubleshooting common issues
  - How to interpret CI failures

- [ ] **Step 5.3:** Add comments to workflow file
  - Explain each step for maintainability

---

### Phase 6: Git Workflow
- [ ] **Step 6.1:** Review all changes
  ```bash
  git status
  git diff
  ```

- [ ] **Step 6.2:** Commit changes with descriptive message
  ```bash
  git add .
  git commit -m "Add GitHub Actions CI/CD for regression testing"
  ```

- [ ] **Step 6.3:** Push feature branch to remote
  ```bash
  git push -u origin add-github-actions-ci
  ```

- [ ] **Step 6.4:** Create pull request on GitHub
  - Title: "Add GitHub Actions CI/CD for automated regression testing"
  - Description: Reference this implementation plan
  - Reviewers: Assign appropriate team members

---

### Phase 7: Verification & Deployment
- [ ] **Step 7.1:** Verify GitHub Actions workflow triggers
  - Check that workflow runs automatically on PR
  - Confirm all 6 testbenches execute

- [ ] **Step 7.2:** Review CI results
  - All tests should pass (green checkmarks)
  - Check execution time for each test
  - Verify artifacts are uploaded on failures

- [ ] **Step 7.3:** Test failure scenario
  - Intentionally break a test to verify CI catches it
  - Confirm log files are accessible
  - Verify waveforms are stored as artifacts

- [ ] **Step 7.4:** Address any CI-specific issues
  - Timeout adjustments
  - Path corrections
  - Dependency issues

- [ ] **Step 7.5:** Merge pull request to main
  - Squash or merge based on team preference
  - Delete feature branch after merge

---

## Files Created/Modified

### New Files
```
scripts/
  ├── run_test.sh                    # Main test runner (CREATED ✅)
  ├── parse_results.py               # Log analyzer (PENDING)
  └── run_all_tests.sh               # All tests wrapper (PENDING)

.github/
  └── workflows/
      └── regression.yml             # GitHub Actions config (PENDING)

CI_CD_IMPLEMENTATION_PLAN.md         # This file (CREATED ✅)
docs/CI_CD_GUIDE.md                  # User guide (OPTIONAL)
```

### Modified Files
```
README.md                            # Add CI badge and testing docs (PENDING)
```

---

## Timeline Estimate

| Phase | Estimated Time | Complexity |
|-------|----------------|------------|
| Phase 1: Setup | 15 minutes | ✅ DONE |
| Phase 2: Core Scripts | 30 minutes | Low |
| Phase 3: GitHub Actions | 45 minutes | Medium |
| Phase 4: Local Testing | 30 minutes | Low-Medium |
| Phase 5: Documentation | 30 minutes | Low |
| Phase 6: Git Workflow | 15 minutes | Low |
| Phase 7: Verification | 30 minutes | Medium |
| **TOTAL** | **~3 hours** | |

---

## Testing Strategy

### Testbenches Coverage
| Testbench | What It Tests | Priority |
|-----------|---------------|----------|
| ualink_turbo64_tb | Main arbitration & packet processing | HIGH |
| ualink_turbordwr_tb | Memory read/write operations | HIGH |
| ualink_mac_tb | MAC computation unit | MEDIUM |
| ualink_dpmem_tb | Dual-port RAM functionality | MEDIUM |
| nf10_bram_output_queues_tb | Output queue management | MEDIUM |
| nf10_nic_output_port_lookup_tb | Port routing logic | MEDIUM |

### Success Criteria
- ✅ All 6 testbenches compile without errors
- ✅ All simulations complete without timeout
- ✅ No ERROR or FAIL messages in logs
- ✅ Simulations reach $finish statement
- ✅ Total CI runtime < 10 minutes
- ✅ Waveforms captured on failures

---

## Troubleshooting Common Issues

### Issue: Script Permission Denied
**Solution:** Make scripts executable
```bash
chmod +x scripts/*.sh scripts/*.py
```

### Issue: Icarus Verilog Not Found in CI
**Solution:** Verify installation step in workflow
```yaml
- name: Install Icarus Verilog
  run: sudo apt-get update && sudo apt-get install -y iverilog
```

### Issue: File Not Found During Compilation
**Solution:** Check that `cd` command in run_test.sh navigates to correct directory

### Issue: Test Passes Locally but Fails in CI
**Solution:**
- Check file paths (case sensitivity on Linux)
- Verify all dependencies are listed in SOURCES
- Check for hardcoded absolute paths

### Issue: Simulation Timeout
**Solution:** Adjust timeout in testbench or add timeout parameter to vvp command

---

## Future Enhancements (Post-Implementation)

- [ ] Add code coverage reporting (Verilator)
- [ ] Integrate waveform viewing in PR comments
- [ ] Add synthesis checks (lint with Verilator)
- [ ] Performance benchmarking (track simulation runtime)
- [ ] Slack/Discord notifications on failures
- [ ] Scheduled nightly regression runs
- [ ] Add FPGA synthesis checks (if Vivado/Quartus available)

---

## Resources

- **Icarus Verilog Documentation:** http://iverilog.icarus.com/
- **GitHub Actions Documentation:** https://docs.github.com/en/actions
- **VCD Waveform Format:** https://en.wikipedia.org/wiki/Value_change_dump
- **Regular Expressions (for parse_results.py):** https://docs.python.org/3/library/re.html

---

## Contacts & Support

- **Implementation Lead:** [Your Name]
- **Code Review:** [Team Member]
- **CI/CD Questions:** Reference this document or create GitHub issue

---

*Last Updated: 2025-10-27*
*Document Version: 1.0*

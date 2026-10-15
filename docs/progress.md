# Project Progress

## 2026-10-15

- Reviewed the provided final project specification and source archive.
- Preserved the supplied DUT RTL unchanged.
- Added constrained-random AXI traffic sequence and random test (40 single-beat transactions, aligned addresses).
- Added a simultaneous AR/AW stimulus path and priority test for checking the RTL's documented AR-first selection.
- Added a lightweight virtual sequence; the APB agent remains reactive to the DUT's APB ACCESS phase.
- Added testbench protocol assertions and instantiated them in `smoke_tb`.
- Extended scoreboard checks for AXI response ID/USER and OKAY response status; adjusted PSLVERR handling to document that this supplied RTL does not propagate APB PSLVERR.
- Removed an invalid scoreboard expectation that AXI WSTRB must appear on APB; APB has no strobe output in this interface.
- Added README, verification plan, lint status, and final-report template.
- **Tests executed in this environment:** none; no VCS/Questa/Verilator/Icarus executable is available. Existing archive includes a previous successful smoke log, but the newly added code still requires compile and regression in the training simulator.

### Next actions

1. Run `make compile TEST=axi2apb_test` in the VCS environment and resolve any version-specific syntax/elaboration issues.
2. Run every test in `scripts/Makefile`; inspect the priority test APB order and the PSLVERR test result.
3. Generate URG coverage and review assertion results.
4. Fill in the final verification report and record seed(s), pass/fail, coverage, and limitations.

## 2026-10-15 (coverage push after first VCS run)

- Work completed: ran package in VCS - compiled and ran with no errors, functional coverage about 60%.
- Root causes of the gap (from reading the coverage model): random addresses limited to 0x100-0xFFC (only `mid` bin hit), data patterns left to chance, fixed per-test APB wait/BREADY/RREADY values (cross bins and `one`/`many` wait bins missed), unreachable non-OKAY `resp` bin counted, `high`/`max` address bins overlapping.
- Added: `axi2apb_read_wait_test`, `axi2apb_boundary_pattern_test`, `axi2apb_backpressure_cross_test`, `axi2apb_random_stress_test`; random test now 300 txns with distributed address/data/ID/USER, randomized PREADY and per-transaction BREADY/RREADY delay.
- Coverage model: fixed overlapping address bins; excluded unreachable non-OKAY response bin with justification.
- Assertions: PENABLE-requires-PSEL, no-X on controls, BRESP/RRESP OKAY assumption, 4 cover properties.
- Scripts: `make regress` (5 seeds) + `gen_report.py` -> `docs/regression_summary.md`.
- Docs: `final_verification_report.md` (replaces template), verification plan updated.
- Tests executed: new code only syntax/semantic checked with slang + UVM core; not simulated here.
- Lint: skipped by decision.
- Next step: `make regress`, read URG holes, fill report section 5.

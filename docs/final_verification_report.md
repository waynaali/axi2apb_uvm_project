# Final Verification Report — AXI4-to-APB Bridge (axi2apb)

Results below are **filled only from simulator evidence**. Run `make regress` in `scripts/`;
it writes `docs/regression_summary.md` and the URG report in `scripts/out/coverage_report`.
Copy the numbers into section 5 after the run.

## 1. DUT and environment
- DUT: supplied PULP `axi2apb` RTL, unmodified (`rtl/`). Defaults: 32-bit addr/data, ID 16, USER 10, buffer depth 4.
- Simulator: VCS (version: ____), UVM 1.2. Testbench commit: ____.
- Lint (Milestone 2): intentionally not performed for this submission.

## 2. Architecture
AXI master agent (item, sequencer, driver, monitor) → DUT → APB slave agent (reactive driver with programmable
PREADY wait / PRDATA / PSLVERR, monitor, optional response sequencer). Both monitors feed the scoreboard;
the AXI monitor also feeds the coverage collector. Protocol assertions bind in `smoke_tb`.

## 3. Test list → spec mapping
| Spec requirement | Test |
|---|---|
| Reset/smoke | `axi2apb_reset_smoke_test`, `axi2apb_test` |
| Single write / read, APB ready | `axi2apb_test` |
| Write with APB wait states | `axi2apb_apb_wait_test` |
| Read with APB wait states | `axi2apb_read_wait_test` (PREADY latency 0/1/2/4/7) |
| RREADY / BREADY delayed | `axi2apb_rready_delay_test`, `axi2apb_bready_delay_test`, `axi2apb_backpressure_cross_test` (0..14 cycles × APB wait 0/3) |
| Simultaneous read/write priority | `axi2apb_priority_test` (scoreboard hard-checks first APB transfer is READ) |
| Back-to-back / mixed | `axi2apb_b2b_write_test`, `axi2apb_b2b_read_test`, `axi2apb_mixed_test` |
| ID / USER | `axi2apb_id_user_test`, `axi2apb_boundary_pattern_test` |
| Boundary addresses, data patterns | `axi2apb_boundary_pattern_test` (zero/one/alt/walking-1/walking-0, 0x0 … 0xFFFFFFFC) |
| PSLVERR behaviour | `axi2apb_pslverr_test` |
| Constrained random | `axi2apb_random_test` (300 txns, PREADY 0..6, BREADY/RREADY 0..8), `axi2apb_random_stress_test` (500 txns, PREADY 0..12) |
| Virtual sequence | `axi2apb_virtual_smoke_test` |

## 4. Assertions
AW/W/AR payload stability, B/R stability under backpressure, APB control stable while PREADY low, reset idle,
RLAST on read response, PENABLE requires PSEL, no X on PWRITE/PADDR in ACCESS, BRESP/RRESP == OKAY (RTL
assumption), plus cover properties for AR+AW together, APB wait→ready, B and R backpressure→handshake.

## 5. Results (fill from regression)
- Regression: ___/___ runs passed, directed tests seed 1, random tests seeds 1 17 99 (`docs/regression_summary.md`)
- Functional coverage (merged): ____ %   Code coverage: line ____ cond ____ toggle ____ assert ____
- Assertion failures: ____
- Coverage holes and disposition: ____

## 6. Observed DUT behaviour / known limitations (from RTL analysis)
- AR has priority over AW when both are valid in IDLE.
- BRESP/RRESP are always OKAY; PSLVERR is not used by the FSM, so driving PSLVERR does not change the AXI response. Non-OKAY response bins are excluded from coverage as unreachable.
- Only single-beat transfers are implemented; burst address progression is not claimed.
- WSTRB/WLAST are accepted but not used for APB generation (APB interface has no strobe).
- Testbench driver issues one transaction at a time, so deep AXI pipelining across channels is limited to what the DUT buffers show on one transaction.

## 7. Issues found
(list DUT / testbench / checker / sequence issues with seed and log reference)

## 8. Conclusion
(pass/fail summary once the regression has been run)

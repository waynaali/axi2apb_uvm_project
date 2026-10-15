# AXI4-to-APB Verification Plan

## Scope and rules

Verify the supplied `axi2apb` RTL through `AXI_BUS` and `APB_BUS`. Do not modify DUT RTL. The environment uses a master-side AXI agent, a reactive APB slave agent with an optional APB response sequencer/sequence, monitors, a scoreboard, functional coverage, and protocol assertions.

## Feature-to-test/checker matrix

| Feature | Stimulus / test | Checker / evidence | Status |
|---|---|---|---|
| Reset release and idle startup | `axi2apb_reset_smoke_test` | reset assertion and smoke transaction | Added; rerun required |
| AXI write address/data handshake | smoke, back-to-back, random | AXI monitor and scoreboard | Existing; new revision unverified |
| AXI write to APB address/direction/data | smoke, mixed, random | APB monitor + scoreboard | Existing; rerun required |
| APB write wait states | `axi2apb_apb_wait_test` | APB wait-state assertion and coverage | Existing; rerun required |
| AXI B response/backpressure | `axi2apb_bready_delay_test` | response stability assertion, coverage | Existing; rerun required |
| AXI read address and APB read | smoke, back-to-back, mixed, random | APB read data vs AXI RDATA | Existing; rerun required |
| APB read wait states | `axi2apb_read_wait_test` (sweep 0/1/2/4/7) | APB stability assertion + apb_cg wait bins | Added; rerun required |
| AXI R response/backpressure and RLAST | `axi2apb_rready_delay_test` | R stability/RLAST assertions | Existing; rerun required |
| ID/USER response propagation | `axi2apb_id_user_test` | scoreboard compares request and response ID/USER | Added checker; rerun required |
| Simultaneous AR/AW priority | `axi2apb_priority_test` | scoreboard errors if first APB transfer is a WRITE; prio_cg | Hard check present; rerun required |
| Back-to-back reads/writes and mixed traffic | existing b2b/mixed tests | transaction scoreboard and adjacency coverage | Existing; rerun required |
| Random address/data/ID/USER/STRB, PREADY and BREADY/RREADY latency | `axi2apb_random_test` (300), `axi2apb_random_stress_test` (500) | scoreboard + functional coverage | Extended; rerun required |
| Boundary addresses, data patterns, ID/USER corners | `axi2apb_boundary_pattern_test` | scoreboard + axi_cg/user_cg | Added; rerun required |
| Backpressure x wait-state cross | `axi2apb_backpressure_cross_test` | bp_cg cross | Added; rerun required |
| PSLVERR behavior | `axi2apb_pslverr_test` | scoreboard expects AXI response OKAY for this RTL and logs ignored APB error | Added; rerun required |
| Burst behavior | not claimed as supported | document supplied RTL limitation | Known limitation |
| WSTRB/WLAST forwarding | directed/random input values | document that supplied FSM does not use them for APB conversion | Known limitation |

## Assertions

`assertions/axi2apb_protocol_assertions.sv` checks AXI AW/W/AR payload stability while stalled, B/R response stability under backpressure, APB control stability while PREADY is low, reset idle behavior, RLAST for the single-read response, PENABLE-requires-PSEL / no-X on APB controls, and the BRESP/RRESP-always-OKAY design assumption, plus cover properties.

## Coverage

The existing coverage collector samples transaction type, address regions, data patterns, IDs, USER values, transaction adjacency, simultaneous AW/AR visibility, APB direction/error/wait cycles, and response backpressure. Coverage closure must be reviewed from VCS/URG reports; a coverage percentage alone is not sign-off.

## Exit criteria

1. All directed and random tests compile and complete without timeout.
2. Scoreboard mismatch count is zero for expected behavior.
3. Assertion failures are zero or individually dispositioned.
4. Functional coverage report is collected; uncovered meaningful bins are addressed or justified.
5. Known DUT limitations are included in the final report.

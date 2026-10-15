# AXI4-to-APB Bridge Verification (UVM)

A UVM-based verification environment for the supplied PULP-platform `axi2apb` RTL. The DUT is treated as the design under verification and must not be modified by this project.

## Architecture

- `rtl/`: supplied DUT and its buffer/FIFO dependencies.
- `tb/interfaces/`: `AXI_BUS` and `APB_BUS` interfaces.
- `tb/smoke_tb.sv`: clock/reset, DUT instantiation, interface configuration, assertions, and `run_test()`.
- `uvm/axi/`: AXI master agent, driver, monitor, and agent.
- `uvm/apb/`: reactive APB slave agent, driver, monitor, and agent.
- `sequences/apb_sequencer.sv` and `sequences/apb_response_sequence.sv`: optional sequence-driven APB wait/error/read-data response control; the default driver remains reactive and uses its memory model when no response item is queued.
- `uvm/env/`: dual-agent environment.
- `uvm/scoreboard/`: AXI/APB transaction correlation and response checks.
- `uvm/coverage/`: functional coverage for type, address/data, ID/USER, sequence adjacency, APB waits, response error stimulus, and backpressure.
- `sequences/`: directed, constrained-random, priority, and virtual sequences.
- `tests/`: UVM tests.
- `assertions/`: protocol assertions bound by explicit top-level instantiation.
- `scripts/`: VCS compile/simulation/regression Makefile and file list.
- `docs/`: verification plan, status, known limitations, and report template.

## Tools

The existing project logs were generated with Synopsys VCS L-2016.06 and UVM 1.2. The current execution environment used to prepare this package does not have VCS installed, so newly added code has **not** been recompiled or rerun here. Re-run the tests in the training VCS environment before treating new tests/assertions as sign-off evidence.

## Run in the VCS environment

```sh
cd scripts
make compile TEST=axi2apb_test
make sim TEST=axi2apb_test
make run SEEDS="1 17 99"
make cov
```

Individual tests can be selected with `TEST=<test_name>`. The regression test list is in `scripts/Makefile`. Run with `VERB=UVM_MEDIUM` for more detail.

## Tests in the regression list

Existing directed tests: `axi2apb_test`, `axi2apb_apb_wait_test`, `axi2apb_bready_delay_test`, `axi2apb_rready_delay_test`, `axi2apb_b2b_write_test`, `axi2apb_b2b_read_test`, `axi2apb_mixed_test`, `axi2apb_id_user_test`.

Added test classes: `axi2apb_reset_smoke_test`, `axi2apb_random_test`, `axi2apb_priority_test`, `axi2apb_pslverr_test`, and `axi2apb_virtual_smoke_test`. The virtual smoke test starts an APB response sequence concurrently with AXI smoke traffic.

## Important DUT limitations reflected in the plan

- The supplied RTL gives AR priority over AW in IDLE.
- `PSLVERR` is not propagated into AXI `BRESP`/`RRESP` by this version; response behavior is expected to remain OKAY and is documented as observed behavior.
- The FSM is single-read focused and does not implement full burst address progression.
- `WSTRB` and `WLAST` are present at the interface but are not used to generate APB-side behavior in the supplied FSM.
- The APB interface has no write-strobe output, so the scoreboard does not falsely compare AXI WSTRB to an APB signal.

## Status

The original archive contains a prior successful smoke simulation log with two scoreboard data/address matches and zero UVM errors. Some other archived compile logs are stale and contain errors from a different source revision. New tests/assertions and documentation have been added in this package, but must be compiled and run in the intended VCS/UVM environment before final sign-off.

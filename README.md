# AXI2APB Bridge: UVM Verification Environment

A UVM 1.2 testbench and regression flow for an **AXI4 to APB bridge**. The project runs on Synopsys VCS, collects code and assertion coverage, and merges all test results into a single URG report.

## Features

- UVM 1.2 environment with directed and constrained-random tests
- AXI4 master side and APB slave side agents, with virtual sequences for cross-protocol scenarios
- SystemVerilog protocol assertions (`axi2apb_protocol_assertions`)
- One-command regression with per-test logs and merged coverage
- Coverage metrics: line, condition, FSM, toggle, branch, assertion

## DUT overview

The bridge accepts AXI read and write transactions and converts them to APB transfers. The AXI channels (AW, W, B, AR, R) are decoupled by buffers built from a parameterized FIFO and single-slice stages.

| Module | Role |
|---|---|
| `axi2apb_wrap` | Top-level wrapper around the bridge |
| `axi2apb` | Core AXI to APB conversion FSM |
| `axi_aw_buffer`, `axi_w_buffer`, `axi_b_buffer`, `axi_ar_buffer`, `axi_r_buffer` | Per-channel AXI buffers |
| `axi_single_slice` | Single pipeline slice used by the buffers |
| `fifo` | Parameterized FIFO (`FALL_THROUGH`, `DATA_WIDTH`, `DEPTH`, `THRESHOLD`) |
| `AXI_BUS`, `APB_BUS` | Interfaces |
| `axi2apb_protocol_assertions` | AXI/APB protocol checkers |

## Directory layout

```
.
├── Makefile            # build / run / coverage flow
├── build.flist         # file list passed to VCS
├── cm_hier.cfg         # (optional) coverage hierarchy / exclusions
├── rtl/                # DUT sources
├── tb/                 # UVM testbench (agents, env, sequences, tests, smoke_tb)
└── out/                # generated output (git-ignored)
    ├── build/          # simv, simv.vdb, simv.daidir, compile.log, per-test logs
    └── coverage_report/# URG HTML report
```

Adjust the folder names above to match your actual tree.

## Requirements

- Synopsys VCS with UVM 1.2 (`-ntb_opts uvm-1.2`)
- Synopsys URG (ships with VCS)
- DVE (optional, for waveforms)
- GNU Make, a POSIX shell, and `timeout` (coreutils)

## Quick start

```bash
make allclean     # start from a clean state
make regress      # build + run all tests + merged coverage report
```

Open `out/coverage_report/dashboard.html` in a browser when it finishes.

## Make targets

| Target | Description |
|---|---|
| `make build` | Compile once into `out/build/` (`simv`, `simv.vdb`, `simv.daidir`) |
| `make sim TEST=<name> SEED=<n>` | Run a single test |
| `make run` | Run all directed tests (seed 1) and random tests (for each seed in `SEEDS`) |
| `make cov` | Generate the merged URG report from `out/build/simv.vdb` |
| `make regress` | `run` followed by `cov` |
| `make wave TEST=<name>` | Open `out/build/waveform_<name>.vpd` in DVE |
| `make clean` | Remove `out/build` and `out/coverage_report` |
| `make allclean` | Remove everything under `out/` |

### Variables

| Variable | Default | Meaning |
|---|---|---|
| `TEST` | `axi2apb_apb_wait_test` | Test for `make sim` |
| `SEED` | `1` | Seed for `make sim` |
| `SEEDS` | `1 17 99` | Seeds for random tests in `make run` |
| `VERB` | `UVM_NONE` | UVM verbosity |

Example:

```bash
make sim TEST=axi2apb_fifo_full_test SEED=5 VERB=UVM_MEDIUM
make run SEEDS="1 2 3 4"
```

## Test list

**Directed tests**

| Test | Focus |
|---|---|
| `axi2apb_test` | Base functional test |
| `axi2apb_apb_wait_test` | APB wait states (PREADY delay) |
| `axi2apb_read_wait_test` | Wait states on the read path |
| `axi2apb_zero_wait_test` | Zero-wait APB slave |
| `axi2apb_bready_delay_test` | Delayed BREADY |
| `axi2apb_rready_delay_test` | Delayed RREADY |
| `axi2apb_backpressure_cross_test` | Combined backpressure on multiple channels |
| `axi2apb_b2b_write_test` | Back-to-back writes |
| `axi2apb_b2b_read_test` | Back-to-back reads |
| `axi2apb_mixed_test` | Mixed reads and writes |
| `axi2apb_priority_test` | Read/write arbitration priority |
| `axi2apb_id_user_test` | ID and USER signal propagation |
| `axi2apb_boundary_pattern_test` | Boundary addresses and data patterns |
| `axi2apb_pslverr_test` | APB slave error (PSLVERR) handling |
| `axi2apb_fifo_full_test` | FIFO full conditions |
| `axi2apb_fifo_stream_test` | Sustained streaming through FIFOs |
| `axi2apb_reset_smoke_test` | Reset sanity |
| `axi2apb_reset_midrun_test` | Reset applied during active traffic |
| `axi2apb_virtual_smoke_test` | Virtual sequence smoke test |

**Random tests** (run for every seed in `SEEDS`)

- `axi2apb_random_test`
- `axi2apb_random_stress_test`

## Coverage flow

- Compile and run use the same flags: `-cm line+cond+fsm+tgl+branch+assert`.
- Every test writes into the single `out/build/simv.vdb` database under its own name (`-cm_name <test>_seed<N>`).
- `urg -dir simv.vdb` merges all tests and has the design information it needs, so no "design file can not be found" warning appears.

### Excluding non-DUT code

`uvm_pkg`, `smoke_tb`, and `vcs_paramclassrepository` are not DUT code and lower the total score. To exclude them, create `cm_hier.cfg`:

```
-module uvm_pkg
-module smoke_tb
-module vcs_paramclassrepository
```

and add `-cm_hier cm_hier.cfg` to the `vcs` command in the `build` target.

## Latest coverage snapshot

| Metric | Score |
|---|---|
| Overall | 83.50 |
| Line | 91.13 |
| Condition | 63.64 |
| Toggle | 90.53 |
| FSM | 80.00 |
| Branch | 86.84 |
| Assertion | 88.89 |

### Known gaps

- `fifo`: assertions at 0%, conditions at 63.64%. Push-when-full and pop-when-empty cases are not yet exercised with `DEPTH=2`.
- `axi2apb`: FSM at 80%, with a state or transition not yet reached.
- `axi2apb_wrap`: toggle at 66.67%, probably unused or constant ports.

## Troubleshooting

| Symptom | Likely cause and fix |
|---|---|
| "design file can not be found in loading base coverage database" | `simv.vdb` or `simv.daidir` was moved after compile. Build in place with `-o` and `-Mdir` (as the Makefile does). |
| A module shows 0.00 in the report | No test reached it, or it was compiled without `-cm`. Check the flags on both compile and run. |
| Mixed or stale coverage numbers | Run `make allclean` before `make regress`. |
| A test reports `FAILED` in `make run` | Open `out/build/<test>_seed<N>.log`. |
| `make cov` says `simv.vdb` is missing | Run `make run` (or `make regress`) first. |

## Notes

- Seeds are applied with `+ntb_random_seed`.
- Each test has a 300-second timeout in `make run`.
- `make run` exits non-zero if any test fails.

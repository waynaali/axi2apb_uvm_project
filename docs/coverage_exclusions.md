# Coverage exclusions and justifications

Status: proposed from the URG reports (23 tests). Re-confirm each row against the
condition/line detail pages after the latest regression. Apply with the URG
exclusion file (`-elfile`) and keep this table as the written justification
(spec section 16: "justify exclusions and unreachable cases").

| # | Item | Metric | Why it cannot / should not be covered |
|---|------|--------|----------------------------------------|
| 1 | `fifo.sv` initial-block `assert property` (full/empty), 10 instances (5 buffers x 2) | ASSERT | Concurrent assertions inside an `initial` block are attempted once at t=0, when `rst_ni && full_o` / `empty_o` is false. They can only pass vacuously whatever the stimulus. DUT cannot be modified (rule 5). Replaced by direct covers in `smoke_tb.sv` (`c_*_fifo_full`, `c_*_fifo_push_pop_mid`). |
| 2 | `uvm_pkg` `uvm_reg_map::do_read/do_write` assertions | ASSERT | UVM library code; no register model is used in this environment. |
| 3 | `vcs_paramclassrepository`, `uvm_pkg` | all | Tool/library code, not DUT or testbench logic. |
| 4 | `fifo.sv` cond `push_i && ~full_o` with push=1, full=1 | COND | `axi_single_slice` gates push with `ready_o = ~full`, so push while full is structurally blocked. |
| 5 | `fifo.sv` cond `pop_i && ~empty_o` with pop=1, empty=1 | COND | pop = ready & `valid_o`, `valid_o = ~empty`; pop on empty is structurally blocked. |
| 6 | `fifo.sv` `FALL_THROUGH` terms and block | COND, LINE | Parameter `FALL_THROUGH=0` fixed by the DUT; constant false. |
| 7 | `fifo.sv` `DEPTH==0` branch | LINE | Wrapper sets `BUFF_DEPTH_SLAVE=2`; zero-depth variant is not instantiated. |
| 8 | `fifo.sv` `if (flush_i)` true branch | LINE | `flush_i` is tied to `1'b0` in `axi_single_slice.sv`. |
| 9 | `axi2apb_wrap.test_en_i` | TOGGLE | DFT test-mode input, tied low in `smoke_tb`; no functional use in the bridge. |
| 10 | `axi2apb.sv` `default: NS = IDLE` | LINE | The 5 FSM states are the only legal encodings; default is a safety net. |
| 11 | `smoke_tb` watchdog / unused tb lines | LINE | Testbench infrastructure, not DUT behaviour. |
| 12 | `axi2apb_64_32.sv` | all | Not instantiated by `axi2apb_wrap`; the verified top is `axi2apb_wrap` (32-bit). State this scope limit in the final report. |

## Not excluded (covered by tests)

| Item | Test |
|------|------|
| FIFO full / stall (AW, W, AR, B, R), stability assertions | `axi2apb_fifo_full_test` |
| Simultaneous push+pop at occupancy 1 (`push && pop && ~full && ~empty`) | `axi2apb_fifo_stream_test` |
| `rst_ni` falling after traffic, `RDATA_Q` clear | `axi2apb_reset_midrun_test` |
| `axi2apb.sv` IDLE-state "PREADY==1" shortcuts, `apb_wait==0` bins (apb_cg, bp_cg) | `axi2apb_zero_wait_test` |
| AW/AR control-field bits (size, burst, lock, cache, prot, region, qos) | `axi2apb_random_test`, `axi2apb_random_stress_test`, `axi2apb_fifo_stream_test` |

## Known remaining test gap

Reset asserted in the middle of a transaction (e.g. during an APB wait) is not yet
exercised; it needs a driver reset-abort and a monitor flush.

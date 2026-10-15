# Final Verification Report (Template)

## DUT and environment
- DUT revision/source:
- Simulator/version:
- UVM version:
- Testbench revision/commit:

## Regression summary

| Test | Seed | Result | AXI/APB transactions | Scoreboard failures | Assertion failures | Notes |
|---|---:|---|---:|---:|---:|---|
| `axi2apb_test` | N/A | Pending | | | | |
| `axi2apb_apb_wait_test` | N/A | Pending | | | | |
| `axi2apb_bready_delay_test` | N/A | Pending | | | | |
| `axi2apb_rready_delay_test` | N/A | Pending | | | | |
| `axi2apb_b2b_write_test` | N/A | Pending | | | | |
| `axi2apb_b2b_read_test` | N/A | Pending | | | | |
| `axi2apb_mixed_test` | N/A | Pending | | | | |
| `axi2apb_id_user_test` | N/A | Pending | | | | |
| `axi2apb_reset_smoke_test` | N/A | Pending | | | | |
| `axi2apb_random_test` | Record actual seed | Pending | | | | |
| `axi2apb_priority_test` | N/A | Pending | | | | |
| `axi2apb_pslverr_test` | N/A | Pending | | | | |
| `axi2apb_virtual_smoke_test` | N/A | Pending | | | | |

## Coverage and assertions
- Functional coverage report:
- Code coverage report:
- Assertion summary:
- Uncovered bins and disposition:

## Known limitations
- The supplied FSM does not implement full burst address progression.
- The supplied FSM does not use WSTRB/WLAST for APB transfer generation.
- PSLVERR is not propagated into AXI response codes in this RTL version.
- The priority, random, virtual-sequence, and assertion additions must be rerun in the intended simulator before sign-off.

## Conclusion
Pending actual regression and coverage evidence.

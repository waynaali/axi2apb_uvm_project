# Package status

This package preserves the supplied DUT RTL and adds testbench-side verification components. Added/updated items include an AXI constrained-random sequence and test, simultaneous AR/AW priority stimulus with a scoreboard check, virtual sequence coordination, an APB response sequencer and optional response sequence, protocol assertions, AXI response ID/USER checks, PSLVERR behavior documentation/checking, verification plan, lint status, progress log, and final-report template.

**Validation limitation:** VCS/Questa/Verilator/Icarus were not installed in the environment used to prepare this ZIP. Newly added SystemVerilog has not been compiled or simulated here. The historical smoke log is included separately and only documents the earlier baseline run. Run the full regression in the intended VCS/UVM environment before sign-off.

**Update (coverage push):** added read-wait, boundary/data-pattern, backpressure-cross and random-stress tests, stronger random sequence, extra assertions, coverage-bin fixes, regression report script and final report document. New code passes a slang + UVM-core parse/elaboration check (no errors in project files), but has **not been simulated**; expect to rerun `make regress` in VCS. RTL lint (Milestone 2) is intentionally skipped.

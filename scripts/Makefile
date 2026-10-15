
# Makefile

TEST     = axi2apb_apb_wait_test
VERB     = UVM_NONE
TIME_OUT = 9200000
SEED     ?= 1
SEEDS    ?= 1 17 99

define newline


endef

# Directed tests are deterministic: one run (seed 1) is enough.
DIRECTED_TESTS = axi2apb_test \
        axi2apb_apb_wait_test \
        axi2apb_bready_delay_test \
        axi2apb_rready_delay_test \
        axi2apb_b2b_write_test \
        axi2apb_b2b_read_test \
        axi2apb_mixed_test \
        axi2apb_id_user_test \
        axi2apb_reset_smoke_test \
        axi2apb_priority_test \
        axi2apb_pslverr_test \
        axi2apb_virtual_smoke_test \
        axi2apb_read_wait_test \
        axi2apb_boundary_pattern_test \
        axi2apb_backpressure_cross_test \
        axi2apb_fifo_full_test \
        axi2apb_reset_midrun_test \
        axi2apb_fifo_stream_test \
        axi2apb_zero_wait_test

# Random tests: run once per seed in SEEDS.
RANDOM_TESTS = axi2apb_random_test \
        axi2apb_random_stress_test

# Compile one test
compile:
	mkdir -p out
	vcs -sverilog -f build.flist -ntb_opts uvm-1.2 +UVM_TESTNAME=$(TEST) -top smoke_tb -cm line+cond+tgl+assert -LDFLAGS -Wl,--no-as-needed -full64 -debug_all
	cd ./out && rm -rf build_$(TEST)
	cd ./out && mkdir build_$(TEST)
	mv csrc simv.daidir simv.vdb simv vc_hdrs.h ./out/build_$(TEST)

# Compile and simulate one test
sim: compile
	cd ./out/build_$(TEST) && timeout 300 ./simv -cm line+cond+tgl+assert +ntb_random_seed=$(SEED) +UVM_TESTNAME=$(TEST) +UVM_VERBOSITY=$(VERB) > log_build_$(TEST).log

# Compile once for all tests
build:
	mkdir -p out
	vcs -sverilog -f build.flist -ntb_opts uvm-1.2 -top smoke_tb -cm line+cond+tgl+assert -LDFLAGS -Wl,--no-as-needed -full64 -debug_all
	rm -rf ./out/build && mkdir -p ./out/build
	mv csrc simv.daidir simv.vdb simv vc_hdrs.h ./out/build

# Directed tests once (seed 1), random tests once per seed in SEEDS.
define RUN_ONE
	@echo "running $(1) seed=$(2) ..."; \
	(cd ./out/build && timeout 300 ./simv -cm line+cond+tgl+assert -cm_name $(1)_seed$(2) +ntb_random_seed=$(2) +UVM_TESTNAME=$(1) +UVM_VERBOSITY=$(VERB) > log_$(1)_seed$(2).log 2>&1); \
	if grep -q "TEST PASSED" ./out/build/log_$(1)_seed$(2).log && ! grep -q "^Error:" ./out/build/log_$(1)_seed$(2).log; then echo "PASS  $(1) seed=$(2)"; else echo "FAIL  $(1) seed=$(2) (see scripts/out/build/log_$(1)_seed$(2).log)"; fi
endef

run: build
	$(foreach t,$(DIRECTED_TESTS),$(call RUN_ONE,$(t),1)$(newline))
	$(foreach s,$(SEEDS),$(foreach t,$(RANDOM_TESTS),$(call RUN_ONE,$(t),$(s))$(newline)))

# Full regression + summary + merged coverage report
regress: run
	python3 gen_report.py out/build ../docs/regression_summary.md
	$(MAKE) cov

# ==========================================
# DVE WAVEFORM VIEWER
# Existing VPD files; no simulation rerun
# ==========================================

DVE ?= dve
WAVE_DIR = out/build

# Open main test waveform
wave:
	$(DVE) -vpd $(WAVE_DIR)/waveform_axi2apb_test.vpd &

# Open APB wait test waveform
wave_apb_wait:
	$(DVE) -vpd $(WAVE_DIR)/waveform_axi2apb_apb_wait_test.vpd &

# Open back-to-back read waveform
wave_b2b_read:
	$(DVE) -vpd $(WAVE_DIR)/waveform_axi2apb_b2b_read_test.vpd &

# Open back-to-back write waveform
wave_b2b_write:
	$(DVE) -vpd $(WAVE_DIR)/waveform_axi2apb_b2b_write_test.vpd &

# Open BREADY delay waveform
wave_bready_delay:
	$(DVE) -vpd $(WAVE_DIR)/waveform_axi2apb_bready_delay_test.vpd &

# Open RREADY delay waveform
wave_rready_delay:
	$(DVE) -vpd $(WAVE_DIR)/waveform_axi2apb_rready_delay_test.vpd &

# Open ID/USER test waveform
wave_id_user:
	$(DVE) -vpd $(WAVE_DIR)/waveform_axi2apb_id_user_test.vpd &

# Open mixed test waveform
wave_mixed:
	$(DVE) -vpd $(WAVE_DIR)/waveform_axi2apb_mixed_test.vpd &

# Open all existing waveforms
waves: wave wave_apb_wait wave_b2b_read wave_b2b_write wave_bready_delay wave_rready_delay wave_id_user wave_mixed

# ==========================================
# COVERAGE
# ==========================================

cov:
	urg -report ./out/coverage_report -dir ./out/build/simv.vdb

# ==========================================
# CLEANUP
# ==========================================

clean:
	rm -rf ./out/build_$(TEST)

allclean:
	rm -rf ./out/*

dve_cov:
	dve -covdir simv.vdb

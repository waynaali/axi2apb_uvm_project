# ============================================================
# AXI2APB UVM Makefile (per-test waveform version)
# ============================================================

.PHONY: all build sim run cov regress clean allclean wave wave-list wave-all

TEST  ?= axi2apb_apb_wait_test
SEED  ?= 1
SEEDS ?= 1 17 99
VERB  ?= UVM_NONE

VCS ?= vcs
URG ?= urg
DVE ?= dve

OUT   = out
BUILD = $(OUT)/build
COV   = $(OUT)/coverage_report

# Absolute paths (each test runs from its own directory)
BUILD_ABS = $(abspath $(BUILD))
SIMV      = $(BUILD_ABS)/simv
CM_DIR    = $(BUILD_ABS)/simv.vdb
RUNS      = $(BUILD_ABS)/runs

# Same coverage flags for compile and run
COV_FLAGS = -cm line+cond+fsm+tgl+branch+assert

all: regress

# ------------------------------------------------------------
# ALL DIRECTED TESTS
# ------------------------------------------------------------

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

# ------------------------------------------------------------
# RANDOM TESTS
# ------------------------------------------------------------

RANDOM_TESTS = axi2apb_random_test \
        axi2apb_random_stress_test

# ------------------------------------------------------------
# COMPILE ONCE
# Compiles in place: simv, simv.daidir and simv.vdb are created
# directly in $(BUILD), so no files are moved after compile.
# ------------------------------------------------------------

build:
	rm -rf $(BUILD)
	mkdir -p $(BUILD)
	$(VCS) -sverilog -f build.flist \
	    -ntb_opts uvm-1.2 \
	    -top smoke_tb \
	    $(COV_FLAGS) \
	    -LDFLAGS -Wl,--no-as-needed \
	    -full64 -debug_all \
	    -Mdir=$(BUILD)/csrc \
	    -o $(BUILD)/simv \
	    -l $(BUILD)/compile.log || exit $$?

# ------------------------------------------------------------
# RUN ONE TEST
# Each run gets its own directory: out/build/runs/<test>_seed<N>/
# The waveform (.vpd) and run.log are written there, so
# nothing is overwritten by other tests.
# ------------------------------------------------------------

sim: build
	mkdir -p $(RUNS)/$(TEST)_seed$(SEED)
	cd $(RUNS)/$(TEST)_seed$(SEED) && $(SIMV) \
	    $(COV_FLAGS) \
	    -cm_dir $(CM_DIR) \
	    -cm_name $(TEST)_seed$(SEED) \
	    +ntb_random_seed=$(SEED) \
	    +UVM_TESTNAME=$(TEST) \
	    +UVM_VERBOSITY=$(VERB) \
	    2>&1 | tee run.log

# ------------------------------------------------------------
# RUN ALL TESTS
# Directed tests run with seed 1, random tests run for every
# seed in SEEDS. Exits non-zero if any test fails.
# ------------------------------------------------------------

run: build
	@mkdir -p $(RUNS); \
	fail=0; \
	for t in $(DIRECTED_TESTS); do \
	    n=$${t}_seed1; \
	    d=$(RUNS)/$$n; \
	    mkdir -p $$d; \
	    echo "========== $$t seed=1 =========="; \
	    ( cd $$d && timeout 300 $(SIMV) \
	        $(COV_FLAGS) \
	        -cm_dir $(CM_DIR) \
	        -cm_name $$n \
	        +ntb_random_seed=1 \
	        +UVM_TESTNAME=$$t \
	        +UVM_VERBOSITY=$(VERB) \
	        > run.log 2>&1 ); \
	    rc=$$?; \
	    if [ $$rc -eq 0 ]; then \
	        echo "Finished: $$t"; \
	    else \
	        echo "FAILED: $$t (exit=$$rc; see $$d/run.log)"; \
	        fail=1; \
	    fi; \
	done; \
	for s in $(SEEDS); do \
	    for t in $(RANDOM_TESTS); do \
	        n=$${t}_seed$${s}; \
	        d=$(RUNS)/$$n; \
	        mkdir -p $$d; \
	        echo "========== $$t seed=$$s =========="; \
	        ( cd $$d && timeout 300 $(SIMV) \
	            $(COV_FLAGS) \
	            -cm_dir $(CM_DIR) \
	            -cm_name $$n \
	            +ntb_random_seed=$$s \
	            +UVM_TESTNAME=$$t \
	            +UVM_VERBOSITY=$(VERB) \
	            > run.log 2>&1 ); \
	        rc=$$?; \
	        if [ $$rc -eq 0 ]; then \
	            echo "Finished: $$t seed=$$s"; \
	        else \
	            echo "FAILED: $$t seed=$$s (exit=$$rc; see $$d/run.log)"; \
	            fail=1; \
	        fi; \
	    done; \
	done; \
	exit $$fail

# ------------------------------------------------------------
# MERGED COVERAGE REPORT
# simv.vdb holds the design plus the data of every test.
# ------------------------------------------------------------

cov:
	@test -d $(BUILD)/simv.vdb || { echo "simv.vdb not found. Run 'make run' first."; exit 1; }
	mkdir -p $(COV)
	cd $(BUILD) && $(URG) -full64 -dir simv.vdb -report ../coverage_report

# ------------------------------------------------------------
# FULL REGRESSION
# ------------------------------------------------------------

regress: run cov
	@echo "Regression and coverage workflow finished."
	@echo "Report: $(COV)/dashboard.html"
	@echo "Waves : make wave-list  |  make wave TEST=<name> SEED=<n>  |  make wave-all"

# ------------------------------------------------------------
# WAVEFORMS
#   make wave-list                  -> list all .vpd files
#   make wave TEST=<name> SEED=<n>  -> open one test's wave in DVE
#   make wave-all                   -> open every test's wave in one DVE
# ------------------------------------------------------------

wave-list:
	@ls -1 $(RUNS)/*/*.vpd 2>/dev/null || echo "No .vpd files found. Run 'make run' first."

wave:
	@f=$$(ls $(RUNS)/$(TEST)_seed$(SEED)/*.vpd 2>/dev/null | head -1); \
	if [ -z "$$f" ]; then \
	    echo "No .vpd found for this test in: $(RUNS)/$(TEST)_seed$(SEED)/"; \
	    echo "Use 'make wave-list' to see the available waveforms."; \
	    exit 1; \
	fi; \
	echo "Opening $$f"; \
	$(DVE) -full64 -vpd $$f &

# Loads every .vpd as a separate database in a single DVE window
wave-all:
	@ls $(RUNS)/*/*.vpd >/dev/null 2>&1 || { echo "No .vpd files found. Run 'make run' first."; exit 1; }
	@rm -f $(BUILD)/open_all.tcl; \
	for f in $(RUNS)/*/*.vpd; do \
	    echo "gui_open_db -file $$f" >> $(BUILD)/open_all.tcl; \
	done; \
	echo "Loading $$(ls $(RUNS)/*/*.vpd | wc -l) waveform database(s) in DVE"; \
	$(DVE) -full64 -script $(BUILD)/open_all.tcl &

# ------------------------------------------------------------
# CLEANUP
# ------------------------------------------------------------

clean:
	rm -rf $(BUILD) $(COV)

allclean:
	rm -rf $(OUT)/* ucli.key DVEfiles

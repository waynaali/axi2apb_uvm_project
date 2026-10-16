# ============================================================
# AXI2APB UVM Makefile (fixed)
# ============================================================

.PHONY: all build sim run cov regress clean allclean wave

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

# Compile aur run dono mein same flags
COV_FLAGS = -cm line+cond+fsm+tgl+branch+assert

# Saari tests ek hi database (simv.vdb) mein jaati hain,
# har test ka apna -cm_name hota hai. urg sirf simv.vdb parhta hai.
SIMV = ./simv

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
# Seedha $(BUILD) mein compile: simv, simv.daidir, simv.vdb
# apni jagah par bante hain, koi mv nahi => design path nahi tootta.
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
# ------------------------------------------------------------

sim: build
	cd $(BUILD) && $(SIMV) \
	    $(COV_FLAGS) \
	    -cm_name $(TEST)_seed$(SEED) \
	    +ntb_random_seed=$(SEED) \
	    +UVM_TESTNAME=$(TEST) \
	    +UVM_VERBOSITY=$(VERB)

# ------------------------------------------------------------
# RUN ALL TESTS
# ------------------------------------------------------------

run: build
	cd $(BUILD) && \
	fail=0; \
	for t in $(DIRECTED_TESTS); do \
	    echo "========== $$t seed=1 =========="; \
	    timeout 300 $(SIMV) \
	        $(COV_FLAGS) \
	        -cm_name $${t}_seed1 \
	        +ntb_random_seed=1 \
	        +UVM_TESTNAME=$$t \
	        +UVM_VERBOSITY=$(VERB) \
	        > $${t}_seed1.log 2>&1; \
	    rc=$$?; \
	    if [ $$rc -eq 0 ]; then \
	        echo "Finished: $$t"; \
	    else \
	        echo "FAILED: $$t (exit=$$rc; see $${t}_seed1.log)"; \
	        fail=1; \
	    fi; \
	done; \
	for s in $(SEEDS); do \
	    for t in $(RANDOM_TESTS); do \
	        echo "========== $$t seed=$$s =========="; \
	        timeout 300 $(SIMV) \
	            $(COV_FLAGS) \
	            -cm_name $${t}_seed$${s} \
	            +ntb_random_seed=$$s \
	            +UVM_TESTNAME=$$t \
	            +UVM_VERBOSITY=$(VERB) \
	            > $${t}_seed$${s}.log 2>&1; \
	        rc=$$?; \
	        if [ $$rc -eq 0 ]; then \
	            echo "Finished: $$t seed=$$s"; \
	        else \
	            echo "FAILED: $$t seed=$$s (exit=$$rc; see $${t}_seed$${s}.log)"; \
	            fail=1; \
	        fi; \
	    done; \
	done; \
	exit $$fail

# ------------------------------------------------------------
# MERGED COVERAGE REPORT
# simv.vdb mein design + saari tests ka data hota hai
# ------------------------------------------------------------

cov:
	@test -d $(BUILD)/simv.vdb || { echo "simv.vdb nahi mila. Pehle 'make run' chalayein."; exit 1; }
	mkdir -p $(COV)
	cd $(BUILD) && $(URG) -full64 -dir simv.vdb -report ../coverage_report

# ------------------------------------------------------------
# FULL REGRESSION
# ------------------------------------------------------------

regress: run cov
	@echo "Regression and coverage workflow finished."
	@echo "Report: $(COV)/dashboard.html"

# ------------------------------------------------------------
# WAVEFORM VIEWER
# ------------------------------------------------------------

wave:
	$(DVE) -vpd $(BUILD)/waveform_$(TEST).vpd &

# ------------------------------------------------------------
# CLEANUP
# ------------------------------------------------------------

clean:
	rm -rf $(BUILD) $(COV)

allclean:
	rm -rf $(OUT)/* ucli.key DVEfiles

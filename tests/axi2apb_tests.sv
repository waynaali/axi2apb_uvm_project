class axi2apb_base_test extends uvm_test;

`uvm_component_utils(axi2apb_base_test)
axi2apb_env env;
virtual AXI_BUS vif;
function new(
string name = "axi2apb_base_test",
uvm_component parent = null
);
super.new(name, parent);
endfunction
// ---------------------------------------------------------
// BUILD PHASE
// ---------------------------------------------------------
virtual function void build_phase(uvm_phase phase);
super.build_phase(phase);
// UVM's default phase timeout is too short for the long random/pattern tests.
// The testbench watchdog in smoke_tb (#9200000) remains the hang detector.
uvm_top.set_timeout(100_000_000, 1);
env = axi2apb_env::type_id::create("env", this);
if (!uvm_config_db#(virtual AXI_BUS)::get(
this, "", "axi_vif", vif
)) begin
`uvm_fatal(
"TEST",
"AXI virtual interface not found"
)
end
endfunction
// ---------------------------------------------------------
// SEQUENCE HOOK
// ---------------------------------------------------------
virtual task run_seq();
// Overridden by derived test.
endtask
// ---------------------------------------------------------
// RUN PHASE
// ---------------------------------------------------------
virtual task run_phase(uvm_phase phase);
phase.raise_objection(this);
`uvm_info(
"TEST",
"Waiting for reset and driver initialization",
UVM_MEDIUM
)
// Top module holds reset low for 5 clock cycles.
// Wait until reset has been released.
repeat (8) @(negedge vif.clk);
// Existing driver initialization delay.
// Keep this if your driver needs 10 clock cycles.
repeat (10) @(negedge vif.clk);
`uvm_info(
"TEST",
"Starting AXI sequence",
UVM_MEDIUM
)
run_seq();
// Allow monitors and scoreboard to finish processing.
repeat (20) @(negedge vif.clk);
`uvm_info(
"TEST",
"Test sequence completed",
UVM_MEDIUM
)
phase.drop_objection(this);
endtask
// ---------------------------------------------------------
// REPORT PHASE
// ---------------------------------------------------------
virtual function void report_phase(uvm_phase phase);
uvm_report_server srv;
srv = uvm_report_server::get_server();
if ((srv.get_severity_count(UVM_ERROR) +
srv.get_severity_count(UVM_FATAL) == 0) &&
(env.scoreboard.pass_count > 0)) begin
`uvm_info(
"RESULT",
"** TEST PASSED **",
UVM_NONE
)
end
else begin
`uvm_info(
"RESULT",
"** TEST FAILED **",
UVM_NONE
)
end
endfunction
endclass
// ---------------------------------------------------------
// DEFAULT TEST
// ---------------------------------------------------------
class axi2apb_test extends axi2apb_base_test;
`uvm_component_utils(axi2apb_test)
function new(
string name = "axi2apb_test",
uvm_component parent = null
);
super.new(name, parent);
endfunction
virtual task run_seq();
axi_sequence seq;
seq = axi_sequence::type_id::create("seq");
`uvm_info(
"TEST",
"Running AXI write/read smoke sequence",
UVM_MEDIUM
)
seq.start(env.axi_ag.axi_seqr);
endtask
endclass
// ---------------------------------------------------------
// SMOKE TEST ALIAS
// ---------------------------------------------------------
class axi2apb_smoke_test extends axi2apb_test;
`uvm_component_utils(axi2apb_smoke_test)
function new(
string name = "axi2apb_smoke_test",
uvm_component parent = null
);
super.new(name, parent);
endfunction
endclass

// ---------------------------------------------------------
// APB WAIT-STATE TEST
// ---------------------------------------------------------
class axi2apb_apb_wait_test extends axi2apb_test;

`uvm_component_utils(axi2apb_apb_wait_test)

function new(
string name = "axi2apb_apb_wait_test",
uvm_component parent = null
);
super.new(name, parent);
endfunction

virtual function void build_phase(uvm_phase phase);
uvm_config_db#(int unsigned)::set(this, "env.apb_ag.apb_drv", "min_wait", 3);
uvm_config_db#(int unsigned)::set(this, "env.apb_ag.apb_drv", "max_wait", 3);
super.build_phase(phase);
endfunction

endclass

// ---------------------------------------------------------
// DIRECTED TESTS
// ---------------------------------------------------------

class axi2apb_bready_delay_test extends axi2apb_base_test;

`uvm_component_utils(axi2apb_bready_delay_test)

function new(string name = "axi2apb_bready_delay_test", uvm_component parent = null);
super.new(name, parent);
endfunction

virtual function void build_phase(uvm_phase phase);
uvm_config_db#(int unsigned)::set(this, "env.axi_ag.axi_drv", "b_delay", 5);
super.build_phase(phase);
endfunction

virtual task run_seq();
axi_sequence seq = axi_sequence::type_id::create("seq");
seq.start(env.axi_ag.axi_seqr);
endtask

endclass

class axi2apb_rready_delay_test extends axi2apb_base_test;

`uvm_component_utils(axi2apb_rready_delay_test)

function new(string name = "axi2apb_rready_delay_test", uvm_component parent = null);
super.new(name, parent);
endfunction

virtual function void build_phase(uvm_phase phase);
uvm_config_db#(int unsigned)::set(this, "env.axi_ag.axi_drv", "r_delay", 5);
super.build_phase(phase);
endfunction

virtual task run_seq();
axi_sequence seq = axi_sequence::type_id::create("seq");
seq.start(env.axi_ag.axi_seqr);
endtask

endclass

class axi2apb_b2b_write_test extends axi2apb_base_test;

`uvm_component_utils(axi2apb_b2b_write_test)

function new(string name = "axi2apb_b2b_write_test", uvm_component parent = null);
super.new(name, parent);
endfunction

virtual task run_seq();
axi_b2b_write_seq seq = axi_b2b_write_seq::type_id::create("seq");
seq.start(env.axi_ag.axi_seqr);
endtask

endclass

class axi2apb_b2b_read_test extends axi2apb_base_test;

`uvm_component_utils(axi2apb_b2b_read_test)

function new(string name = "axi2apb_b2b_read_test", uvm_component parent = null);
super.new(name, parent);
endfunction

virtual task run_seq();
axi_b2b_read_seq seq = axi_b2b_read_seq::type_id::create("seq");
seq.start(env.axi_ag.axi_seqr);
endtask

endclass

class axi2apb_mixed_test extends axi2apb_base_test;

`uvm_component_utils(axi2apb_mixed_test)

function new(string name = "axi2apb_mixed_test", uvm_component parent = null);
super.new(name, parent);
endfunction

virtual task run_seq();
axi_mixed_seq seq = axi_mixed_seq::type_id::create("seq");
seq.start(env.axi_ag.axi_seqr);
endtask

endclass

class axi2apb_id_user_test extends axi2apb_base_test;

`uvm_component_utils(axi2apb_id_user_test)

function new(string name = "axi2apb_id_user_test", uvm_component parent = null);
super.new(name, parent);
endfunction

virtual task run_seq();
axi_id_user_seq seq = axi_id_user_seq::type_id::create("seq");
seq.start(env.axi_ag.axi_seqr);
endtask

endclass


// Reset/startup smoke: base test waits for reset release before transactions.
class axi2apb_reset_smoke_test extends axi2apb_test;
    `uvm_component_utils(axi2apb_reset_smoke_test)
    function new(string name="axi2apb_reset_smoke_test", uvm_component parent=null); super.new(name,parent); endfunction
endclass

class axi2apb_random_test extends axi2apb_base_test;
    `uvm_component_utils(axi2apb_random_test)
    int unsigned num_txn = 300;
    function new(string name="axi2apb_random_test", uvm_component parent=null); super.new(name,parent); endfunction
    virtual function void build_phase(uvm_phase phase);
        // Randomized APB PREADY latency 0..6 (driver draws a new value per access)
        uvm_config_db#(int unsigned)::set(this, "env.apb_ag.apb_drv", "min_wait", 0);
        uvm_config_db#(int unsigned)::set(this, "env.apb_ag.apb_drv", "max_wait", 6);
        super.build_phase(phase);
        void'($value$plusargs("NUM_TXN=%d", num_txn));
    endfunction
    virtual task run_seq();
        axi_random_seq seq = axi_random_seq::type_id::create("random_seq");
        seq.num_transactions = num_txn;
        seq.start(env.axi_ag.axi_seqr);
    endtask
endclass

// Longer random run with deeper APB wait states (0..12) and 1000 transactions.
class axi2apb_random_stress_test extends axi2apb_random_test;
    `uvm_component_utils(axi2apb_random_stress_test)
    function new(string name="axi2apb_random_stress_test", uvm_component parent=null);
        super.new(name,parent);
        num_txn = 500;
    endfunction
    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        // Set after super so it overrides the parent's max_wait of 6 (the driver
        // reads config_db in its own build_phase, which runs after this one).
        uvm_config_db#(int unsigned)::set(this, "env.apb_ag.apb_drv", "max_wait", 12);
    endfunction
endclass

// Dedicated APB read wait-state test: sweeps PREADY latency 0,1,2,4,7 and does
// write + read-back at each setting.
class axi2apb_read_wait_test extends axi2apb_base_test;
    `uvm_component_utils(axi2apb_read_wait_test)
    function new(string name="axi2apb_read_wait_test", uvm_component parent=null); super.new(name,parent); endfunction
    virtual task run_seq();
        int unsigned waits[] = '{0, 1, 2, 4, 7};
        axi_wait_rw_seq seq;
        foreach (waits[i]) begin
            env.apb_ag.apb_drv.min_wait = waits[i];
            env.apb_ag.apb_drv.max_wait = waits[i];
            seq = axi_wait_rw_seq::type_id::create($sformatf("rd_wait_seq_%0d", i));
            seq.addr = 32'h600 + 4*i;
            seq.data = 32'hC0DE_0000 + i;
            seq.start(env.axi_ag.axi_seqr);
        end
    endtask
endclass

// Boundary addresses, data patterns (zero/one/alternating/walking), ID/USER corners.
class axi2apb_boundary_pattern_test extends axi2apb_base_test;
    `uvm_component_utils(axi2apb_boundary_pattern_test)
    function new(string name="axi2apb_boundary_pattern_test", uvm_component parent=null); super.new(name,parent); endfunction
    virtual task run_seq();
        axi_boundary_pattern_seq seq = axi_boundary_pattern_seq::type_id::create("bp_seq");
        seq.start(env.axi_ag.axi_seqr);
    endtask
endclass

// Cross closure: APB wait (none / waited) x BREADY/RREADY delay 0..14, reads and writes.
class axi2apb_backpressure_cross_test extends axi2apb_base_test;
    `uvm_component_utils(axi2apb_backpressure_cross_test)
    function new(string name="axi2apb_backpressure_cross_test", uvm_component parent=null); super.new(name,parent); endfunction
    virtual task run_seq();
        int unsigned apb_waits[] = '{0, 3};
        axi_wait_rw_seq seq;
        foreach (apb_waits[w]) begin
            env.apb_ag.apb_drv.min_wait = apb_waits[w];
            env.apb_ag.apb_drv.max_wait = apb_waits[w];
            for (int d = 0; d <= 14; d++) begin
                env.axi_ag.axi_drv.b_delay = d;
                env.axi_ag.axi_drv.r_delay = d;
                seq = axi_wait_rw_seq::type_id::create($sformatf("bp_seq_%0d_%0d", w, d));
                seq.addr = 32'h700 + 4*d;
                seq.data = 32'hBEEF_0000 + d;
                seq.start(env.axi_ag.axi_seqr);
            end
        end
    endtask
endclass

class axi2apb_priority_test extends axi2apb_base_test;
    `uvm_component_utils(axi2apb_priority_test)
    function new(string name="axi2apb_priority_test", uvm_component parent=null); super.new(name,parent); endfunction
    virtual function void build_phase(uvm_phase phase);
        uvm_config_db#(bit)::set(this, "env.scoreboard", "check_priority", 1'b1);
        super.build_phase(phase);
    endfunction
    virtual task run_seq();
        axi_priority_seq seq = axi_priority_seq::type_id::create("priority_seq");
        seq.start(env.axi_ag.axi_seqr);
    endtask
endclass

class axi2apb_pslverr_test extends axi2apb_test;
    `uvm_component_utils(axi2apb_pslverr_test)
    function new(string name="axi2apb_pslverr_test", uvm_component parent=null); super.new(name,parent); endfunction
    virtual function void build_phase(uvm_phase phase);
        uvm_config_db#(bit)::set(this, "env.apb_ag.apb_drv", "slverr_en", 1'b1);
        super.build_phase(phase);
    endfunction
endclass

class axi2apb_virtual_smoke_test extends axi2apb_base_test;
    `uvm_component_utils(axi2apb_virtual_smoke_test)
    function new(string name="axi2apb_virtual_smoke_test", uvm_component parent=null); super.new(name,parent); endfunction
    virtual task run_seq();
        axi2apb_virtual_sequence vseq = axi2apb_virtual_sequence::type_id::create("vseq");
        vseq.axi_seqr = env.axi_ag.axi_seqr;
        vseq.apb_seqr = env.apb_ag.apb_seqr;
        vseq.run_apb_response_seq = 1'b1;
        vseq.start(null);
    endtask
endclass


// ---------------------------------------------------------------------------
// FIFO full / stall closure. Slow APB slave + BREADY/RREADY held low while the
// AXI master keeps issuing -> AW/W (or AR) FIFOs and B (or R) FIFOs go full, so
// READY is low with VALID high (stability assertions' antecedent) and fifo
// full_o / push-while-full conditions are exercised. Responses are released
// after hold_cycles and the test checks every request completes.
// ---------------------------------------------------------------------------
class axi2apb_fifo_full_test extends axi2apb_base_test;
    `uvm_component_utils(axi2apb_fifo_full_test)
    function new(string name="axi2apb_fifo_full_test", uvm_component parent=null); super.new(name,parent); endfunction

    int unsigned num_txn     = 14;
    int unsigned hold_cycles = 300;

    task run_phase_burst(bit is_write, bit [31:0] base);
        axi_fifo_fill_seq seq = axi_fifo_fill_seq::type_id::create(is_write ? "fill_wr" : "fill_rd");
        int unsigned target = env.scoreboard.pass_count + num_txn;
        seq.is_write = is_write; seq.num_txn = num_txn; seq.base_addr = base;
        env.axi_ag.axi_drv.pipe_mode    = 1;
        env.axi_ag.axi_drv.rsp_ready_en = 0;           // hold BREADY/RREADY low
        fork
            seq.start(env.axi_ag.axi_seqr);            // blocks while FIFOs are full
            begin
                repeat (hold_cycles) @(posedge vif.clk);
                env.axi_ag.axi_drv.rsp_ready_en = 1;   // now drain
            end
        join
        // wait for all responses (bounded)
        for (int t = 0; t < 5000 && env.scoreboard.pass_count < target; t++) @(posedge vif.clk);
        if (env.scoreboard.pass_count < target)
            `uvm_error("FIFO_FULL", $sformatf("only %0d/%0d completions", env.scoreboard.pass_count, target))
        env.axi_ag.axi_drv.rsp_ready_en = 0;
        env.axi_ag.axi_drv.pipe_mode    = 0;
        repeat (10) @(posedge vif.clk);
    endtask

    virtual task run_seq();
        env.apb_ag.apb_drv.min_wait = 12;   // slow downstream -> core drains slowly
        env.apb_ag.apb_drv.max_wait = 12;
        run_phase_burst(1, 32'h800);        // writes: AW/W/B FIFOs full
        run_phase_burst(0, 32'h800);        // reads of same addrs: AR/R FIFOs full
    endtask
endclass


// ---------------------------------------------------------------------------
// Mid-run reset. The tb only resets once at power-up, so rst_ni never falls
// after being high: the async reset path (CS -> IDLE, RDATA_Q cleared) and the
// "!rst_n |-> !penable" assertion were never exercised under traffic. Here
// rst_n is pulsed low while the bridge is idle but with state left over from
// earlier traffic (non-zero RDATA_Q, last FSM path), then traffic must work again.
// Reset is applied via hierarchical reference to the tb's rst_n (testbench-only).
// ---------------------------------------------------------------------------
class axi2apb_reset_midrun_test extends axi2apb_base_test;
    `uvm_component_utils(axi2apb_reset_midrun_test)
    function new(string name="axi2apb_reset_midrun_test", uvm_component parent=null); super.new(name,parent); endfunction

    task pulse_reset(int unsigned cycles = 3);
        repeat (4) @(posedge vif.clk);          // let DUT settle in IDLE
        @(negedge vif.clk);
        smoke_tb.rst_n = 1'b0;
        repeat (cycles) @(negedge vif.clk);
        smoke_tb.rst_n = 1'b1;
        repeat (4) @(posedge vif.clk);
    endtask

    task traffic(string tag);
        axi_b2b_write_seq wseq = axi_b2b_write_seq::type_id::create({tag, "_w"});
        axi_b2b_read_seq  rseq = axi_b2b_read_seq::type_id::create({tag, "_r"});
        wseq.start(env.axi_ag.axi_seqr);
        rseq.start(env.axi_ag.axi_seqr);
    endtask

    virtual task run_seq();
        traffic("pre_rst");
        pulse_reset(3);
        traffic("post_rst1");
        pulse_reset(1);                          // minimum-width reset
        traffic("post_rst2");
    endtask
endclass


// ---------------------------------------------------------------------------
// FIFO streaming with random BREADY/RREADY and random issue gaps: reaches the
// simultaneous push+pop (occupancy 1) case in the AW/W/AR FIFOs and, with
// random response READY, in the B/R FIFOs as well. Also drives random AXI
// control fields through the buffers.
// ---------------------------------------------------------------------------
class axi2apb_fifo_stream_test extends axi2apb_base_test;
    `uvm_component_utils(axi2apb_fifo_stream_test)
    function new(string name="axi2apb_fifo_stream_test", uvm_component parent=null); super.new(name,parent); endfunction

    int unsigned num_txn = 60;

    task stream(bit is_write);
        axi_fifo_stream_seq seq = axi_fifo_stream_seq::type_id::create(is_write ? "stream_wr" : "stream_rd");
        int unsigned target = env.scoreboard.pass_count + num_txn;
        seq.is_write = is_write; seq.num_txn = num_txn;
        env.axi_ag.axi_drv.pipe_mode    = 1;
        env.axi_ag.axi_drv.rsp_random   = 1;
        env.axi_ag.axi_drv.rsp_ready_en = 0;
        seq.start(env.axi_ag.axi_seqr);
        env.axi_ag.axi_drv.rsp_random   = 0;           // drain remaining responses
        env.axi_ag.axi_drv.rsp_ready_en = 1;
        for (int t = 0; t < 5000 && env.scoreboard.pass_count < target; t++) @(posedge vif.clk);
        if (env.scoreboard.pass_count < target)
            `uvm_error("FIFO_STREAM", $sformatf("only %0d/%0d completions", env.scoreboard.pass_count, target))
        env.axi_ag.axi_drv.rsp_ready_en = 0;
        env.axi_ag.axi_drv.pipe_mode    = 0;
        repeat (10) @(posedge vif.clk);
    endtask

    virtual task run_seq();
        env.apb_ag.apb_drv.min_wait = 0;
        env.apb_ag.apb_drv.max_wait = 2;
        stream(1);
        stream(0);
        stream(1);
        stream(0);
    endtask
endclass


// ---------------------------------------------------------------------------
// Zero-wait APB slave: PREADY is already high in the first PENABLE cycle, so the
// bridge takes the IDLE-state "PREADY==1" shortcuts (IDLE -> DONE_SINGLE_RD and
// IDLE -> SEND_B_RESP) that the reactive APB driver can never reach. Closes the
// spec item "PREADY immediate completion" and the apb_wait==0 bins of apb_cg and
// bp_cg. Mixes blocking random traffic (short/long B/R backpressure) with
// pipelined streaming (READY already high when VALID rises -> bp_wait==0).
// ---------------------------------------------------------------------------
class axi2apb_zero_wait_test extends axi2apb_fifo_stream_test;
    `uvm_component_utils(axi2apb_zero_wait_test)
    function new(string name="axi2apb_zero_wait_test", uvm_component parent=null); super.new(name,parent); endfunction

    virtual function void build_phase(uvm_phase phase);
        uvm_config_db#(bit)::set(this, "env.apb_ag.apb_drv", "zero_wait", 1'b1);
        super.build_phase(phase);
    endfunction

    virtual task run_seq();
        axi_random_seq rseq = axi_random_seq::type_id::create("zw_random");
        rseq.num_transactions = 100;
        rseq.start(env.axi_ag.axi_seqr);
        super.run_seq();                 // pipelined write/read streams
    endtask
endclass

class axi_transaction extends uvm_sequence_item;

    // -------------------------
    // AXI transaction type
    // -------------------------
    rand bit is_write;
    // When set, the driver launches AR and AW together to exercise DUT priority.
    bit both_req = 1'b0;
    // When set, the driver only issues the request (AW+W or AR) and returns without
    // waiting for B/R, so several requests can be outstanding (FIFO fill tests).
    bit issue_only = 1'b0;

    // -------------------------
    // AXI ID
    // -------------------------
    rand bit [5:0] id;

    // AXI USER (AW/W/AR)
    rand bit [5:0] user;

    // -------------------------
    // AXI address
    // -------------------------
    rand bit [31:0] addr;

    // -------------------------
    // Write data
    // -------------------------
    rand bit [31:0] data;

    // -------------------------
    // Write strobe
    // -------------------------
    rand bit [3:0] strb;

    // -------------------------
    // Legal AXI control fields (single-beat: LEN is always 0). Defaults equal the
    // old hard-wired values, so directed tests that do not randomize are unchanged.
    // The bridge ignores these; random values prove they pass through harmlessly
    // and exercise the AW/AR buffer bits. BURST excludes WRAP (illegal with LEN=0)
    // and the reserved value; SIZE is limited to the 32-bit bus width.
    // -------------------------
    rand bit [2:0] ctl_size   = 3'd2;
    rand bit [1:0] ctl_burst  = 2'b01;
    rand bit       ctl_lock   = 1'b0;
    rand bit [3:0] ctl_cache  = 4'h0;
    rand bit [2:0] ctl_prot   = 3'h0;
    rand bit [3:0] ctl_region = 4'h0;
    rand bit [3:0] ctl_qos    = 4'h0;
    constraint c_ctl { ctl_size inside {[0:2]}; ctl_burst inside {[0:1]}; }

    // Idle cycles before an issue_only request is driven (FIFO streaming tests).
    rand int unsigned issue_gap = 0;
    constraint c_gap { issue_gap inside {[0:12]}; }

    // -------------------------
    // Per-transaction backpressure (used only when use_dly = 1, otherwise the
    // driver's config_db b_delay / r_delay values apply)
    // -------------------------
    bit use_dly = 1'b0;
    rand int unsigned b_dly;
    rand int unsigned r_dly;
    constraint c_dly { b_dly inside {[0:8]}; r_dly inside {[0:8]}; }

    // -------------------------
    // AXI response
    // -------------------------
    bit [1:0] resp;
    bit [5:0] response_id;
    bit [5:0] response_user;

    // -------------------------
    // Constructor
    // -------------------------
    function new(string name = "axi_transaction");
        super.new(name);
    endfunction

    // -------------------------
    // Print transaction
    // -------------------------
    `uvm_object_utils_begin(axi_transaction)
        `uvm_field_int(is_write, UVM_ALL_ON)
        `uvm_field_int(both_req, UVM_ALL_ON)
        `uvm_field_int(id,       UVM_ALL_ON)
        `uvm_field_int(user,     UVM_ALL_ON)
        `uvm_field_int(addr,     UVM_ALL_ON)
        `uvm_field_int(data,     UVM_ALL_ON)
        `uvm_field_int(strb,     UVM_ALL_ON)
        `uvm_field_int(resp,     UVM_ALL_ON)
        `uvm_field_int(response_id, UVM_ALL_ON)
        `uvm_field_int(response_user, UVM_ALL_ON)
    `uvm_object_utils_end

endclass
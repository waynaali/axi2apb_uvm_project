// Testbench-only protocol assertions. The DUT RTL is not modified.
module axi2apb_protocol_assertions (
    input logic clk, rst_n,
    input logic aw_valid, aw_ready, input logic [31:0] aw_addr, input logic [5:0] aw_id,
    input logic w_valid, w_ready, input logic [31:0] w_data, input logic [3:0] w_strb,
    input logic ar_valid, ar_ready, input logic [31:0] ar_addr, input logic [5:0] ar_id,
    input logic b_valid, b_ready, input logic [1:0] b_resp,
    input logic r_valid, r_ready, input logic [31:0] r_data, input logic [1:0] r_resp, input logic r_last,
    input logic psel, penable, pwrite, pready, input logic [31:0] paddr, pwdata
);
    property p_aw_stable;
        @(posedge clk) disable iff (!rst_n) aw_valid && !aw_ready |=> aw_valid && $stable({aw_addr, aw_id});
    endproperty
    assert property (p_aw_stable) else $error("AXI AW payload/VALID changed before READY");

    property p_w_stable;
        @(posedge clk) disable iff (!rst_n) w_valid && !w_ready |=> w_valid && $stable({w_data, w_strb});
    endproperty
    assert property (p_w_stable) else $error("AXI W payload/VALID changed before READY");

    property p_ar_stable;
        @(posedge clk) disable iff (!rst_n) ar_valid && !ar_ready |=> ar_valid && $stable({ar_addr, ar_id});
    endproperty
    assert property (p_ar_stable) else $error("AXI AR payload/VALID changed before READY");

    property p_b_stable;
        @(posedge clk) disable iff (!rst_n) b_valid && !b_ready |=> b_valid && $stable(b_resp);
    endproperty
    assert property (p_b_stable) else $error("AXI B response changed before READY");

    property p_r_stable;
        @(posedge clk) disable iff (!rst_n) r_valid && !r_ready |=> r_valid && $stable({r_data, r_resp, r_last});
    endproperty
    assert property (p_r_stable) else $error("AXI R response changed before READY");

    // APB: PADDR and PWRITE must hold while PREADY is low. PWDATA only has to hold
    // for WRITE transfers: on a read it is a don't-care, and the supplied RTL drives
    // PWDATA straight from the W buffer, so it may change during a read wait state
    // (seen when AR and AW are presented together). Split into three assertions so a
    // failure names the offending signal.
    property p_apb_ctrl_hold;
        @(posedge clk) disable iff (!rst_n) psel && penable && !pready |=> psel && penable;
    endproperty
    assert property (p_apb_ctrl_hold) else $error("APB PSEL/PENABLE dropped during wait state");

    property p_apb_addr_write_stable;
        @(posedge clk) disable iff (!rst_n) psel && penable && !pready |=> $stable({paddr, pwrite});
    endproperty
    assert property (p_apb_addr_write_stable) else $error("APB PADDR/PWRITE changed during wait state");

    property p_apb_wdata_stable_on_write;
        @(posedge clk) disable iff (!rst_n) psel && penable && !pready && pwrite |=> $stable(pwdata);
    endproperty
    assert property (p_apb_wdata_stable_on_write) else $error("APB PWDATA changed during WRITE wait state");

    assert property (@(posedge clk) !rst_n |-> !penable)
        else $error("APB PENABLE active while reset asserted");
    assert property (@(posedge clk) disable iff (!rst_n) r_valid |-> r_last)
        else $error("Single-read bridge response did not assert RLAST");

    // APB control legality: no APB access without PSEL, and no X on control/address
    assert property (@(posedge clk) disable iff (!rst_n) penable |-> psel)
        else $error("Illegal APB control combination: PENABLE without PSEL");
    assert property (@(posedge clk) disable iff (!rst_n) penable |-> !$isunknown({pwrite, paddr}))
        else $error("APB PWRITE/PADDR unknown during ACCESS phase");

    // Design-specific assumption from RTL analysis: BRESP/RRESP are hard-wired OKAY
    assert property (@(posedge clk) disable iff (!rst_n) b_valid |-> b_resp == 2'b00)
        else $error("BRESP not OKAY (supplied RTL is expected to return OKAY only)");
    assert property (@(posedge clk) disable iff (!rst_n) r_valid |-> r_resp == 2'b00)
        else $error("RRESP not OKAY (supplied RTL is expected to return OKAY only)");

    // Coverage of interesting protocol events (shows up in the assertion report)
    cover property (@(posedge clk) disable iff (!rst_n) ar_valid && aw_valid);
    cover property (@(posedge clk) disable iff (!rst_n) psel && penable && !pready ##1 pready);
    cover property (@(posedge clk) disable iff (!rst_n) b_valid && !b_ready ##1 b_valid && b_ready);
    cover property (@(posedge clk) disable iff (!rst_n) r_valid && !r_ready ##1 r_valid && r_ready);
    // FIFO-full evidence at the AXI boundary: READY held low with VALID high, then released.
    cover property (@(posedge clk) disable iff (!rst_n) aw_valid && !aw_ready ##1 aw_valid && aw_ready);
    cover property (@(posedge clk) disable iff (!rst_n) w_valid  && !w_ready  ##1 w_valid  && w_ready);
    cover property (@(posedge clk) disable iff (!rst_n) ar_valid && !ar_ready ##1 ar_valid && ar_ready);
endmodule

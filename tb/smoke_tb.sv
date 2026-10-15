


module smoke_tb;

  import uvm_pkg::*;
  `include "uvm_macros.svh"

  // ---------------------------------------------------------
  // CLOCK
  // ---------------------------------------------------------
  bit clk = 0;

  always #5 clk = ~clk;

  // ---------------------------------------------------------
  // RESET
  // Reset is generated only in this top module.
  // ---------------------------------------------------------
  bit rst_n;

  initial begin
    rst_n = 1'b0;

    repeat (5) @(negedge clk);

    rst_n = 1'b1;
  end

  // ---------------------------------------------------------
  // AXI AND APB INTERFACES
  // ---------------------------------------------------------
  AXI_BUS axi();
  APB_BUS apb();

  // Connect AXI interface clock.
  assign axi.clk = clk;

  // Connect APB interface clock.
  assign apb.clk = clk;

  // ---------------------------------------------------------
  // DUT
  // ---------------------------------------------------------
  axi2apb_wrap dut (
    .clk_i      (clk),
    .rst_ni     (rst_n),
    .test_en_i  (1'b0),
    .axi_slave  (axi),
    .apb_master (apb)
  );

  // ---------------------------------------------------------
  // Protocol assertions (testbench-only; DUT remains unchanged)
  // ---------------------------------------------------------
  axi2apb_protocol_assertions protocol_checks (
    .clk(clk), .rst_n(rst_n),
    .aw_valid(axi.aw_valid), .aw_ready(axi.aw_ready), .aw_addr(axi.aw_addr), .aw_id(axi.aw_id),
    .w_valid(axi.w_valid), .w_ready(axi.w_ready), .w_data(axi.w_data), .w_strb(axi.w_strb),
    .ar_valid(axi.ar_valid), .ar_ready(axi.ar_ready), .ar_addr(axi.ar_addr), .ar_id(axi.ar_id),
    .b_valid(axi.b_valid), .b_ready(axi.b_ready), .b_resp(axi.b_resp),
    .r_valid(axi.r_valid), .r_ready(axi.r_ready), .r_data(axi.r_data), .r_resp(axi.r_resp), .r_last(axi.r_last),
    .psel(apb.psel), .penable(apb.penable), .pwrite(apb.pwrite), .pready(apb.pready), .paddr(apb.paddr), .pwdata(apb.pwdata)
  );

  // ---------------------------------------------------------
  // FIFO-state evidence (testbench-only covers on DUT internals).
  // Replaces the unreachable initial-block asserts in fifo.sv as proof that
  // each buffer really reached full and saw simultaneous push+pop.
  // ---------------------------------------------------------
  c_aw_fifo_full: cover property (@(posedge clk) disable iff (!rst_n) dut.genblk1.axi2apb_i.slave_aw_buffer_i.i_axi_single_slice.i_fifo.full_o);
  c_aw_fifo_push_pop_mid: cover property (@(posedge clk) disable iff (!rst_n)
      dut.genblk1.axi2apb_i.slave_aw_buffer_i.i_axi_single_slice.i_fifo.push_i && dut.genblk1.axi2apb_i.slave_aw_buffer_i.i_axi_single_slice.i_fifo.pop_i && !dut.genblk1.axi2apb_i.slave_aw_buffer_i.i_axi_single_slice.i_fifo.full_o && !dut.genblk1.axi2apb_i.slave_aw_buffer_i.i_axi_single_slice.i_fifo.empty_o);
  c_w_fifo_full: cover property (@(posedge clk) disable iff (!rst_n) dut.genblk1.axi2apb_i.slave_w_buffer_i.i_axi_single_slice.i_fifo.full_o);
  c_w_fifo_push_pop_mid: cover property (@(posedge clk) disable iff (!rst_n)
      dut.genblk1.axi2apb_i.slave_w_buffer_i.i_axi_single_slice.i_fifo.push_i && dut.genblk1.axi2apb_i.slave_w_buffer_i.i_axi_single_slice.i_fifo.pop_i && !dut.genblk1.axi2apb_i.slave_w_buffer_i.i_axi_single_slice.i_fifo.full_o && !dut.genblk1.axi2apb_i.slave_w_buffer_i.i_axi_single_slice.i_fifo.empty_o);
  c_ar_fifo_full: cover property (@(posedge clk) disable iff (!rst_n) dut.genblk1.axi2apb_i.slave_ar_buffer_i.i_axi_single_slice.i_fifo.full_o);
  c_ar_fifo_push_pop_mid: cover property (@(posedge clk) disable iff (!rst_n)
      dut.genblk1.axi2apb_i.slave_ar_buffer_i.i_axi_single_slice.i_fifo.push_i && dut.genblk1.axi2apb_i.slave_ar_buffer_i.i_axi_single_slice.i_fifo.pop_i && !dut.genblk1.axi2apb_i.slave_ar_buffer_i.i_axi_single_slice.i_fifo.full_o && !dut.genblk1.axi2apb_i.slave_ar_buffer_i.i_axi_single_slice.i_fifo.empty_o);
  c_b_fifo_full: cover property (@(posedge clk) disable iff (!rst_n) dut.genblk1.axi2apb_i.slave_b_buffer.i_axi_single_slice.i_fifo.full_o);
  c_b_fifo_push_pop_mid: cover property (@(posedge clk) disable iff (!rst_n)
      dut.genblk1.axi2apb_i.slave_b_buffer.i_axi_single_slice.i_fifo.push_i && dut.genblk1.axi2apb_i.slave_b_buffer.i_axi_single_slice.i_fifo.pop_i && !dut.genblk1.axi2apb_i.slave_b_buffer.i_axi_single_slice.i_fifo.full_o && !dut.genblk1.axi2apb_i.slave_b_buffer.i_axi_single_slice.i_fifo.empty_o);
  c_r_fifo_full: cover property (@(posedge clk) disable iff (!rst_n) dut.genblk1.axi2apb_i.slave_r_buffer_i.i_axi_single_slice.i_fifo.full_o);
  c_r_fifo_push_pop_mid: cover property (@(posedge clk) disable iff (!rst_n)
      dut.genblk1.axi2apb_i.slave_r_buffer_i.i_axi_single_slice.i_fifo.push_i && dut.genblk1.axi2apb_i.slave_r_buffer_i.i_axi_single_slice.i_fifo.pop_i && !dut.genblk1.axi2apb_i.slave_r_buffer_i.i_axi_single_slice.i_fifo.full_o && !dut.genblk1.axi2apb_i.slave_r_buffer_i.i_axi_single_slice.i_fifo.empty_o);

  // ---------------------------------------------------------
  // UVM CONFIGURATION
  // ---------------------------------------------------------
  initial begin

    uvm_config_db#(virtual AXI_BUS)::set(
      null,
      "*",
      "axi_vif",
      axi
    );

    uvm_config_db#(virtual APB_BUS)::set(
      null,
      "*",
      "apb_vif",
      apb
    );

    run_test();

  end

  // ---------------------------------------------------------
  // WAVEFORM DUMP (waveform_<testname>.vpd, view with `make gui TEST=<testname>`)
  // ---------------------------------------------------------
  string test_name;

  initial begin
    if (!$value$plusargs("UVM_TESTNAME=%s", test_name))
      test_name = "default";

    $vcdplusfile({"waveform_", test_name, ".vpd"});
    $vcdpluson(0, smoke_tb);
  end

  // ---------------------------------------------------------
  // TIMEOUT WATCHDOG
  // ---------------------------------------------------------
  initial begin
    #9200000;

    `uvm_fatal(
      "TIMEOUT",
      "Simulation timed out. Check AXI/APB handshakes."
    )
  end

endmodule

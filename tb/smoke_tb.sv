`timescale 1ns/1ps

module smoke_tb;

    parameter AXI_ADDR_WIDTH = 32;
    parameter AXI_DATA_WIDTH = 32;
    parameter AXI_USER_WIDTH = 6;
    parameter AXI_ID_WIDTH   = 6;
    parameter APB_ADDR_WIDTH = 32;
    parameter APB_DATA_WIDTH = 32;

    logic clk;
    logic rst_n;
    logic test_en;

    AXI_BUS #(
        .AXI_ADDR_WIDTH (AXI_ADDR_WIDTH),
        .AXI_DATA_WIDTH (AXI_DATA_WIDTH),
        .AXI_ID_WIDTH   (AXI_ID_WIDTH),
        .AXI_USER_WIDTH (AXI_USER_WIDTH)
    ) axi();

    APB_BUS #(
        .APB_ADDR_WIDTH (APB_ADDR_WIDTH),
        .APB_DATA_WIDTH (APB_DATA_WIDTH)
    ) apb();

    // DUT
    axi2apb_wrap #(
        .AXI_ADDR_WIDTH (AXI_ADDR_WIDTH),
        .AXI_DATA_WIDTH (AXI_DATA_WIDTH),
        .AXI_USER_WIDTH (AXI_USER_WIDTH),
        .AXI_ID_WIDTH   (AXI_ID_WIDTH),
        .APB_ADDR_WIDTH (APB_ADDR_WIDTH),
        .APB_DATA_WIDTH (APB_DATA_WIDTH)
    ) dut (
        .clk_i      (clk),
        .rst_ni     (rst_n),
        .test_en_i  (test_en),

        .axi_slave  (axi),
        .apb_master (apb)
    );

    // Clock
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // Simple APB response
    initial begin
        apb.pready  = 1'b1;
        apb.prdata  = 32'h1234_5678;
        apb.pslverr = 1'b0;
    end

    // Reset + smoke
    initial begin
        test_en = 1'b0;

        // Initialize AXI inputs
        axi.aw_id    = '0;
        axi.aw_addr  = '0;
        axi.aw_len   = '0;
        axi.aw_size  = 3'd2;
        axi.aw_burst = 2'b01;
        axi.aw_lock  = 1'b0;
        axi.aw_cache = '0;
        axi.aw_prot  = '0;
        axi.aw_region = '0;
        axi.aw_user  = '0;
        axi.aw_qos   = '0;
        axi.aw_valid = 1'b0;

        axi.w_data  = '0;
        axi.w_strb  = '0;
        axi.w_last  = 1'b1;
        axi.w_user  = '0;
        axi.w_valid = 1'b0;

        axi.b_ready = 1'b1;

        axi.ar_id    = '0;
        axi.ar_addr  = '0;
        axi.ar_len   = '0;
        axi.ar_size  = 3'd2;
        axi.ar_burst = 2'b01;
        axi.ar_lock  = 1'b0;
        axi.ar_cache = '0;
        axi.ar_prot  = '0;
        axi.ar_region = '0;
        axi.ar_user  = '0;
        axi.ar_qos   = '0;
        axi.ar_valid = 1'b0;

        axi.r_ready = 1'b1;

        // Reset
        rst_n = 1'b0;
        repeat (3) @(posedge clk);

        rst_n = 1'b1;
        repeat (3) @(posedge clk);

        $display("======================================");
        $display(" AXI2APB SMOKE TEST STARTED");
        $display("======================================");

        // -------------------------
        // Simple AXI WRITE
        // -------------------------
        @(posedge clk);

        axi.aw_id    <= 6'd1;
        axi.aw_addr  <= 32'h0000_0010;
        axi.aw_valid <= 1'b1;

        axi.w_data   <= 32'hDEAD_BEEF;
        axi.w_strb   <= 4'b1111;
        axi.w_last   <= 1'b1;
        axi.w_valid  <= 1'b1;

        wait (axi.aw_ready && axi.w_ready);

        @(posedge clk);

        axi.aw_valid <= 1'b0;
        axi.w_valid  <= 1'b0;

        $display("WRITE transaction sent");

        wait (axi.b_valid);

        $display("WRITE RESPONSE received: BRESP=%0d",
                 axi.b_resp);

        @(posedge clk);

        // -------------------------
        // Simple AXI READ
        // -------------------------
        axi.ar_id    <= 6'd2;
        axi.ar_addr  <= 32'h0000_0020;
        axi.ar_valid <= 1'b1;

        wait (axi.ar_ready);

        @(posedge clk);

        axi.ar_valid <= 1'b0;

        $display("READ transaction sent");

        wait (axi.r_valid);

        $display("READ RESPONSE received: RDATA=%h",
                 axi.r_data);

        @(posedge clk);

        $display("======================================");
        $display(" AXI2APB SMOKE TEST FINISHED");
        $display("======================================");

        #20;
        $finish;
    end

endmodule
module uvm_tb;

    // =========================================================
    // Clock and Reset
    // =========================================================

    logic clk;
    logic rst_n;
    logic test_en;


    // Clock generation
    initial begin
        clk = 1'b0;

        forever begin
            #5 clk = ~clk;
        end
    end


    // Reset generation
    initial begin
        rst_n = 1'b0;

        repeat (5) @(posedge clk);

        rst_n = 1'b1;
    end


    // Test enable
    initial begin
        test_en = 1'b0;
    end


    // =========================================================
    // AXI and APB Interfaces
    // =========================================================

    AXI_BUS axi();
    APB_BUS apb();


    // Connect common clock to interfaces
    assign axi.clk = clk;
    assign apb.clk = clk;


    // =========================================================
    // DUT
    // =========================================================

    axi2apb_wrap dut (
        .clk_i      (clk),
        .rst_ni     (rst_n),
        .test_en_i  (test_en),

        .axi_slave  (axi),
        .apb_master (apb)
    );


    // =========================================================
    // APB DEBUG MONITOR
    // =========================================================

initial begin
    forever begin
        @(posedge clk);

        if (apb.psel && apb.penable) begin
            $display(
                "TIME=%0t | APB: PSEL=%b PENABLE=%b PWRITE=%b ADDR=%h DATA=%h READY=%b",
                $time,
                apb.psel,
                apb.penable,
                apb.pwrite,
                apb.paddr,
                apb.pwdata,
                apb.pready
            );
        end
    end
end

        

 


    // =========================================================
    // UVM CONFIGURATION
    // =========================================================

    initial begin

        // Give AXI virtual interface to UVM
        uvm_config_db #(virtual AXI_BUS)::set(
            null,
            "*",
            "axi_vif",
            axi
        );


        // Give APB virtual interface to UVM
        uvm_config_db #(virtual APB_BUS)::set(
            null,
            "*",
            "apb_vif",
            apb
        );


        // Start UVM test
        run_test("axi2apb_test");

    end

endmodule
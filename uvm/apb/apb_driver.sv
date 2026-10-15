class apb_driver extends uvm_driver #(apb_transaction);

    `uvm_component_utils(apb_driver)

    virtual APB_BUS apb_vif;

    bit [31:0] mem [bit [31:0]];

    // Response configuration (set through config_db, defaults = no delay, no error)
    int unsigned min_wait = 0;   // minimum PREADY wait cycles
    int unsigned max_wait = 0;   // maximum PREADY wait cycles
    bit          slverr_en = 0;  // drive PSLVERR with every response
    // True zero-wait slave: PREADY is held high and PRDATA follows PADDR
    // combinationally, so PREADY is already high in the first PENABLE cycle.
    // The reactive default mode can never do this (it needs >=1 cycle to see
    // PENABLE), which left the DUT's "IDLE && PREADY" paths unexercised.
    bit          zero_wait = 0;


    function new(
        string name = "apb_driver",
        uvm_component parent = null
    );
        super.new(name, parent);
    endfunction


    function void build_phase(uvm_phase phase);

        super.build_phase(phase);

        void'(uvm_config_db #(int unsigned)::get(this, "", "min_wait",  min_wait));
        void'(uvm_config_db #(int unsigned)::get(this, "", "max_wait",  max_wait));
        void'(uvm_config_db #(bit)::get(this, "", "slverr_en", slverr_en));
        void'(uvm_config_db #(bit)::get(this, "", "zero_wait", zero_wait));

        if (!uvm_config_db #(virtual APB_BUS)::get(
                this,
                "",
                "apb_vif",
                apb_vif
            )) begin

            `uvm_fatal(
                "APB_DRV",
                "APB virtual interface not found"
            )

        end

    endfunction


    // Zero-wait APB slave (see zero_wait). Memory model is shared with the
    // reactive mode; writes are captured on the ACCESS edge, read data is
    // refreshed whenever the address/phase changes and after every write.
    virtual task run_zero_wait();
        apb_vif.pready  <= 1'b1;
        apb_vif.pslverr <= slverr_en;
        fork
            forever begin
                apb_vif.prdata <= mem.exists(apb_vif.paddr) ? mem[apb_vif.paddr] : 32'h0;
                @(apb_vif.paddr or apb_vif.penable or apb_vif.pwrite);
            end
            forever begin
                @(posedge apb_vif.clk);
                if (apb_vif.psel === 1'b1 && apb_vif.penable === 1'b1 && apb_vif.pwrite === 1'b1) begin
                    mem[apb_vif.paddr] = apb_vif.pwdata;
                    apb_vif.prdata <= apb_vif.pwdata;   // keep read data coherent if paddr stays put
                end
            end
        join
    endtask

    virtual task run_phase(uvm_phase phase);

        apb_vif.pready  <= 1'b0;
        apb_vif.prdata  <= 32'h00000000;
        apb_vif.pslverr <= 1'b0;

        if (zero_wait) run_zero_wait();   // never returns

        forever begin

            @(posedge apb_vif.clk);

            // Wait for actual APB ACCESS phase.
            // PSEL is permanently 1 in this DUT.
            if (apb_vif.penable === 1'b1) begin
                apb_transaction rsp_cfg;
                bit have_rsp_cfg;
                int unsigned selected_wait;
                bit selected_slverr;

                // UVM-1.2: try_next_item is a task; rsp_cfg stays null when no item is pending.
                rsp_cfg = null;
                seq_item_port.try_next_item(rsp_cfg);
                have_rsp_cfg = (rsp_cfg != null);
                selected_wait = have_rsp_cfg ? rsp_cfg.wait_cycles : $urandom_range(max_wait, min_wait);
                selected_slverr = have_rsp_cfg ? rsp_cfg.slverr : slverr_en;

                `uvm_info(
                    "APB_DRV",
                    $sformatf(
                        "APB ACCESS: WRITE=%b ADDR=%h WDATA=%h",
                        apb_vif.pwrite,
                        apb_vif.paddr,
                        apb_vif.pwdata
                    ),
                    UVM_MEDIUM
                );


                if (apb_vif.pwrite === 1'b1) begin

                    mem[apb_vif.paddr] = apb_vif.pwdata;

                    `uvm_info(
                        "APB_DRV",
                        $sformatf(
                            "APB WRITE: ADDR=%h DATA=%h",
                            apb_vif.paddr,
                            apb_vif.pwdata
                        ),
                        UVM_MEDIUM
                    );

                end
                else begin

                    if (have_rsp_cfg && rsp_cfg.use_rdata)
                        apb_vif.prdata <= rsp_cfg.response_data;
                    else if (mem.exists(apb_vif.paddr))
                        apb_vif.prdata <= mem[apb_vif.paddr];
                    else
                        apb_vif.prdata <= 32'h00000000;

                    `uvm_info(
                        "APB_DRV",
                        $sformatf(
                            "APB READ: ADDR=%h DATA=%h",
                            apb_vif.paddr,
                            (have_rsp_cfg && rsp_cfg.use_rdata)
                                ? rsp_cfg.response_data
                                : (mem.exists(apb_vif.paddr) ? mem[apb_vif.paddr] : 32'h00000000)
                        ),
                        UVM_MEDIUM
                    );

                end


                // Insert programmable wait states before completing.
                repeat (selected_wait)
                    @(posedge apb_vif.clk);

                apb_vif.pslverr <= selected_slverr;

                // Complete APB ACCESS
                apb_vif.pready <= 1'b1;

                `uvm_info(
                    "APB_DRV",
                    "APB ACCESS: PREADY=1",
                    UVM_MEDIUM
                );

                @(posedge apb_vif.clk);

                apb_vif.pready  <= 1'b0;
                apb_vif.prdata  <= 32'h00000000;
                apb_vif.pslverr <= 1'b0;
                if (have_rsp_cfg)
                    seq_item_port.item_done();

            end

        end

    endtask

endclass
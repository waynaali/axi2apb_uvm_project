class apb_driver extends uvm_component;

    `uvm_component_utils(apb_driver)

    virtual apb_if apb_vif;

    function new(string name = "apb_driver",
                 uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        if (!uvm_config_db#(virtual apb_if)::get(
                this,
                "",
                "vif",
                apb_vif
            )) begin

            `uvm_fatal(
                "NOVIF",
                "APB virtual interface not found"
            )

        end
    endfunction


    virtual task run_phase(uvm_phase phase);

        apb_vif.pready  <= 1'b0;
        apb_vif.prdata  <= 32'h0;
        apb_vif.pslverr <= 1'b0;

        forever begin

            @(posedge apb_vif.clk);

            if (apb_vif.psel && apb_vif.penable) begin

                `uvm_info(
                    "APB_DRIVER",
                    $sformatf(
                        "APB ACCESS: ADDR=%h WRITE=%0d WDATA=%h",
                        apb_vif.paddr,
                        apb_vif.pwrite,
                        apb_vif.pwdata
                    ),
                    UVM_MEDIUM
                )

                apb_vif.pready  <= 1'b1;
                apb_vif.pslverr <= 1'b0;

                if (apb_vif.pwrite) begin

                    apb_vif.prdata <= 32'h0000_0000;

                    `uvm_info(
                        "APB_DRIVER",
                        $sformatf(
                            "APB WRITE: ADDR=%h DATA=%h",
                            apb_vif.paddr,
                            apb_vif.pwdata
                        ),
                        UVM_MEDIUM
                    )

                end

                else begin

                    apb_vif.prdata <= 32'h1234_5678;

                    `uvm_info(
                        "APB_DRIVER",
                        $sformatf(
                            "APB READ: ADDR=%h RDATA=%h",
                            apb_vif.paddr,
                            32'h1234_5678
                        ),
                        UVM_MEDIUM
                    )

                end

            end

            else begin

                apb_vif.pready  <= 1'b0;
                apb_vif.prdata  <= 32'h0;
                apb_vif.pslverr <= 1'b0;

            end

        end

    endtask

endclass
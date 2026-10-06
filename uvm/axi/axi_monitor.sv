class axi_monitor extends uvm_monitor;

    `uvm_component_utils(axi_monitor)

    virtual AXI_BUS axi_vif;

    uvm_analysis_port #(axi_transaction) analysis_port;

    function new(
        string name = "axi_monitor",
        uvm_component parent = null
    );
        super.new(name, parent);
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        analysis_port = new("analysis_port", this);

        if (!uvm_config_db #(virtual AXI_BUS)::get(
                this,
                "",
                "axi_vif",
                axi_vif
            )) begin
            `uvm_fatal("AXI_MON",
                       "AXI virtual interface not found")
        end
    endfunction

    virtual task run_phase(uvm_phase phase);

        forever begin

            @(posedge axi_vif.clk);

            // -------------------------
            // WRITE ADDRESS CHANNEL
            // -------------------------
            if (axi_vif.aw_valid && axi_vif.aw_ready) begin

                axi_transaction tr;
                tr = axi_transaction::type_id::create("write_mon");

                tr.is_write = 1'b1;
                tr.id       = axi_vif.aw_id;
                tr.addr     = axi_vif.aw_addr;

                `uvm_info(
                    "AXI_MON",
                    $sformatf(
                        "WRITE ADDRESS: ID=%0d ADDR=%h",
                        tr.id,
                        tr.addr
                    ),
                    UVM_MEDIUM
                )

                // Wait for write data
                @(posedge axi_vif.clk);

                if (axi_vif.w_valid && axi_vif.w_ready) begin
                    tr.data = axi_vif.w_data;
                    tr.strb = axi_vif.w_strb;

                    `uvm_info(
                        "AXI_MON",
                        $sformatf(
                            "WRITE DATA: DATA=%h STRB=%h",
                            tr.data,
                            tr.strb
                        ),
                        UVM_MEDIUM
                    )
                end

                // Wait for write response
                wait (axi_vif.b_valid);

                tr.resp = axi_vif.b_resp;

                `uvm_info(
                    "AXI_MON",
                    $sformatf(
                        "WRITE RESPONSE: RESP=%0d",
                        tr.resp
                    ),
                    UVM_MEDIUM
                )

                analysis_port.write(tr);
            end

            // -------------------------
            // READ ADDRESS CHANNEL
            // -------------------------
            if (axi_vif.ar_valid && axi_vif.ar_ready) begin

                axi_transaction tr;
                tr = axi_transaction::type_id::create("read_mon");

                tr.is_write = 1'b0;
                tr.id       = axi_vif.ar_id;
                tr.addr     = axi_vif.ar_addr;

                `uvm_info(
                    "AXI_MON",
                    $sformatf(
                        "READ ADDRESS: ID=%0d ADDR=%h",
                        tr.id,
                        tr.addr
                    ),
                    UVM_MEDIUM
                )

                // Wait for read response
                wait (axi_vif.r_valid);

                tr.data = axi_vif.r_data;
                tr.resp = axi_vif.r_resp;

                `uvm_info(
                    "AXI_MON",
                    $sformatf(
                        "READ RESPONSE: DATA=%h RESP=%0d",
                        tr.data,
                        tr.resp
                    ),
                    UVM_MEDIUM
                )

                analysis_port.write(tr);
            end

        end

    endtask

endclass
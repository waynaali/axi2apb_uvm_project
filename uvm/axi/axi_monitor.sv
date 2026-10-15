class axi_monitor extends uvm_monitor;

    `uvm_component_utils(axi_monitor)

    virtual AXI_BUS axi_vif;

    uvm_analysis_port #(axi_transaction) analysis_port;


    // ------------------------------------------------
    // Pending write information
    // ------------------------------------------------

    // Queues (not single slots) so several AW/W/AR can be outstanding when the
    // DUT buffers fill. With one outstanding transfer they behave exactly like
    // the old single pending slot.
    bit [5:0]  aw_id_q[$];
    bit [31:0] aw_addr_q[$];
    bit [5:0]  aw_user_q[$];
    bit [31:0] w_data_q[$];
    bit [3:0]  w_strb_q[$];
    axi_transaction ar_q[$];


    function new(
        string name = "axi_monitor",
        uvm_component parent = null
    );

        super.new(name, parent);

    endfunction


    // ------------------------------------------------
    // BUILD
    // ------------------------------------------------

    virtual function void build_phase(uvm_phase phase);

        super.build_phase(phase);

        analysis_port = new(
            "analysis_port",
            this
        );

        if (!uvm_config_db #(virtual AXI_BUS)::get(
                this,
                "",
                "axi_vif",
                axi_vif
            )) begin

            `uvm_fatal(
                "AXI_MON",
                "AXI virtual interface not found"
            );

        end

    endfunction


    // ------------------------------------------------
    // RUN
    // ------------------------------------------------

    virtual task run_phase(uvm_phase phase);

        forever begin

            @(posedge axi_vif.clk);


            // =========================================
            // WRITE ADDRESS CHANNEL
            // =========================================

            if (
                axi_vif.aw_valid &&
                axi_vif.aw_ready
            ) begin

                aw_id_q.push_back(axi_vif.aw_id);
                aw_addr_q.push_back(axi_vif.aw_addr);
                aw_user_q.push_back(axi_vif.aw_user);

                `uvm_info(
                    "AXI_MON",
                    $sformatf(
                        "WRITE ADDRESS: ID=%0d ADDR=%h",
                        axi_vif.aw_id,
                        axi_vif.aw_addr
                    ),
                    UVM_MEDIUM
                );

            end


            // =========================================
            // WRITE DATA CHANNEL
            // =========================================

            if (
                axi_vif.w_valid &&
                axi_vif.w_ready
            ) begin

                w_data_q.push_back(axi_vif.w_data);
                w_strb_q.push_back(axi_vif.w_strb);

                `uvm_info(
                    "AXI_MON",
                    $sformatf(
                        "WRITE DATA: DATA=%h STRB=%h",
                        axi_vif.w_data,
                        axi_vif.w_strb
                    ),
                    UVM_MEDIUM
                );

            end


            // =========================================
            // WRITE RESPONSE
            // =========================================

            if (
                (aw_id_q.size() > 0) &&
                (w_data_q.size() > 0) &&
                axi_vif.b_valid &&
                axi_vif.b_ready
            ) begin

                axi_transaction tr;

                tr = axi_transaction::type_id::create(
                    "write_mon"
                );

                tr.is_write = 1'b1;
                tr.id       = aw_id_q.pop_front();
                tr.user     = aw_user_q.pop_front();
                tr.response_id = axi_vif.b_id;
                tr.response_user = axi_vif.b_user;
                tr.addr     = aw_addr_q.pop_front();
                tr.data     = w_data_q.pop_front();
                tr.strb     = w_strb_q.pop_front();
                tr.resp     = axi_vif.b_resp;


                `uvm_info(
                    "AXI_MON",
                    $sformatf(
                        "WRITE COMPLETE: ID=%0d ADDR=%h DATA=%h RESP=%0d",
                        tr.id,
                        tr.addr,
                        tr.data,
                        tr.resp
                    ),
                    UVM_MEDIUM
                );


                analysis_port.write(tr);



            end


            // =========================================
            // READ RESPONSE (matched to oldest outstanding AR)
            // =========================================

            if (axi_vif.r_valid && axi_vif.r_ready && (ar_q.size() > 0)) begin
                axi_transaction rtr;
                rtr = ar_q.pop_front();
                rtr.data = axi_vif.r_data;
                rtr.resp = axi_vif.r_resp;
                rtr.response_id = axi_vif.r_id;
                rtr.response_user = axi_vif.r_user;
                `uvm_info("AXI_MON", $sformatf("READ COMPLETE: ID=%0d ADDR=%h DATA=%h RESP=%0d",
                          rtr.id, rtr.addr, rtr.data, rtr.resp), UVM_MEDIUM);
                analysis_port.write(rtr);
            end

            // =========================================
            // READ ADDRESS CHANNEL
            // =========================================

            if (
                axi_vif.ar_valid &&
                axi_vif.ar_ready
            ) begin

                axi_transaction tr;

                tr = axi_transaction::type_id::create(
                    "read_mon"
                );

                tr.is_write = 1'b0;
                tr.id       = axi_vif.ar_id;
                tr.user     = axi_vif.ar_user;
                tr.addr     = axi_vif.ar_addr;


                `uvm_info(
                    "AXI_MON",
                    $sformatf(
                        "READ ADDRESS: ID=%0d ADDR=%h",
                        tr.id,
                        tr.addr
                    ),
                    UVM_MEDIUM
                );


                ar_q.push_back(tr);

            end

        end

    endtask

endclass
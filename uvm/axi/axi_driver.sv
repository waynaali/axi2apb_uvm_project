class axi_driver extends uvm_driver #(axi_transaction);

    `uvm_component_utils(axi_driver)

    // AXI virtual interface
    virtual AXI_BUS axi_vif;

    function new(
        string name = "axi_driver",
        uvm_component parent = null
    );
        super.new(name, parent);
    endfunction


    // Get virtual interface
    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        if (!uvm_config_db #(virtual AXI_BUS)::get(
                this,
                "",
                "axi_vif",
                axi_vif
            )) begin

            `uvm_fatal("AXI_DRV",
                       "AXI virtual interface not found")

        end
    endfunction


    // Driver main loop
    virtual task run_phase(uvm_phase phase);

        axi_transaction req;

        forever begin

            seq_item_port.get_next_item(req);

            if (req.is_write)
                drive_write(req);
            else
                drive_read(req);

            seq_item_port.item_done();

        end

    endtask


    // ------------------------------------------------
    // AXI WRITE
    // ------------------------------------------------

    virtual task drive_write(axi_transaction req);

        // -------------------------
        // AW channel
        // -------------------------

        @(posedge axi_vif.clk);

        axi_vif.aw_id    <= req.id;
        axi_vif.aw_addr  <= req.addr;
        axi_vif.aw_len   <= 8'd0;
        axi_vif.aw_size  <= 3'd2;
        axi_vif.aw_burst <= 2'b01;
        axi_vif.aw_lock  <= 1'b0;
        axi_vif.aw_cache <= 4'b0;
        axi_vif.aw_prot  <= 3'b0;
        axi_vif.aw_region<= 4'b0;
        axi_vif.aw_user  <= '0;
        axi_vif.aw_qos   <= 4'b0;

        axi_vif.aw_valid <= 1'b1;

        wait (axi_vif.aw_ready);

        @(posedge axi_vif.clk);

        axi_vif.aw_valid <= 1'b0;


        // -------------------------
        // W channel
        // -------------------------

        axi_vif.w_data  <= req.data;
        axi_vif.w_strb  <= req.strb;
        axi_vif.w_last  <= 1'b1;
        axi_vif.w_user  <= '0;
        axi_vif.w_valid <= 1'b1;

        wait (axi_vif.w_ready);

        @(posedge axi_vif.clk);

        axi_vif.w_valid <= 1'b0;


        // -------------------------
        // B channel
        // -------------------------

        axi_vif.b_ready <= 1'b1;

        wait (axi_vif.b_valid);

        req.resp = axi_vif.b_resp;

        @(posedge axi_vif.clk);

        axi_vif.b_ready <= 1'b0;

        `uvm_info(
            "AXI_DRIVER",
            $sformatf(
                "WRITE: ADDR=%h DATA=%h RESP=%0d",
                req.addr,
                req.data,
                req.resp
            ),
            UVM_MEDIUM
        )

    endtask


    // ------------------------------------------------
    // AXI READ
    // ------------------------------------------------

    virtual task drive_read(axi_transaction req);

        // -------------------------
        // AR channel
        // -------------------------

        @(posedge axi_vif.clk);

        axi_vif.ar_id     <= req.id;
        axi_vif.ar_addr   <= req.addr;
        axi_vif.ar_len    <= 8'd0;
        axi_vif.ar_size   <= 3'd2;
        axi_vif.ar_burst  <= 2'b01;
        axi_vif.ar_lock   <= 1'b0;
        axi_vif.ar_cache  <= 4'b0;
        axi_vif.ar_prot   <= 3'b0;
        axi_vif.ar_region <= 4'b0;
        axi_vif.ar_user   <= '0;
        axi_vif.ar_qos    <= 4'b0;

        axi_vif.ar_valid <= 1'b1;

        wait (axi_vif.ar_ready);

        @(posedge axi_vif.clk);

        axi_vif.ar_valid <= 1'b0;


        // -------------------------
        // R channel
        // -------------------------

        axi_vif.r_ready <= 1'b1;

        wait (axi_vif.r_valid);

        req.data = axi_vif.r_data;
        req.resp = axi_vif.r_resp;

        @(posedge axi_vif.clk);

        axi_vif.r_ready <= 1'b0;

        `uvm_info(
            "AXI_DRIVER",
            $sformatf(
                "READ: ADDR=%h DATA=%h RESP=%0d",
                req.addr,
                req.data,
                req.resp
            ),
            UVM_MEDIUM
        )

    endtask

endclass
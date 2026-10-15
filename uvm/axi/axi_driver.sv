class axi_driver extends uvm_driver #(axi_transaction);

    `uvm_component_utils(axi_driver)

    virtual AXI_BUS axi_vif;

    // Backpressure configuration (config_db), cycles to hold BREADY/RREADY low
    int unsigned b_delay = 0;
    int unsigned r_delay = 0;

    // Pipelined/FIFO-fill mode. In pipe_mode the driver does not wait for B/R;
    // BREADY/RREADY are owned by a background responder gated by rsp_ready_en.
    bit pipe_mode    = 1'b0;
    bit rsp_ready_en = 1'b0;
    bit rsp_random   = 1'b0;   // when set, BREADY/RREADY toggle randomly instead


    function new(
        string name = "axi_driver",
        uvm_component parent = null
    );
        super.new(name, parent);
    endfunction


    // ------------------------------------------------
    // BUILD PHASE
    // ------------------------------------------------

    virtual function void build_phase(uvm_phase phase);

        super.build_phase(phase);

        void'(uvm_config_db #(int unsigned)::get(this, "", "b_delay", b_delay));
        void'(uvm_config_db #(int unsigned)::get(this, "", "r_delay", r_delay));

        if (!uvm_config_db #(virtual AXI_BUS)::get(
                this,
                "",
                "axi_vif",
                axi_vif
            )) begin

            `uvm_fatal(
                "AXI_DRV",
                "AXI virtual interface not found"
            )

        end

    endfunction


    // ------------------------------------------------
    // RUN PHASE
    // ------------------------------------------------

    virtual task run_phase(uvm_phase phase);

        axi_transaction req;

        // Initialize AXI outputs
        axi_vif.aw_valid <= 1'b0;
        axi_vif.w_valid  <= 1'b0;
        axi_vif.ar_valid <= 1'b0;

        axi_vif.b_ready  <= 1'b0;
        axi_vif.r_ready  <= 1'b0;

        axi_vif.aw_id    <= '0;
        axi_vif.aw_addr  <= '0;
        axi_vif.aw_len   <= '0;
        axi_vif.aw_size  <= '0;
        axi_vif.aw_burst <= '0;
        axi_vif.aw_lock  <= '0;
        axi_vif.aw_cache <= '0;
        axi_vif.aw_prot  <= '0;
        axi_vif.aw_region<= '0;
        axi_vif.aw_user  <= '0;
        axi_vif.aw_qos   <= '0;

        axi_vif.w_data   <= '0;
        axi_vif.w_strb   <= '0;
        axi_vif.w_last   <= 1'b0;
        axi_vif.w_user   <= '0;

        axi_vif.ar_id    <= '0;
        axi_vif.ar_addr  <= '0;
        axi_vif.ar_len   <= '0;
        axi_vif.ar_size  <= '0;
        axi_vif.ar_burst <= '0;
        axi_vif.ar_lock  <= '0;
        axi_vif.ar_cache <= '0;
        axi_vif.ar_prot  <= '0;
        axi_vif.ar_region<= '0;
        axi_vif.ar_user  <= '0;
        axi_vif.ar_qos   <= '0;


        // Wait out reset (tb releases rst_n at the 5th clock edge).
        // Without this, ready=1 during reset made the driver drop valid
        // and the transfer was lost -> hang waiting for BVALID/RVALID.
        repeat (10) @(posedge axi_vif.clk);

        // Background BREADY/RREADY owner, active only in pipe_mode.
        fork
            forever begin
                @(negedge axi_vif.clk);
                if (pipe_mode) begin
                    if (rsp_random) begin
                        axi_vif.b_ready <= $urandom_range(0, 1);
                        axi_vif.r_ready <= $urandom_range(0, 1);
                    end else begin
                        axi_vif.b_ready <= rsp_ready_en;
                        axi_vif.r_ready <= rsp_ready_en;
                    end
                end
            end
        join_none

        forever begin

            seq_item_port.get_next_item(req);

            if (req.issue_only && req.is_write)
                drive_write_issue(req);
            else if (req.issue_only)
                drive_read_issue(req);
            else if (req.both_req)
                drive_simultaneous_read_write(req);
            else if (req.is_write)
                drive_write(req);
            else
                drive_read(req);

            seq_item_port.item_done();

        end

    endtask



    // Launch AW and AR together. The supplied DUT is expected to select AR
    // first when both requests are visible in IDLE. The same address/ID are
    // deliberately used so the existing transaction scoreboard can correlate
    // the two completions without inventing unsupported burst behavior.
    virtual task drive_simultaneous_read_write(axi_transaction req);
        bit aw_done, ar_done, b_done, r_done;

        aw_done = 0; ar_done = 0; b_done = 0; r_done = 0;
        @(negedge axi_vif.clk);
        axi_vif.aw_id <= req.id;
        axi_vif.aw_addr <= req.addr;
        axi_vif.aw_len <= 0; axi_vif.aw_size <= req.ctl_size; axi_vif.aw_burst <= req.ctl_burst;
        axi_vif.aw_lock <= req.ctl_lock; axi_vif.aw_cache <= req.ctl_cache; axi_vif.aw_prot <= req.ctl_prot;
        axi_vif.aw_region <= req.ctl_region; axi_vif.aw_user <= req.user; axi_vif.aw_qos <= req.ctl_qos;
        axi_vif.ar_id <= req.id;
        axi_vif.ar_addr <= req.addr;
        axi_vif.ar_len <= 0; axi_vif.ar_size <= req.ctl_size; axi_vif.ar_burst <= req.ctl_burst;
        axi_vif.ar_lock <= req.ctl_lock; axi_vif.ar_cache <= req.ctl_cache; axi_vif.ar_prot <= req.ctl_prot;
        axi_vif.ar_region <= req.ctl_region; axi_vif.ar_user <= req.user; axi_vif.ar_qos <= req.ctl_qos;
        axi_vif.aw_valid <= 1; axi_vif.ar_valid <= 1;

        while (!(aw_done && ar_done)) begin
            @(posedge axi_vif.clk);
            if (!aw_done && axi_vif.aw_ready === 1'b1) begin
                aw_done = 1;
                axi_vif.aw_valid <= 0;
            end
            if (!ar_done && axi_vif.ar_ready === 1'b1) begin
                ar_done = 1;
                axi_vif.ar_valid <= 0;
            end
        end

        @(negedge axi_vif.clk);
        axi_vif.w_data <= req.data;
        axi_vif.w_strb <= req.strb;
        axi_vif.w_last <= 1;
        axi_vif.w_user <= req.user;
        axi_vif.w_valid <= 1;
        do @(posedge axi_vif.clk); while (axi_vif.w_ready !== 1'b1);
        axi_vif.w_valid <= 0;

        // Keep both response channels ready and observe each handshake.
        axi_vif.b_ready <= 1;
        axi_vif.r_ready <= 1;
        while (!(b_done && r_done)) begin
            @(posedge axi_vif.clk);
            if (!b_done && axi_vif.b_valid && axi_vif.b_ready) begin
                b_done = 1;
                req.resp = axi_vif.b_resp;
            end
            if (!r_done && axi_vif.r_valid && axi_vif.r_ready) begin
                r_done = 1;
                req.data = axi_vif.r_data;
                req.resp = axi_vif.r_resp;
            end
        end
        @(negedge axi_vif.clk);
        axi_vif.b_ready <= 0;
        axi_vif.r_ready <= 0;
        `uvm_info("AXI_DRV", "SIMULTANEOUS AR/AW requests completed; inspect APB order for AR priority", UVM_MEDIUM)
    endtask

    // =================================================
    // ISSUE-ONLY (pipelined) WRITE / READ
    // AW and W are driven concurrently; the task returns after both handshakes
    // without waiting for B. Payload/VALID are held until READY (AXI rule), so
    // when the buffer FIFO is full the driver sits here with VALID=1, READY=0.
    // =================================================
    virtual task drive_write_issue(axi_transaction req);
        repeat (req.issue_gap) @(posedge axi_vif.clk);
        fork
            begin
                @(posedge axi_vif.clk);
                axi_vif.aw_id <= req.id;   axi_vif.aw_addr <= req.addr;
                axi_vif.aw_len <= 8'd0;    axi_vif.aw_size <= req.ctl_size;
                axi_vif.aw_burst <= req.ctl_burst; axi_vif.aw_lock <= req.ctl_lock;
                axi_vif.aw_cache <= req.ctl_cache;  axi_vif.aw_prot <= req.ctl_prot;
                axi_vif.aw_region <= req.ctl_region; axi_vif.aw_user <= req.user;
                axi_vif.aw_qos <= req.ctl_qos;    axi_vif.aw_valid <= 1'b1;
                do @(posedge axi_vif.clk); while (axi_vif.aw_ready !== 1'b1);
                axi_vif.aw_valid <= 1'b0;
            end
            begin
                @(posedge axi_vif.clk);
                axi_vif.w_data <= req.data; axi_vif.w_strb <= req.strb;
                axi_vif.w_last <= 1'b1;     axi_vif.w_user <= req.user;
                axi_vif.w_valid <= 1'b1;
                do @(posedge axi_vif.clk); while (axi_vif.w_ready !== 1'b1);
                axi_vif.w_valid <= 1'b0;
            end
        join
    endtask

    virtual task drive_read_issue(axi_transaction req);
        repeat (req.issue_gap) @(posedge axi_vif.clk);
        @(posedge axi_vif.clk);
        axi_vif.ar_id <= req.id;   axi_vif.ar_addr <= req.addr;
        axi_vif.ar_len <= 8'd0;    axi_vif.ar_size <= req.ctl_size;
        axi_vif.ar_burst <= req.ctl_burst; axi_vif.ar_lock <= req.ctl_lock;
        axi_vif.ar_cache <= req.ctl_cache;  axi_vif.ar_prot <= req.ctl_prot;
        axi_vif.ar_region <= req.ctl_region; axi_vif.ar_user <= req.user;
        axi_vif.ar_qos <= req.ctl_qos;    axi_vif.ar_valid <= 1'b1;
        do @(posedge axi_vif.clk); while (axi_vif.ar_ready !== 1'b1);
        axi_vif.ar_valid <= 1'b0;
    endtask

    // =================================================
    // WRITE
    // =================================================

    virtual task drive_write(axi_transaction req);

        // -------------------------
        // AW CHANNEL
        // -------------------------

        @(posedge axi_vif.clk);

        axi_vif.aw_id     <= req.id;
        axi_vif.aw_addr   <= req.addr;
        axi_vif.aw_len    <= 8'd0;
        axi_vif.aw_size   <= req.ctl_size;
        axi_vif.aw_burst  <= req.ctl_burst;
        axi_vif.aw_lock   <= req.ctl_lock;
        axi_vif.aw_cache  <= req.ctl_cache;
        axi_vif.aw_prot   <= req.ctl_prot;
        axi_vif.aw_region <= req.ctl_region;
        axi_vif.aw_user   <= req.user;
        axi_vif.aw_qos    <= req.ctl_qos;

        axi_vif.aw_valid  <= 1'b1;


        do @(posedge axi_vif.clk); while (axi_vif.aw_ready !== 1'b1);

        axi_vif.aw_valid <= 1'b0;


        // -------------------------
        // W CHANNEL
        // -------------------------

        axi_vif.w_data  <= req.data;
        axi_vif.w_strb  <= req.strb;
        axi_vif.w_last  <= 1'b1;
        axi_vif.w_user  <= req.user;

        axi_vif.w_valid <= 1'b1;


        do @(posedge axi_vif.clk); while (axi_vif.w_ready !== 1'b1);

        axi_vif.w_valid <= 1'b0;


        // -------------------------
        // B CHANNEL
        // -------------------------

        repeat (req.use_dly ? req.b_dly : b_delay) @(posedge axi_vif.clk);
        axi_vif.b_ready <= 1'b1;

        `uvm_info(
            "AXI_DRV",
            "WRITE: waiting for BVALID...",
            UVM_HIGH
        )

        wait (axi_vif.b_valid === 1'b1);

        req.resp = axi_vif.b_resp;

        `uvm_info(
            "AXI_DRV",
            "WRITE: BVALID RECEIVED",
            UVM_HIGH
        )

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


    // =================================================
    // READ
    // =================================================

    virtual task drive_read(axi_transaction req);

        // -------------------------
        // AR CHANNEL
        // -------------------------

        @(posedge axi_vif.clk);

        axi_vif.ar_id     <= req.id;
        axi_vif.ar_addr   <= req.addr;
        axi_vif.ar_len    <= 8'd0;
        axi_vif.ar_size   <= req.ctl_size;
        axi_vif.ar_burst  <= req.ctl_burst;
        axi_vif.ar_lock   <= req.ctl_lock;
        axi_vif.ar_cache  <= req.ctl_cache;
        axi_vif.ar_prot   <= req.ctl_prot;
        axi_vif.ar_region <= req.ctl_region;
        axi_vif.ar_user   <= req.user;
        axi_vif.ar_qos    <= req.ctl_qos;

        axi_vif.ar_valid  <= 1'b1;


        do @(posedge axi_vif.clk); while (axi_vif.ar_ready !== 1'b1);

        axi_vif.ar_valid <= 1'b0;


        // -------------------------
        // R CHANNEL
        // -------------------------

        repeat (req.use_dly ? req.r_dly : r_delay) @(posedge axi_vif.clk);
        axi_vif.r_ready <= 1'b1;

        `uvm_info(
            "AXI_DRV",
            "READ: waiting for RVALID...",
            UVM_HIGH
        )

        wait (axi_vif.r_valid === 1'b1);

        req.data = axi_vif.r_data;
        req.resp = axi_vif.r_resp;


        `uvm_info(
            "AXI_DRV",
            "READ: RVALID RECEIVED",
            UVM_HIGH
        )

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
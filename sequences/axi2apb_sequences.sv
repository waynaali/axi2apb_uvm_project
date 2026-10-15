// =========================================================
// AXI2APB SEQUENCES
//   axi_sequence      : smoke (1 write + 1 read)
//   axi_base_seq      : helper with send()
//   axi_b2b_*_seq     : back-to-back traffic
//   axi_mixed_seq     : mixed traffic / data patterns
//   axi_id_user_seq   : different IDs and USER values
// =========================================================

class axi_sequence extends uvm_sequence #(axi_transaction);

    `uvm_object_utils(axi_sequence)

    function new(string name = "axi_sequence");
        super.new(name);
    endfunction


    task body();

        axi_transaction tr;


        // =================================================
        // WRITE
        // =================================================

        tr = axi_transaction::type_id::create("write_tr");

        start_item(tr);

        tr.is_write = 1'b1;
        tr.id       = 6'd1;
        tr.addr     = 32'h00000010;
        tr.data     = 32'hDEADBEEF;
        tr.strb     = 4'hF;

        finish_item(tr);

        `uvm_info(
            "SEQ",
            "WRITE SENT: ADDR=0x10 DATA=DEADBEEF",
            UVM_LOW
        );


        // =================================================
        // READ SAME ADDRESS
        // =================================================

        tr = axi_transaction::type_id::create("read_tr");

        start_item(tr);

        tr.is_write = 1'b0;
        tr.id       = 6'd2;
        tr.addr     = 32'h00000010;
        tr.data     = 32'h0;
        tr.strb     = 4'hF;

        finish_item(tr);

        `uvm_info(
            "SEQ",
            "READ SENT: ADDR=0x10",
            UVM_LOW
        );


        // =================================================
        // END
        // =================================================

        `uvm_info(
            "SEQ",
            "SEQUENCE BODY FINISHED",
            UVM_LOW
        );

    endtask

endclass


// Base sequence with a helper to send one single-beat transaction.
class axi_base_seq extends uvm_sequence #(axi_transaction);

    `uvm_object_utils(axi_base_seq)

    function new(string name = "axi_base_seq");
        super.new(name);
    endfunction

    task send(bit is_write, bit [5:0] id, bit [31:0] addr,
              bit [31:0] data = 0, bit [5:0] user = 0);
        axi_transaction tr = axi_transaction::type_id::create("tr");
        start_item(tr);
        tr.is_write = is_write;
        tr.id       = id;
        tr.user     = user;
        tr.addr     = addr;
        tr.data     = data;
        tr.strb     = 4'hF;
        finish_item(tr);
    endtask

endclass


// Back-to-back writes.
class axi_b2b_write_seq extends axi_base_seq;
    `uvm_object_utils(axi_b2b_write_seq)
    function new(string name = "axi_b2b_write_seq"); super.new(name); endfunction

    task body();
        for (int i = 0; i < 8; i++)
            send(1, i, 32'h100 + 4*i, 32'hA000_0000 + i);
    endtask
endclass


// Back-to-back reads (preceded by writes so there is data to read).
class axi_b2b_read_seq extends axi_base_seq;
    `uvm_object_utils(axi_b2b_read_seq)
    function new(string name = "axi_b2b_read_seq"); super.new(name); endfunction

    task body();
        for (int i = 0; i < 4; i++)
            send(1, i, 32'h200 + 4*i, 32'hB000_0000 + i);
        for (int i = 0; i < 8; i++)
            send(0, i, 32'h200 + 4*(i % 4));
    endtask
endclass


// Mixed read/write traffic with different addresses and data patterns.
class axi_mixed_seq extends axi_base_seq;
    `uvm_object_utils(axi_mixed_seq)
    function new(string name = "axi_mixed_seq"); super.new(name); endfunction

    task body();
        send(1, 1, 32'h300, 32'h0000_0000);
        send(1, 2, 32'h304, 32'hFFFF_FFFF);
        send(1, 3, 32'h308, 32'hAAAA_AAAA);
        send(0, 4, 32'h300);
        send(1, 5, 32'h30C, 32'h5555_5555);
        send(0, 6, 32'h304);
        send(0, 7, 32'h308);
        send(0, 8, 32'h30C);
    endtask
endclass


// Different IDs and USER values.
class axi_id_user_seq extends axi_base_seq;
    `uvm_object_utils(axi_id_user_seq)
    function new(string name = "axi_id_user_seq"); super.new(name); endfunction

    task body();
        send(1, 6'h00, 32'h400, 32'h1111_1111, 6'h00);
        send(1, 6'h3F, 32'h404, 32'h2222_2222, 6'h3F);
        send(1, 6'h15, 32'h408, 32'h3333_3333, 6'h2A);
        send(0, 6'h00, 32'h400, 0, 6'h00);
        send(0, 6'h3F, 32'h404, 0, 6'h3F);
        send(0, 6'h15, 32'h408, 0, 6'h2A);
    endtask
endclass


// Write then read back one location (used by the wait-state / backpressure sweeps).
class axi_wait_rw_seq extends axi_base_seq;
    `uvm_object_utils(axi_wait_rw_seq)
    bit [31:0] addr = 32'h600;
    bit [31:0] data = 32'h1234_5678;
    bit        do_write = 1'b1;
    bit        do_read  = 1'b1;
    function new(string name = "axi_wait_rw_seq"); super.new(name); endfunction

    task body();
        if (do_write) send(1, 6'd5, addr, data, 6'd1);
        if (do_read)  send(0, 6'd6, addr, 0,    6'd2);
    endtask
endclass


// Boundary addresses x data patterns x ID/USER corners. Each location is written
// and read back so read-side coverage sees the same patterns.
class axi_boundary_pattern_seq extends axi_base_seq;
    `uvm_object_utils(axi_boundary_pattern_seq)
    function new(string name = "axi_boundary_pattern_seq"); super.new(name); endfunction

    task body();
        bit [31:0] addrs[]  = '{32'h0, 32'h4, 32'hFC, 32'h100, 32'hFFFC,
                                32'h1_0000, 32'hFFFF_FFF0, 32'hFFFF_FFFC};
        bit [31:0] pats[]   = '{32'h0, 32'hFFFF_FFFF, 32'hAAAA_AAAA, 32'h5555_5555, 32'hDEAD_BEEF};
        bit [5:0]  idu[]    = '{6'd0, 6'd1, 6'd15, 6'd16, 6'd62, 6'd63};
        int k = 0;

        foreach (addrs[a]) begin
            foreach (pats[p]) begin
                send(1, idu[k % idu.size()], addrs[a], pats[p], idu[(k + 3) % idu.size()]);
                send(0, idu[k % idu.size()], addrs[a], 0,       idu[(k + 3) % idu.size()]);
                k++;
            end
        end

        // walking-one and walking-zero data
        for (int b = 0; b < 32; b++) begin
            send(1, 6'd7, 32'h800 + 4*b, 32'h1 << b, 6'd7);
            send(0, 6'd7, 32'h800 + 4*b, 0,          6'd7);
        end
        for (int b = 0; b < 32; b++) begin
            send(1, 6'd8, 32'hA00 + 4*b, ~(32'h1 << b), 6'd8);
            send(0, 6'd8, 32'hA00 + 4*b, 0,             6'd8);
        end
    endtask
endclass


// ---------------------------------------------------------------------------
// FIFO-fill sequences: issue N requests without waiting for B/R. Must be run
// with driver.pipe_mode=1 and a slow APB slave / held BREADY,RREADY so the
// AW/W/AR buffers (wrapper sets BUFF_DEPTH_SLAVE=2) and B/R buffers actually fill.
// ---------------------------------------------------------------------------
class axi_fifo_fill_seq extends axi_base_seq;
    `uvm_object_utils(axi_fifo_fill_seq)
    int unsigned num_txn = 14;     // well above FIFO depth (2) so every buffer is forced full
    bit          is_write = 1;
    bit [31:0]   base_addr = 32'h800;
    function new(string name = "axi_fifo_fill_seq"); super.new(name); endfunction

    task body();
        for (int i = 0; i < num_txn; i++) begin
            axi_transaction tr = axi_transaction::type_id::create($sformatf("fill_tr_%0d", i));
            start_item(tr);
            tr.is_write   = is_write;
            tr.issue_only = 1'b1;
            tr.id         = i[5:0];
            tr.user       = i[5:0] ^ 6'h15;
            tr.addr       = base_addr + 4*i;
            tr.data       = 32'hF1F0_0000 + i;
            tr.strb       = 4'hF;
            finish_item(tr);
        end
    endtask
endclass


// ---------------------------------------------------------------------------
// FIFO streaming: randomized gaps between issue_only requests so that a new
// AW/W/AR push lands in the same cycle as the pop of the head entry while the
// FIFO holds exactly one element (the push&&pop&&~full&&~empty condition).
// Control fields (size/burst/lock/cache/prot/region/qos) are randomized too.
// ---------------------------------------------------------------------------
class axi_fifo_stream_seq extends axi_base_seq;
    `uvm_object_utils(axi_fifo_stream_seq)
    int unsigned num_txn  = 60;
    bit          is_write = 1;
    function new(string name = "axi_fifo_stream_seq"); super.new(name); endfunction

    task body();
        for (int i = 0; i < num_txn; i++) begin
            axi_transaction tr = axi_transaction::type_id::create($sformatf("stream_tr_%0d", i));
            start_item(tr);
            if (!tr.randomize() with {
                is_write == local::is_write;
                addr[1:0] == 2'b00;
                addr inside {[32'h800:32'h8FC]};
                strb inside {[4'h1:4'hF]};
            }) `uvm_fatal("RAND", "Failed to randomize stream transaction")
            tr.issue_only = 1'b1;
            finish_item(tr);
        end
    endtask
endclass

// Constrained-random single-beat AXI traffic.
//  - address classes cover zero / low / mid / high / top-of-range (word aligned)
//  - data classes cover all-zero / all-one / alternating / walking-one / random
//  - ID and USER span zero / low / mid / max
//  - reads re-visit previously written addresses so read data is non-trivial
//  - BREADY/RREADY delay is randomized per transaction when random_delays = 1
//    (APB PREADY latency is randomized by the APB driver min_wait/max_wait knobs)
class axi_random_seq extends uvm_sequence #(axi_transaction);
    `uvm_object_utils(axi_random_seq)
    int unsigned num_transactions = 300;
    bit          random_delays    = 1'b1;
    bit [31:0]   written[$];

    function new(string name = "axi_random_seq"); super.new(name); endfunction

    task body();
        axi_transaction tr;
        int unsigned data_sel;
        repeat (num_transactions) begin
            tr = axi_transaction::type_id::create("rand_tr");
            data_sel = $urandom_range(0, 5);
            start_item(tr);
            if (!tr.randomize() with {
                addr[1:0] == 2'b00;
                addr dist { 32'h0 := 2,
                            [32'h4:32'hFC] := 3,
                            [32'h100:32'hFFFC] := 6,
                            [32'h10000:32'hFFFFFFEC] := 3,
                            [32'hFFFFFFF0:32'hFFFFFFFC] := 2 };
                (data_sel == 0) -> data == 32'h0;
                (data_sel == 1) -> data == 32'hFFFF_FFFF;
                (data_sel == 2) -> data inside {32'hAAAA_AAAA, 32'h5555_5555};
                (data_sel == 3) -> $countones(data) == 1;
                id   dist { 6'd0 := 1, [6'd1:6'd15] := 3, [6'd16:6'd62] := 3, 6'd63 := 1 };
                user dist { 6'd0 := 1, [6'd1:6'd15] := 3, [6'd16:6'd62] := 3, 6'd63 := 1 };
                strb inside {[4'h1:4'hF]};
            }) `uvm_fatal("RAND", "Failed to randomize legal AXI transaction")
            if (!tr.is_write && written.size() > 0 && $urandom_range(0, 1))
                tr.addr = written[$urandom_range(written.size() - 1, 0)];
            if (tr.is_write) written.push_back(tr.addr);
            tr.use_dly = random_delays;
            finish_item(tr);
        end
    endtask
endclass

class axi_priority_seq extends uvm_sequence #(axi_transaction);
    `uvm_object_utils(axi_priority_seq)
    function new(string name = "axi_priority_seq"); super.new(name); endfunction
    task body();
        axi_transaction tr = axi_transaction::type_id::create("priority_tr");
        start_item(tr);
        tr.is_write = 1'b1;
        tr.both_req = 1'b1;
        tr.id = 6'd9;
        tr.user = 6'd3;
        tr.addr = 32'h0000_0500;
        tr.data = 32'hC001_CAFE;
        tr.strb = 4'hF;
        finish_item(tr);
    endtask
endclass

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


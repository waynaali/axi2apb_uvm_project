class axi_sequence extends uvm_sequence #(axi_transaction);

    `uvm_object_utils(axi_sequence)

    function new(string name = "axi_sequence");
        super.new(name);
    endfunction

    task body();

        axi_transaction tr;

        // =========================
        // ONE WRITE ONLY
        // =========================
        tr = axi_transaction::type_id::create("write_tr");

        start_item(tr);

        tr.is_write = 1;
        tr.id       = 1;
        tr.addr     = 32'h00000010;
        tr.data     = 32'hDEADBEEF;
        tr.strb     = 4'hF;

        finish_item(tr);

        `uvm_info("SEQ", "ONE WRITE SENT", UVM_LOW)


        // =========================
        // ONE READ ONLY
        // =========================
        tr = axi_transaction::type_id::create("read_tr");

        start_item(tr);

        tr.is_write = 0;
        tr.id       = 2;
        tr.addr     = 32'h00000020;
        tr.data     = 32'h0;
        tr.strb     = 4'hF;

        finish_item(tr);

        `uvm_info("SEQ", "ONE READ SENT", UVM_LOW)

        `uvm_info("SEQ", "SEQUENCE BODY FINISHED", UVM_LOW)

    endtask

endclass
// Lightweight virtual sequence for this environment. The APB slave driver is
// reactive to DUT PENABLE. An optional APB response sequence can be started
// alongside AXI traffic to control wait/error/read-data behavior.
class axi2apb_virtual_sequence extends uvm_sequence #(uvm_sequence_item);
    `uvm_object_utils(axi2apb_virtual_sequence)
    axi_sequencer axi_seqr;
    apb_sequencer apb_seqr;
    bit run_apb_response_seq = 0;
    bit run_priority_case = 0;
    function new(string name = "axi2apb_virtual_sequence"); super.new(name); endfunction

    task body();
        if (axi_seqr == null) `uvm_fatal("VSEQ", "AXI sequencer handle was not assigned")
        if (run_apb_response_seq) begin
            if (apb_seqr == null) `uvm_fatal("VSEQ", "APB sequencer handle was not assigned")
            fork
                begin
                    apb_response_sequence apb_seq = apb_response_sequence::type_id::create("apb_rsp_seq");
                    apb_seq.num_responses = 2;
                    apb_seq.start(apb_seqr);
                end
                begin
                    if (run_priority_case) begin
                        axi_priority_seq pseq = axi_priority_seq::type_id::create("priority_seq");
                        pseq.start(axi_seqr);
                    end else begin
                        axi_sequence seq = axi_sequence::type_id::create("smoke_seq");
                        seq.start(axi_seqr);
                    end
                end
            join
        end else if (run_priority_case) begin
            axi_priority_seq pseq = axi_priority_seq::type_id::create("priority_seq");
            pseq.start(axi_seqr);
        end else begin
            axi_sequence seq = axi_sequence::type_id::create("smoke_seq");
            seq.start(axi_seqr);
        end
    endtask
endclass

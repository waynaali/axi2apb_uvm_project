// Optional response-control sequence for the reactive APB slave driver.
// Each item controls the next observed APB ACCESS: wait cycles, PSLVERR,
// and optional explicit read data. With use_rdata=0, the driver's memory model is used.
class apb_response_sequence extends uvm_sequence #(apb_transaction);
    `uvm_object_utils(apb_response_sequence)
    int unsigned num_responses = 2;
    int unsigned wait_cycles = 0;
    bit slverr = 0;
    bit use_rdata = 0;
    bit [31:0] response_data = 0;

    function new(string name="apb_response_sequence"); super.new(name); endfunction
    task body();
        repeat (num_responses) begin
            apb_transaction rsp = apb_transaction::type_id::create("apb_rsp");
            start_item(rsp);
            rsp.addr = '0;
            rsp.data = '0;
            rsp.write = 0;
            rsp.strb = '1;
            rsp.wait_cycles = wait_cycles;
            rsp.slverr = slverr;
            rsp.use_rdata = use_rdata;
            rsp.response_data = response_data;
            finish_item(rsp);
        end
    endtask
endclass

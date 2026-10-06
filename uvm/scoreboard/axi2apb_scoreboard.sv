`uvm_analysis_imp_decl(_axi)
`uvm_analysis_imp_decl(_apb)

class axi2apb_scoreboard extends uvm_scoreboard;

    `uvm_component_utils(axi2apb_scoreboard)

    // --------------------------------
    // Analysis implementation ports
    // --------------------------------
    uvm_analysis_imp_axi #(axi_transaction,
                           axi2apb_scoreboard) axi_export;

    uvm_analysis_imp_apb #(apb_transaction,
                           axi2apb_scoreboard) apb_export;


    function new(
        string name = "axi2apb_scoreboard",
        uvm_component parent = null
    );
        super.new(name, parent);
    endfunction


    virtual function void build_phase(uvm_phase phase);

        super.build_phase(phase);

        axi_export = new("axi_export", this);
        apb_export = new("apb_export", this);

    endfunction


    // =================================
    // AXI transaction
    // =================================
    virtual function void write_axi(axi_transaction tr);

        if (tr.is_write) begin

            `uvm_info(
                "SCOREBOARD",
                $sformatf(
                    "AXI WRITE: ADDR=%h DATA=%h RESP=%0d",
                    tr.addr,
                    tr.data,
                    tr.resp
                ),
                UVM_MEDIUM
            )

        end
        else begin

            `uvm_info(
                "SCOREBOARD",
                $sformatf(
                    "AXI READ: ADDR=%h DATA=%h RESP=%0d",
                    tr.addr,
                    tr.data,
                    tr.resp
                ),
                UVM_MEDIUM
            )

        end

    endfunction


    // =================================
    // APB transaction
    // =================================
    virtual function void write_apb(apb_transaction tr);

        if (tr.write) begin

            `uvm_info(
                "SCOREBOARD",
                $sformatf(
                    "APB WRITE: ADDR=%h DATA=%h ERR=%0d",
                    tr.addr,
                    tr.data,
                    tr.slverr
                ),
                UVM_MEDIUM
            )

        end
        else begin

            `uvm_info(
                "SCOREBOARD",
                $sformatf(
                    "APB READ: ADDR=%h DATA=%h ERR=%0d",
                    tr.addr,
                    tr.rdata,
                    tr.slverr
                ),
                UVM_MEDIUM
            )

        end

    endfunction


endclass
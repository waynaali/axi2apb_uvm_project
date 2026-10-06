module fifo #(
    parameter bit          FALL_THROUGH = 1'b0,
    parameter int unsigned DATA_WIDTH   = 32,
    parameter int unsigned DEPTH        = 4
)(
    input  logic                 clk_i,
    input  logic                 rst_ni,
    input  logic                 flush_i,
    input  logic                 testmode_i,

    output logic                 full_o,
    output logic                 empty_o,

    input  logic [DATA_WIDTH-1:0] data_i,
    input  logic                  push_i,

    output logic [DATA_WIDTH-1:0] data_o,
    input  logic                  pop_i
);

    localparam int unsigned PTR_WIDTH =
        (DEPTH <= 1) ? 1 : $clog2(DEPTH);

    logic [DATA_WIDTH-1:0] mem [0:DEPTH-1];

    logic [PTR_WIDTH-1:0] wr_ptr;
    logic [PTR_WIDTH-1:0] rd_ptr;

    logic [PTR_WIDTH:0] count;

    assign full_o  = (count == DEPTH);
    assign empty_o = (count == 0);

    assign data_o = mem[rd_ptr];

    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            wr_ptr <= '0;
            rd_ptr <= '0;
            count  <= '0;
        end
        else if (flush_i) begin
            wr_ptr <= '0;
            rd_ptr <= '0;
            count  <= '0;
        end
        else begin

            // PUSH
            if (push_i && !full_o) begin
                mem[wr_ptr] <= data_i;

                if (wr_ptr == DEPTH-1)
                    wr_ptr <= '0;
                else
                    wr_ptr <= wr_ptr + 1'b1;
            end

            // POP
            if (pop_i && !empty_o) begin
                if (rd_ptr == DEPTH-1)
                    rd_ptr <= '0;
                else
                    rd_ptr <= rd_ptr + 1'b1;
            end

            // COUNT
            case ({push_i && !full_o, pop_i && !empty_o})
                2'b10: count <= count + 1'b1;
                2'b01: count <= count - 1'b1;
                default: count <= count;
            endcase
        end
    end

endmodule
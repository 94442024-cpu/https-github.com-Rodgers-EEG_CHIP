module interrupt_controller (
    input  wire        clk,
    input  wire        rst,
    input  wire        cyc_i,
    input  wire        stb_i,
    input  wire        we_i,
    input  wire [11:0] adr_i,
    input  wire [31:0] dat_i,
    input  wire [3:0]  sel_i,
    output reg  [31:0] dat_o,
    output wire        ack_o,
    output wire        err_o,
    input  wire [1:0]  irq_i,
    output wire        irq_o
);
    localparam ADDR_PENDING = 12'h000;
    localparam ADDR_MASK = 12'h004;
    localparam ADDR_CLEAR = 12'h008;
    localparam ADDR_STATUS = 12'h00C;

    reg [1:0] pending;
    reg [1:0] mask;
    wire request = cyc_i && stb_i;
    wire address_valid = (adr_i == ADDR_PENDING) || (adr_i == ADDR_MASK) ||
                         (adr_i == ADDR_CLEAR) || (adr_i == ADDR_STATUS);
    wire [1:0] clear_bits = request && !we_i && adr_i == ADDR_CLEAR ? 2'b00 :
                            request && we_i && adr_i == ADDR_CLEAR ? ((sel_i[0] ? dat_i[0] : 1'b0) | (sel_i[1] ? dat_i[1] : 1'b0)) : 2'b00;

    assign ack_o = request && address_valid;
    assign err_o = request && !address_valid;
    assign irq_o = ((pending & mask) != 2'd0);

    always @* begin
        case (adr_i)
            ADDR_PENDING: dat_o = {30'd0, pending};
            ADDR_MASK: dat_o = {30'd0, mask};
            ADDR_CLEAR: dat_o = 32'd0;
            ADDR_STATUS: dat_o = {30'd0, (pending & mask)};
            default: dat_o = 32'd0;
        endcase
    end

    always @(posedge clk) begin
        if (rst) begin
            pending <= 2'b00;
            mask <= 2'b11;
        end else begin
            pending <= (pending | irq_i) & ~clear_bits;

            if (request && !err_o && we_i) begin
                case (adr_i)
                    ADDR_MASK: begin
                        if (sel_i[0]) mask[0] <= dat_i[0];
                        if (sel_i[1]) mask[1] <= dat_i[1];
                    end
                    ADDR_CLEAR: begin
                        if (sel_i[0]) pending[0] <= 1'b0;
                        if (sel_i[1]) pending[1] <= 1'b0;
                    end
                    default: begin end
                endcase
            end
        end
    end
endmodule

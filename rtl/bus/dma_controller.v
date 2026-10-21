module dma_controller (
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
    output wire        irq_o,

    output wire        master_cyc_o,
    output wire        master_stb_o,
    output wire        master_we_o,
    output wire [31:0] master_adr_o,
    output wire [31:0] master_dat_o,
    output wire [3:0]  master_sel_o,
    input  wire [31:0] master_dat_i,
    input  wire        master_ack_i,
    input  wire        master_err_i
);
    localparam ADDR_CONTROL = 12'h000;
    localparam ADDR_STATUS = 12'h004;
    localparam ADDR_SOURCE = 12'h008;
    localparam ADDR_DESTINATION = 12'h00C;
    localparam ADDR_LENGTH = 12'h010;

    localparam STATE_IDLE = 2'd0;
    localparam STATE_READ = 2'd1;
    localparam STATE_WRITE = 2'd2;

    reg [31:0] source_reg;
    reg [31:0] destination_reg;
    reg [31:0] length_reg;
    reg [31:0] buffer_reg;
    reg [1:0] state;
    reg done_reg;
    reg error_reg;

    wire request = cyc_i && stb_i;
    wire address_valid = (adr_i == ADDR_CONTROL) || (adr_i == ADDR_STATUS) ||
                          (adr_i == ADDR_SOURCE) || (adr_i == ADDR_DESTINATION) ||
                          (adr_i == ADDR_LENGTH);
    wire start_request = request && we_i && !err_o && adr_i == ADDR_CONTROL && sel_i[0] && dat_i[0];

    assign ack_o = request && address_valid;
    assign err_o = request && !address_valid;
    assign irq_o = done_reg;

    assign master_cyc_o = (state == STATE_READ) || (state == STATE_WRITE);
    assign master_stb_o = master_cyc_o;
    assign master_we_o = (state == STATE_WRITE);
    assign master_adr_o = (state == STATE_WRITE) ? destination_reg : source_reg;
    assign master_dat_o = buffer_reg;
    assign master_sel_o = 4'hF;

    always @* begin
        case (adr_i)
            ADDR_CONTROL: dat_o = 32'd0;
            ADDR_STATUS: dat_o = {29'd0, error_reg, done_reg, state != STATE_IDLE};
            ADDR_SOURCE: dat_o = source_reg;
            ADDR_DESTINATION: dat_o = destination_reg;
            ADDR_LENGTH: dat_o = length_reg;
            default: dat_o = 32'd0;
        endcase
    end

    always @(posedge clk) begin
        if (rst) begin
            source_reg <= 32'd0;
            destination_reg <= 32'd0;
            length_reg <= 32'd0;
            buffer_reg <= 32'd0;
            state <= STATE_IDLE;
            done_reg <= 1'b0;
            error_reg <= 1'b0;
        end else begin
            if (request && !err_o && we_i) begin
                case (adr_i)
                    ADDR_CONTROL: begin
                        if (sel_i[0] && dat_i[1]) done_reg <= 1'b0;
                        if (sel_i[0] && dat_i[2]) error_reg <= 1'b0;
                    end
                    ADDR_STATUS: begin
                        if (sel_i[0] && dat_i[0]) done_reg <= 1'b0;
                        if (sel_i[0] && dat_i[1]) error_reg <= 1'b0;
                    end
                    ADDR_SOURCE: source_reg <= dat_i;
                    ADDR_DESTINATION: destination_reg <= dat_i;
                    ADDR_LENGTH: length_reg <= dat_i;
                    default: begin end
                endcase
            end

            if (start_request && state == STATE_IDLE && length_reg != 0) begin
                state <= STATE_READ;
                done_reg <= 1'b0;
                error_reg <= 1'b0;
            end else if (state == STATE_READ && (master_ack_i || master_err_i)) begin
                if (master_err_i) begin
                    state <= STATE_IDLE;
                    error_reg <= 1'b1;
                end else begin
                    buffer_reg <= master_dat_i;
                    state <= STATE_WRITE;
                end
            end else if (state == STATE_WRITE && (master_ack_i || master_err_i)) begin
                if (master_err_i) begin
                    state <= STATE_IDLE;
                    error_reg <= 1'b1;
                end else if (length_reg <= 4) begin
                    state <= STATE_IDLE;
                    length_reg <= 0;
                    done_reg <= 1'b1;
                end else begin
                    source_reg <= source_reg + 4;
                    destination_reg <= destination_reg + 4;
                    length_reg <= length_reg - 4;
                    state <= STATE_READ;
                end
            end
        end
    end
endmodule

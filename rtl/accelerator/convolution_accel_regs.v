module convolution_accel_regs (
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
    output wire        err_o
);
    localparam ADDR_CONTROL = 12'h000;
    localparam ADDR_STATUS = 12'h004;
    localparam ADDR_SAMPLE = 12'h008;
    localparam ADDR_COEFF = 12'h00C;
    localparam ADDR_RESULT = 12'h010;

    reg [31:0] control_reg;
    reg [31:0] sample_reg;
    reg [31:0] coeff_reg;
    reg [31:0] result_reg;
    reg busy_reg;
    reg done_reg;
    wire request = cyc_i && stb_i;
    wire address_valid = (adr_i == ADDR_CONTROL) || (adr_i == ADDR_STATUS) ||
                          (adr_i == ADDR_SAMPLE) || (adr_i == ADDR_COEFF) ||
                          (adr_i == ADDR_RESULT);

    assign ack_o = request && address_valid;
    assign err_o = request && !address_valid;

    always @* begin
        case (adr_i)
            ADDR_CONTROL: dat_o = control_reg;
            ADDR_STATUS: dat_o = {30'd0, done_reg, busy_reg};
            ADDR_SAMPLE: dat_o = sample_reg;
            ADDR_COEFF: dat_o = coeff_reg;
            ADDR_RESULT: dat_o = result_reg;
            default: dat_o = 32'd0;
        endcase
    end

    always @(posedge clk) begin
        if (rst) begin
            control_reg <= 32'd0;
            sample_reg <= 32'd0;
            coeff_reg <= 32'd0;
            result_reg <= 32'd0;
            busy_reg <= 1'b0;
            done_reg <= 1'b0;
        end else begin
            if (busy_reg) begin
                busy_reg <= 1'b0;
                done_reg <= 1'b1;
            end

            if (request && !err_o && we_i) begin
                case (adr_i)
                    ADDR_CONTROL: begin
                        control_reg <= dat_i;
                        if (sel_i[0] && dat_i[0]) begin
                            result_reg <= $signed(sample_reg) * $signed(coeff_reg);
                            busy_reg <= 1'b1;
                            done_reg <= 1'b0;
                        end
                    end
                    ADDR_STATUS: begin
                        if (sel_i[0] && dat_i[0]) done_reg <= 1'b0;
                    end
                    ADDR_SAMPLE: sample_reg <= dat_i;
                    ADDR_COEFF: coeff_reg <= dat_i;
                    default: begin end
                endcase
            end
        end
    end
endmodule

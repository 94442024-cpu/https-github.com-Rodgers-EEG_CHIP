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
    output wire        err_o,
    output wire        irq_o,
    output wire [31:0] coeff0_o,
    output wire [31:0] coeff1_o,
    output wire [31:0] coeff2_o,
    output wire [31:0] coeff3_o
);
    localparam ADDR_CONTROL = 12'h000;
    localparam ADDR_STATUS = 12'h004;
    localparam ADDR_SAMPLE = 12'h008;
    localparam ADDR_COEFF = 12'h00C;
    localparam ADDR_RESULT = 12'h010;
    localparam ADDR_SAMPLE1 = 12'h014;
    localparam ADDR_COEFF1 = 12'h018;
    localparam ADDR_SAMPLE2 = 12'h01C;
    localparam ADDR_COEFF2 = 12'h020;
    localparam ADDR_SAMPLE3 = 12'h024;
    localparam ADDR_COEFF3 = 12'h028;

    reg [31:0] control_reg;
    reg [31:0] sample_regs [0:3];
    reg [31:0] coeff_regs [0:3];
    reg [31:0] result_reg;
    reg busy_reg;
    reg done_reg;
    wire request = cyc_i && stb_i;
    wire address_valid = (adr_i == ADDR_CONTROL) || (adr_i == ADDR_STATUS) ||
                          (adr_i == ADDR_SAMPLE) || (adr_i == ADDR_COEFF) ||
                          (adr_i == ADDR_RESULT) || (adr_i == ADDR_SAMPLE1) ||
                          (adr_i == ADDR_COEFF1) || (adr_i == ADDR_SAMPLE2) ||
                          (adr_i == ADDR_COEFF2) || (adr_i == ADDR_SAMPLE3) ||
                          (adr_i == ADDR_COEFF3);

    assign ack_o = request && address_valid;
    assign err_o = request && !address_valid;
    assign irq_o = done_reg;
    assign coeff0_o = coeff_regs[0];
    assign coeff1_o = coeff_regs[1];
    assign coeff2_o = coeff_regs[2];
    assign coeff3_o = coeff_regs[3];

    always @* begin
        case (adr_i)
            ADDR_CONTROL: dat_o = control_reg;
            ADDR_STATUS: dat_o = {30'd0, done_reg, busy_reg};
            ADDR_SAMPLE: dat_o = sample_regs[0];
            ADDR_COEFF: dat_o = coeff_regs[0];
            ADDR_RESULT: dat_o = result_reg;
            ADDR_SAMPLE1: dat_o = sample_regs[1];
            ADDR_COEFF1: dat_o = coeff_regs[1];
            ADDR_SAMPLE2: dat_o = sample_regs[2];
            ADDR_COEFF2: dat_o = coeff_regs[2];
            ADDR_SAMPLE3: dat_o = sample_regs[3];
            ADDR_COEFF3: dat_o = coeff_regs[3];
            default: dat_o = 32'd0;
        endcase
    end

    always @(posedge clk) begin
        if (rst) begin
            control_reg <= 32'd0;
            sample_regs[0] <= 32'd0;
            sample_regs[1] <= 32'd0;
            sample_regs[2] <= 32'd0;
            sample_regs[3] <= 32'd0;
            coeff_regs[0] <= 32'd0;
            coeff_regs[1] <= 32'd0;
            coeff_regs[2] <= 32'd0;
            coeff_regs[3] <= 32'd0;
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
                            result_reg <= ($signed(sample_regs[0]) * $signed(coeff_regs[0])) +
                                          ($signed(sample_regs[1]) * $signed(coeff_regs[1])) +
                                          ($signed(sample_regs[2]) * $signed(coeff_regs[2])) +
                                          ($signed(sample_regs[3]) * $signed(coeff_regs[3]));
                            busy_reg <= 1'b1;
                            done_reg <= 1'b0;
                        end
                    end
                    ADDR_STATUS: begin
                        if (sel_i[0] && dat_i[0]) done_reg <= 1'b0;
                    end
                    ADDR_SAMPLE: sample_regs[0] <= dat_i;
                    ADDR_COEFF: coeff_regs[0] <= dat_i;
                    ADDR_SAMPLE1: sample_regs[1] <= dat_i;
                    ADDR_COEFF1: coeff_regs[1] <= dat_i;
                    ADDR_SAMPLE2: sample_regs[2] <= dat_i;
                    ADDR_COEFF2: coeff_regs[2] <= dat_i;
                    ADDR_SAMPLE3: sample_regs[3] <= dat_i;
                    ADDR_COEFF3: coeff_regs[3] <= dat_i;
                    default: begin end
                endcase
            end
        end
    end
endmodule

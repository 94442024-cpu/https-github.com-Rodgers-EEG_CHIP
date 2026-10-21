module convolution_accelerator (
    input  wire        clk,
    input  wire        rst,
    input  wire        cyc_i,
    input  wire        stb_i,
    input  wire        we_i,
    input  wire [11:0] adr_i,
    input  wire [31:0] dat_i,
    input  wire [3:0]  sel_i,
    output wire [31:0] dat_o,
    output wire        ack_o,
    output wire        err_o,
    input  wire        sample_valid_i,
    input  wire [31:0] sample_i,
    output wire        sample_ready_o,
    output wire        stream_result_valid_o,
    output wire [31:0] stream_result_o
);
    wire [31:0] coeff0;
    wire [31:0] coeff1;
    wire [31:0] coeff2;
    wire [31:0] coeff3;

    convolution_accel_regs registers (
        .clk(clk), .rst(rst), .cyc_i(cyc_i), .stb_i(stb_i), .we_i(we_i),
        .adr_i(adr_i), .dat_i(dat_i), .sel_i(sel_i), .dat_o(dat_o),
        .ack_o(ack_o), .err_o(err_o), .coeff0_o(coeff0), .coeff1_o(coeff1),
        .coeff2_o(coeff2), .coeff3_o(coeff3)
    );

    convolution_stream stream (
        .clk(clk), .rst(rst), .sample_valid_i(sample_valid_i), .sample_i(sample_i),
        .coeff0_i(coeff0), .coeff1_i(coeff1), .coeff2_i(coeff2), .coeff3_i(coeff3),
        .sample_ready_o(sample_ready_o), .result_valid_o(stream_result_valid_o),
        .result_o(stream_result_o)
    );
endmodule

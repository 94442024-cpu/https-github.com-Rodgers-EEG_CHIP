module convolution_stream (
    input  wire        clk,
    input  wire        rst,
    input  wire        sample_valid_i,
    input  wire [31:0] sample_i,
    input  wire [31:0] coeff0_i,
    input  wire [31:0] coeff1_i,
    input  wire [31:0] coeff2_i,
    input  wire [31:0] coeff3_i,
    output wire        sample_ready_o,
    output reg         result_valid_o,
    output reg  [31:0] result_o
);
    reg [31:0] samples [0:2];
    reg [2:0] sample_count;
    reg signed [63:0] accumulation;
    integer index;

    assign sample_ready_o = 1'b1;

    always @(posedge clk) begin
        if (rst) begin
            samples[0] <= 32'd0;
            samples[1] <= 32'd0;
            samples[2] <= 32'd0;
            sample_count <= 3'd0;
            result_valid_o <= 1'b0;
            result_o <= 32'd0;
        end else begin
            result_valid_o <= 1'b0;
            if (sample_valid_i && sample_ready_o) begin
                if (sample_count >= 3) begin
                    accumulation = ($signed(sample_i) * $signed(coeff0_i)) +
                                   ($signed(samples[0]) * $signed(coeff1_i)) +
                                   ($signed(samples[1]) * $signed(coeff2_i)) +
                                   ($signed(samples[2]) * $signed(coeff3_i));
                    result_o <= accumulation[31:0];
                    result_valid_o <= 1'b1;
                end else begin
                    sample_count <= sample_count + 3'd1;
                end
                samples[2] <= samples[1];
                samples[1] <= samples[0];
                samples[0] <= sample_i;
            end
        end
    end
endmodule

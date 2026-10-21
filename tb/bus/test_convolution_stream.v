`timescale 1ns/1ps

module test_convolution_stream;
    reg clk = 1'b0;
    reg rst = 1'b1;
    reg sample_valid_i;
    reg [31:0] sample_i;
    reg [31:0] coeff0_i, coeff1_i, coeff2_i, coeff3_i;
    wire sample_ready_o;
    wire result_valid_o;
    wire [31:0] result_o;

    convolution_stream stream (
        .clk(clk), .rst(rst), .sample_valid_i(sample_valid_i), .sample_i(sample_i),
        .coeff0_i(coeff0_i), .coeff1_i(coeff1_i), .coeff2_i(coeff2_i), .coeff3_i(coeff3_i),
        .sample_ready_o(sample_ready_o), .result_valid_o(result_valid_o), .result_o(result_o)
    );

    always #5 clk = ~clk;

    task send_sample;
        input [31:0] value;
        input expected_valid;
        input [31:0] expected_result;
        begin
            @(negedge clk);
            sample_i = value;
            sample_valid_i = 1'b1;
            @(posedge clk);
            #1;
            if (result_valid_o !== expected_valid) $fatal(1, "stream valid expected %b got %b", expected_valid, result_valid_o);
            if (expected_valid && result_o !== expected_result) $fatal(1, "stream result expected %h got %h", expected_result, result_o);
            @(negedge clk);
            sample_valid_i = 1'b0;
        end
    endtask

    initial begin
        sample_valid_i = 0;
        sample_i = 0;
        coeff0_i = 1;
        coeff1_i = 2;
        coeff2_i = 3;
        coeff3_i = 4;
        #12;
        rst = 1'b0;
        send_sample(32'd1, 0, 0);
        send_sample(32'd2, 0, 0);
        send_sample(32'd3, 0, 0);
        send_sample(32'd4, 1, 32'd20);
        send_sample(32'd5, 1, 32'd30);
        $display("Convolution stream tests passed");
        $finish;
    end
endmodule

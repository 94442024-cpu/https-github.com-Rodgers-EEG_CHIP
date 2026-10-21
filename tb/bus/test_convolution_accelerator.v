`timescale 1ns/1ps

module test_convolution_accelerator;
    reg clk = 1'b0;
    reg rst = 1'b1;
    reg cyc_i, stb_i, we_i;
    reg [11:0] adr_i;
    reg [31:0] dat_i;
    reg [3:0] sel_i;
    wire [31:0] dat_o;
    wire ack_o, err_o;
    reg sample_valid_i;
    reg [31:0] sample_i;
    wire sample_ready_o, stream_result_valid_o;
    wire [31:0] stream_result_o;

    convolution_accelerator accelerator (
        .clk(clk), .rst(rst), .cyc_i(cyc_i), .stb_i(stb_i), .we_i(we_i),
        .adr_i(adr_i), .dat_i(dat_i), .sel_i(sel_i), .dat_o(dat_o),
        .ack_o(ack_o), .err_o(err_o), .sample_valid_i(sample_valid_i),
        .sample_i(sample_i), .sample_ready_o(sample_ready_o),
        .stream_result_valid_o(stream_result_valid_o), .stream_result_o(stream_result_o)
    );

    always #5 clk = ~clk;

    task write_register;
        input [11:0] address;
        input [31:0] value;
        begin
            @(negedge clk);
            adr_i = address;
            dat_i = value;
            we_i = 1'b1;
            cyc_i = 1'b1;
            stb_i = 1'b1;
            #1;
            if (!ack_o || err_o) $fatal(1, "coefficient write failed");
            @(negedge clk);
            cyc_i = 1'b0;
            stb_i = 1'b0;
            we_i = 1'b0;
        end
    endtask

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
            if (stream_result_valid_o !== expected_valid) $fatal(1, "stream valid mismatch");
            if (expected_valid && stream_result_o !== expected_result) $fatal(1, "stream result expected %h got %h", expected_result, stream_result_o);
            @(negedge clk);
            sample_valid_i = 1'b0;
        end
    endtask

    initial begin
        cyc_i = 0;
        stb_i = 0;
        we_i = 0;
        adr_i = 0;
        dat_i = 0;
        sel_i = 4'hF;
        sample_valid_i = 0;
        sample_i = 0;
        #12;
        rst = 1'b0;

        write_register(12'h00C, 32'd1);
        write_register(12'h018, 32'd2);
        write_register(12'h020, 32'd3);
        write_register(12'h028, 32'd4);
        send_sample(32'd1, 0, 0);
        send_sample(32'd2, 0, 0);
        send_sample(32'd3, 0, 0);
        send_sample(32'd4, 1, 32'd20);
        send_sample(32'd5, 1, 32'd30);

        $display("Configured convolution accelerator stream tests passed");
        $finish;
    end
endmodule

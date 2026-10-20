`timescale 1ns/1ps

module test_wishbone_ram;
    reg clk = 1'b0;
    reg rst = 1'b1;
    reg cyc_i, stb_i, we_i;
    reg [31:0] adr_i, dat_i;
    reg [3:0] sel_i;
    wire [31:0] dat_o;
    wire ack_o, err_o;

    wishbone_ram #(.BYTES(256)) ram (
        .clk(clk), .rst(rst), .cyc_i(cyc_i), .stb_i(stb_i), .we_i(we_i),
        .adr_i(adr_i), .dat_i(dat_i), .sel_i(sel_i),
        .dat_o(dat_o), .ack_o(ack_o), .err_o(err_o)
    );

    always #5 clk = ~clk;

    task write_word;
        input [31:0] address;
        input [31:0] value;
        begin
            @(negedge clk);
            adr_i = address;
            dat_i = value;
            sel_i = 4'hF;
            we_i = 1'b1;
            cyc_i = 1'b1;
            stb_i = 1'b1;
            #1;
            if (!ack_o || err_o) $fatal(1, "RAM write response failed");
            @(negedge clk);
            cyc_i = 1'b0;
            stb_i = 1'b0;
            we_i = 1'b0;
        end
    endtask

    task read_word;
        input [31:0] address;
        input [31:0] expected;
        begin
            @(negedge clk);
            adr_i = address;
            sel_i = 4'hF;
            cyc_i = 1'b1;
            stb_i = 1'b1;
            #1;
            if (!ack_o || err_o || dat_o !== expected) $fatal(1, "RAM read response failed");
            @(negedge clk);
            cyc_i = 1'b0;
            stb_i = 1'b0;
        end
    endtask

    initial begin
        cyc_i = 0;
        stb_i = 0;
        we_i = 0;
        adr_i = 0;
        dat_i = 0;
        sel_i = 0;
        #12;
        rst = 1'b0;
        write_word(32'h20, 32'hAABBCCDD);
        read_word(32'h20, 32'hAABBCCDD);
        write_word(32'h24, 32'h11223344);
        read_word(32'h24, 32'h11223344);

        @(negedge clk);
        adr_i = 32'hFE;
        cyc_i = 1'b1;
        stb_i = 1'b1;
        #1;
        if (!err_o || ack_o) $fatal(1, "out-of-range RAM access did not error");

        $display("Wishbone RAM tests passed");
        $finish;
    end
endmodule

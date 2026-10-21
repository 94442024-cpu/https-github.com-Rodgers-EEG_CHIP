`timescale 1ns/1ps

module test_dma_controller;
    reg clk = 1'b0;
    reg rst = 1'b1;
    reg cyc_i, stb_i, we_i;
    reg [11:0] adr_i;
    reg [31:0] dat_i;
    reg [3:0] sel_i;
    wire [31:0] dat_o;
    wire ack_o, err_o;
    wire master_cyc_o, master_stb_o, master_we_o;
    wire [31:0] master_adr_o, master_dat_o;
    wire [3:0] master_sel_o;
    wire [31:0] master_dat_i;
    wire master_ack_i, master_err_i;
    reg [31:0] memory [0:63];
    integer index;

    dma_controller dma (
        .clk(clk), .rst(rst), .cyc_i(cyc_i), .stb_i(stb_i), .we_i(we_i),
        .adr_i(adr_i), .dat_i(dat_i), .sel_i(sel_i), .dat_o(dat_o),
        .ack_o(ack_o), .err_o(err_o), .master_cyc_o(master_cyc_o),
        .master_stb_o(master_stb_o), .master_we_o(master_we_o),
        .master_adr_o(master_adr_o), .master_dat_o(master_dat_o),
        .master_sel_o(master_sel_o), .master_dat_i(master_dat_i),
        .master_ack_i(master_ack_i), .master_err_i(master_err_i)
    );

    assign master_dat_i = memory[master_adr_o[7:2]];
    assign master_ack_i = master_cyc_o && master_stb_o;
    assign master_err_i = master_cyc_o && (master_adr_o[31:8] != 0);

    always #5 clk = ~clk;

    always @(posedge clk) begin
        if (master_cyc_o && master_stb_o && master_we_o && !master_err_i)
            memory[master_adr_o[7:2]] <= master_dat_o;
    end

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
            if (!ack_o || err_o) $fatal(1, "DMA register write failed at %h", address);
            @(negedge clk);
            cyc_i = 1'b0;
            stb_i = 1'b0;
            we_i = 1'b0;
        end
    endtask

    initial begin
        cyc_i = 0;
        stb_i = 0;
        we_i = 0;
        adr_i = 0;
        dat_i = 0;
        sel_i = 4'hF;
        for (index = 0; index < 64; index = index + 1) memory[index] = 0;
        memory[0] = 32'hAABBCCDD;
        memory[1] = 32'h11223344;
        #12;
        rst = 1'b0;

        write_register(12'h008, 32'h00000000);
        write_register(12'h00C, 32'h00000020);
        write_register(12'h010, 32'd8);
        write_register(12'h000, 32'd1);
        repeat (12) @(posedge clk);

        if (memory[8] !== 32'hAABBCCDD || memory[9] !== 32'h11223344)
            $fatal(1, "DMA memory transfer failed");
        if (dma.state !== 2'd0 || !dma.done_reg) $fatal(1, "DMA did not report completion");

        $display("DMA controller tests passed");
        $finish;
    end
endmodule

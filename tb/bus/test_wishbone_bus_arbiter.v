`timescale 1ns/1ps

module test_wishbone_bus_arbiter;
    reg clk = 1'b0;
    reg rst = 1'b1;
    reg cpu_cyc_i, cpu_stb_i, cpu_we_i;
    reg [31:0] cpu_adr_i, cpu_dat_i;
    reg [3:0] cpu_sel_i;
    wire [31:0] cpu_dat_o;
    wire cpu_ack_o, cpu_err_o;
    reg dma_cyc_i, dma_stb_i, dma_we_i;
    reg [31:0] dma_adr_i, dma_dat_i;
    reg [3:0] dma_sel_i;
    wire [31:0] dma_dat_o;
    wire dma_ack_o, dma_err_o;
    wire bus_cyc_o, bus_stb_o, bus_we_o;
    wire [31:0] bus_adr_o, bus_dat_o;
    wire [3:0] bus_sel_o;
    reg [31:0] bus_dat_i;
    reg bus_ack_i, bus_err_i;

    wishbone_bus_arbiter arbiter (
        .clk(clk), .rst(rst),
        .cpu_cyc_i(cpu_cyc_i), .cpu_stb_i(cpu_stb_i), .cpu_we_i(cpu_we_i),
        .cpu_adr_i(cpu_adr_i), .cpu_dat_i(cpu_dat_i), .cpu_sel_i(cpu_sel_i),
        .cpu_dat_o(cpu_dat_o), .cpu_ack_o(cpu_ack_o), .cpu_err_o(cpu_err_o),
        .dma_cyc_i(dma_cyc_i), .dma_stb_i(dma_stb_i), .dma_we_i(dma_we_i),
        .dma_adr_i(dma_adr_i), .dma_dat_i(dma_dat_i), .dma_sel_i(dma_sel_i),
        .dma_dat_o(dma_dat_o), .dma_ack_o(dma_ack_o), .dma_err_o(dma_err_o),
        .bus_cyc_o(bus_cyc_o), .bus_stb_o(bus_stb_o), .bus_we_o(bus_we_o),
        .bus_adr_o(bus_adr_o), .bus_dat_o(bus_dat_o), .bus_sel_o(bus_sel_o),
        .bus_dat_i(bus_dat_i), .bus_ack_i(bus_ack_i), .bus_err_i(bus_err_i)
    );

    always #5 clk = ~clk;

    initial begin
        cpu_cyc_i = 0; cpu_stb_i = 0; cpu_we_i = 0; cpu_adr_i = 0; cpu_dat_i = 0; cpu_sel_i = 0;
        dma_cyc_i = 0; dma_stb_i = 0; dma_we_i = 0; dma_adr_i = 0; dma_dat_i = 0; dma_sel_i = 0;
        bus_dat_i = 32'h12345678; bus_ack_i = 0; bus_err_i = 0;
        #12;
        rst = 1'b0;

        cpu_adr_i = 32'h10;
        dma_adr_i = 32'h20;
        cpu_cyc_i = 1'b1; cpu_stb_i = 1'b1;
        dma_cyc_i = 1'b1; dma_stb_i = 1'b1;
        @(negedge clk);
        #1;
        if (bus_adr_o !== 32'h10 || !bus_cyc_o || dma_ack_o || !cpu_cyc_i) $fatal(1, "CPU priority failed");
        bus_ack_i = 1'b1;
        @(negedge clk);
        #1;
        bus_ack_i = 1'b0;
        cpu_cyc_i = 1'b0; cpu_stb_i = 1'b0;
        @(posedge clk);
        #1;
        if (bus_adr_o !== 32'h20 || !bus_cyc_o) $fatal(1, "DMA grant failed");
        bus_ack_i = 1'b1;
        @(negedge clk);
        #1;
        if (!dma_ack_o && bus_cyc_o) $fatal(1, "DMA completion failed");

        $display("Wishbone bus arbiter tests passed");
        $finish;
    end
endmodule

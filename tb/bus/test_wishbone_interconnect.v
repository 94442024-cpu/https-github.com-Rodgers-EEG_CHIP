`timescale 1ns/1ps

module test_wishbone_interconnect;
    reg master_cyc_i;
    reg master_stb_i;
    reg master_we_i;
    reg [31:0] master_adr_i;
    reg [31:0] master_dat_i;
    reg [3:0] master_sel_i;
    wire [31:0] master_dat_o;
    wire master_ack_o;
    wire master_err_o;

    wire memory_cyc_o, memory_stb_o, memory_we_o;
    wire [31:0] memory_adr_o, memory_dat_o;
    wire [3:0] memory_sel_o;
    reg [31:0] memory_dat_i;
    reg memory_ack_i, memory_err_i;

    wire accelerator_cyc_o, accelerator_stb_o, accelerator_we_o;
    wire [31:0] accelerator_adr_o, accelerator_dat_o;
    wire [3:0] accelerator_sel_o;
    reg [31:0] accelerator_dat_i;
    reg accelerator_ack_i, accelerator_err_i;

    wire dma_cyc_o, dma_stb_o, dma_we_o;
    wire [31:0] dma_adr_o, dma_dat_o;
    wire [3:0] dma_sel_o;
    reg [31:0] dma_dat_i;
    reg dma_ack_i, dma_err_i;

    wishbone_interconnect bus_decoder (
        .master_cyc_i(master_cyc_i), .master_stb_i(master_stb_i), .master_we_i(master_we_i),
        .master_adr_i(master_adr_i), .master_dat_i(master_dat_i), .master_sel_i(master_sel_i),
        .master_dat_o(master_dat_o), .master_ack_o(master_ack_o), .master_err_o(master_err_o),
        .memory_cyc_o(memory_cyc_o), .memory_stb_o(memory_stb_o), .memory_we_o(memory_we_o),
        .memory_adr_o(memory_adr_o), .memory_dat_o(memory_dat_o), .memory_sel_o(memory_sel_o),
        .memory_dat_i(memory_dat_i), .memory_ack_i(memory_ack_i), .memory_err_i(memory_err_i),
        .accelerator_cyc_o(accelerator_cyc_o), .accelerator_stb_o(accelerator_stb_o),
        .accelerator_we_o(accelerator_we_o), .accelerator_adr_o(accelerator_adr_o),
        .accelerator_dat_o(accelerator_dat_o), .accelerator_sel_o(accelerator_sel_o),
        .accelerator_dat_i(accelerator_dat_i), .accelerator_ack_i(accelerator_ack_i),
        .accelerator_err_i(accelerator_err_i), .dma_cyc_o(dma_cyc_o), .dma_stb_o(dma_stb_o),
        .dma_we_o(dma_we_o), .dma_adr_o(dma_adr_o), .dma_dat_o(dma_dat_o), .dma_sel_o(dma_sel_o),
        .dma_dat_i(dma_dat_i), .dma_ack_i(dma_ack_i), .dma_err_i(dma_err_i)
    );

    task check_route;
        input [31:0] address;
        input expected_memory;
        input expected_accelerator;
        input expected_dma;
        begin
            master_cyc_i = 1'b1;
            master_stb_i = 1'b1;
            master_adr_i = address;
            #1;
            if (memory_cyc_o !== expected_memory || accelerator_cyc_o !== expected_accelerator || dma_cyc_o !== expected_dma)
                $fatal(1, "route failed for address %h", address);
        end
    endtask

    initial begin
        master_cyc_i = 0;
        master_stb_i = 0;
        master_we_i = 0;
        master_adr_i = 0;
        master_dat_i = 0;
        master_sel_i = 4'hF;
        memory_dat_i = 32'h11111111;
        memory_ack_i = 1;
        memory_err_i = 0;
        accelerator_dat_i = 32'h22222222;
        accelerator_ack_i = 1;
        accelerator_err_i = 0;
        dma_dat_i = 32'h33333333;
        dma_ack_i = 1;
        dma_err_i = 0;

        check_route(32'h00000000, 1, 0, 0);
        if (master_dat_o !== 32'h11111111 || !master_ack_o || master_err_o) $fatal(1, "memory response failed");
        check_route(32'h40000010, 0, 1, 0);
        if (master_dat_o !== 32'h22222222 || !master_ack_o || master_err_o) $fatal(1, "accelerator response failed");
        check_route(32'h40001010, 0, 0, 1);
        if (master_dat_o !== 32'h33333333 || !master_ack_o || master_err_o) $fatal(1, "DMA response failed");
        check_route(32'h80000000, 0, 0, 0);
        if (!master_err_o) $fatal(1, "unmapped access did not return an error");

        $display("Wishbone interconnect tests passed");
        $finish;
    end
endmodule

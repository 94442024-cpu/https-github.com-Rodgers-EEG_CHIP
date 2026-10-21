module riscv_wb_system #(
    parameter INSTRUCTION_WORDS = 1024,
    parameter DATA_BYTES = 65536
) (
    input wire clk,
    input wire reset
);
    wire data_request;
    wire data_write;
    wire [31:0] data_address;
    wire [31:0] data_write_data;
    wire [1:0] data_width;
    wire data_unsigned;
    wire [31:0] data_read_data;
    wire data_ack;
    wire data_err;

    wire wb_cyc, wb_stb, wb_we;
    wire [31:0] wb_adr, wb_dat_o, wb_dat_i;
    wire [3:0] wb_sel;
    wire wb_ack, wb_err;

    wire memory_cyc, memory_stb, memory_we;
    wire [31:0] memory_adr, memory_dat_o, memory_dat_i;
    wire [3:0] memory_sel;
    wire memory_ack, memory_err;

    wire accelerator_cyc, accelerator_stb, accelerator_we;
    wire [31:0] accelerator_adr, accelerator_dat_o;
    wire [3:0] accelerator_sel;
    wire dma_cyc, dma_stb, dma_we;
    wire [31:0] dma_adr, dma_dat_o;
    wire [3:0] dma_sel;

    riscv_core #(
        .INSTRUCTION_WORDS(INSTRUCTION_WORDS),
        .DATA_BYTES(DATA_BYTES),
        .EXTERNAL_DATA_BUS(1)
    ) cpu (
        .clk(clk), .reset(reset),
        .data_request_o(data_request), .data_write_o(data_write),
        .data_address_o(data_address), .data_write_data_o(data_write_data),
        .data_width_o(data_width), .data_unsigned_o(data_unsigned),
        .data_read_data_i(data_read_data), .data_ack_i(data_ack), .data_err_i(data_err)
    );

    wishbone_master_bridge bridge (
        .clk(clk), .rst(reset), .cpu_req_i(data_request), .cpu_we_i(data_write),
        .cpu_adr_i(data_address), .cpu_dat_i(data_write_data),
        .cpu_sel_i(data_width == 2'd0 ? 4'b0001 : data_width == 2'd1 ? 4'b0011 : 4'b1111),
        .cpu_dat_o(data_read_data), .cpu_ack_o(data_ack), .cpu_err_o(data_err),
        .wb_cyc_o(wb_cyc), .wb_stb_o(wb_stb), .wb_we_o(wb_we),
        .wb_adr_o(wb_adr), .wb_dat_o(wb_dat_o), .wb_sel_o(wb_sel),
        .wb_dat_i(wb_dat_i), .wb_ack_i(wb_ack), .wb_err_i(wb_err)
    );

    wishbone_interconnect bus_decoder (
        .master_cyc_i(wb_cyc), .master_stb_i(wb_stb), .master_we_i(wb_we),
        .master_adr_i(wb_adr), .master_dat_i(wb_dat_o), .master_sel_i(wb_sel),
        .master_dat_o(wb_dat_i), .master_ack_o(wb_ack), .master_err_o(wb_err),
        .memory_cyc_o(memory_cyc), .memory_stb_o(memory_stb), .memory_we_o(memory_we),
        .memory_adr_o(memory_adr), .memory_dat_o(memory_dat_o), .memory_sel_o(memory_sel),
        .memory_dat_i(memory_dat_i), .memory_ack_i(memory_ack), .memory_err_i(memory_err),
        .accelerator_cyc_o(accelerator_cyc), .accelerator_stb_o(accelerator_stb),
        .accelerator_we_o(accelerator_we), .accelerator_adr_o(accelerator_adr),
        .accelerator_dat_o(accelerator_dat_o), .accelerator_sel_o(accelerator_sel),
        .accelerator_dat_i(32'd0), .accelerator_ack_i(1'b0), .accelerator_err_i(1'b0),
        .dma_cyc_o(dma_cyc), .dma_stb_o(dma_stb), .dma_we_o(dma_we), .dma_adr_o(dma_adr),
        .dma_dat_o(dma_dat_o), .dma_sel_o(dma_sel),
        .dma_dat_i(32'd0), .dma_ack_i(1'b0), .dma_err_i(1'b0)
    );

    wishbone_ram #(.BYTES(DATA_BYTES)) memory_target (
        .clk(clk), .rst(reset), .cyc_i(memory_cyc), .stb_i(memory_stb),
        .we_i(memory_we), .adr_i(memory_adr), .dat_i(memory_dat_o),
        .sel_i(memory_sel), .dat_o(memory_dat_i), .ack_o(memory_ack), .err_o(memory_err)
    );
endmodule

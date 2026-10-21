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
    wire bus_cyc, bus_stb, bus_we;
    wire [31:0] bus_adr, bus_dat_o, bus_dat_i;
    wire [3:0] bus_sel;
    wire bus_ack, bus_err;
    wire dma_bus_ack, dma_bus_err;
    wire [31:0] dma_master_dat_i;
    wire dma_master_cyc, dma_master_stb, dma_master_we;
    wire [31:0] dma_master_adr, dma_master_dat_o;
    wire [3:0] dma_master_sel;

    wire memory_cyc, memory_stb, memory_we;
    wire [31:0] memory_adr, memory_dat_o, memory_dat_i;
    wire [3:0] memory_sel;
    wire memory_ack, memory_err;

    wire accelerator_cyc, accelerator_stb, accelerator_we;
    wire [31:0] accelerator_adr, accelerator_dat_o;
    wire [3:0] accelerator_sel;
    wire [31:0] accelerator_dat_i;
    wire accelerator_ack, accelerator_err;
    wire dma_cyc, dma_stb, dma_we;
    wire [31:0] dma_adr, dma_dat_o;
    wire [3:0] dma_sel;
    wire [31:0] dma_dat_i;
    wire dma_ack, dma_err;
    wire dma_irq;

    wire interrupt_cyc, interrupt_stb, interrupt_we;
    wire [31:0] interrupt_adr, interrupt_dat_o;
    wire [3:0] interrupt_sel;
    wire [31:0] interrupt_dat_i;
    wire interrupt_ack, interrupt_err;
    wire accelerator_irq;

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

    dma_controller dma (
        .clk(clk), .rst(reset), .cyc_i(dma_cyc), .stb_i(dma_stb), .we_i(dma_we),
        .adr_i(dma_adr[11:0]), .dat_i(dma_dat_o), .sel_i(dma_sel), .dat_o(dma_dat_i),
        .ack_o(dma_ack), .err_o(dma_err), .irq_o(dma_irq), .master_cyc_o(dma_master_cyc),
        .master_stb_o(dma_master_stb), .master_we_o(dma_master_we),
        .master_adr_o(dma_master_adr), .master_dat_o(dma_master_dat_o),
        .master_sel_o(dma_master_sel), .master_dat_i(dma_master_dat_i),
        .master_ack_i(dma_bus_ack), .master_err_i(dma_bus_err)
    );

    wishbone_bus_arbiter bus_arbiter (
        .clk(clk), .rst(reset),
        .cpu_cyc_i(wb_cyc), .cpu_stb_i(wb_stb), .cpu_we_i(wb_we),
        .cpu_adr_i(wb_adr), .cpu_dat_i(wb_dat_o), .cpu_sel_i(wb_sel),
        .cpu_dat_o(wb_dat_i), .cpu_ack_o(wb_ack), .cpu_err_o(wb_err),
        .dma_cyc_i(dma_master_cyc), .dma_stb_i(dma_master_stb), .dma_we_i(dma_master_we),
        .dma_adr_i(dma_master_adr), .dma_dat_i(dma_master_dat_o), .dma_sel_i(dma_master_sel),
        .dma_dat_o(dma_master_dat_i), .dma_ack_o(dma_bus_ack), .dma_err_o(dma_bus_err),
        .bus_cyc_o(bus_cyc), .bus_stb_o(bus_stb), .bus_we_o(bus_we),
        .bus_adr_o(bus_adr), .bus_dat_o(bus_dat_o), .bus_sel_o(bus_sel),
        .bus_dat_i(bus_dat_i), .bus_ack_i(bus_ack), .bus_err_i(bus_err)
    );

    wishbone_interconnect bus_decoder (
        .master_cyc_i(bus_cyc), .master_stb_i(bus_stb), .master_we_i(bus_we),
        .master_adr_i(bus_adr), .master_dat_i(bus_dat_o), .master_sel_i(bus_sel),
        .master_dat_o(bus_dat_i), .master_ack_o(bus_ack), .master_err_o(bus_err),
        .memory_cyc_o(memory_cyc), .memory_stb_o(memory_stb), .memory_we_o(memory_we),
        .memory_adr_o(memory_adr), .memory_dat_o(memory_dat_o), .memory_sel_o(memory_sel),
        .memory_dat_i(memory_dat_i), .memory_ack_i(memory_ack), .memory_err_i(memory_err),
        .accelerator_cyc_o(accelerator_cyc), .accelerator_stb_o(accelerator_stb),
        .accelerator_we_o(accelerator_we), .accelerator_adr_o(accelerator_adr),
        .accelerator_dat_o(accelerator_dat_o), .accelerator_sel_o(accelerator_sel),
        .accelerator_dat_i(accelerator_dat_i), .accelerator_ack_i(accelerator_ack),
        .accelerator_err_i(accelerator_err),
        .dma_cyc_o(dma_cyc), .dma_stb_o(dma_stb), .dma_we_o(dma_we), .dma_adr_o(dma_adr),
        .dma_dat_o(dma_dat_o), .dma_sel_o(dma_sel),
        .dma_dat_i(dma_dat_i), .dma_ack_i(dma_ack), .dma_err_i(dma_err),
        .interrupt_cyc_o(interrupt_cyc), .interrupt_stb_o(interrupt_stb),
        .interrupt_we_o(interrupt_we), .interrupt_adr_o(interrupt_adr),
        .interrupt_dat_o(interrupt_dat_o), .interrupt_sel_o(interrupt_sel),
        .interrupt_dat_i(interrupt_dat_i), .interrupt_ack_i(interrupt_ack),
        .interrupt_err_i(interrupt_err)
    );

    interrupt_controller interrupt_block (
        .clk(clk), .rst(reset),
        .cyc_i(interrupt_cyc), .stb_i(interrupt_stb), .we_i(interrupt_we),
        .adr_i(interrupt_adr[11:0]), .dat_i(interrupt_dat_o), .sel_i(interrupt_sel),
        .dat_o(interrupt_dat_i), .ack_o(interrupt_ack), .err_o(interrupt_err),
        .irq_i({accelerator_irq, dma_irq}), .irq_o()
    );

    convolution_accel_regs accelerator (
        .clk(clk), .rst(reset), .cyc_i(accelerator_cyc), .stb_i(accelerator_stb),
        .we_i(accelerator_we), .adr_i(accelerator_adr[11:0]), .dat_i(accelerator_dat_o),
        .sel_i(accelerator_sel), .dat_o(accelerator_dat_i), .ack_o(accelerator_ack),
        .err_o(accelerator_err), .irq_o(accelerator_irq)
    );

    wishbone_ram #(.BYTES(DATA_BYTES)) memory_target (
        .clk(clk), .rst(reset), .cyc_i(memory_cyc), .stb_i(memory_stb),
        .we_i(memory_we), .adr_i(memory_adr), .dat_i(memory_dat_o),
        .sel_i(memory_sel), .dat_o(memory_dat_i), .ack_o(memory_ack), .err_o(memory_err)
    );
endmodule

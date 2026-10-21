module wishbone_interconnect (
    input  wire        master_cyc_i,
    input  wire        master_stb_i,
    input  wire        master_we_i,
    input  wire [31:0] master_adr_i,
    input  wire [31:0] master_dat_i,
    input  wire [3:0]  master_sel_i,
    output wire [31:0] master_dat_o,
    output wire        master_ack_o,
    output wire        master_err_o,

    output wire        memory_cyc_o,
    output wire        memory_stb_o,
    output wire        memory_we_o,
    output wire [31:0] memory_adr_o,
    output wire [31:0] memory_dat_o,
    output wire [3:0]  memory_sel_o,
    input  wire [31:0] memory_dat_i,
    input  wire        memory_ack_i,
    input  wire        memory_err_i,

    output wire        accelerator_cyc_o,
    output wire        accelerator_stb_o,
    output wire        accelerator_we_o,
    output wire [31:0] accelerator_adr_o,
    output wire [31:0] accelerator_dat_o,
    output wire [3:0]  accelerator_sel_o,
    input  wire [31:0] accelerator_dat_i,
    input  wire        accelerator_ack_i,
    input  wire        accelerator_err_i,

    output wire        dma_cyc_o,
    output wire        dma_stb_o,
    output wire        dma_we_o,
    output wire [31:0] dma_adr_o,
    output wire [31:0] dma_dat_o,
    output wire [3:0]  dma_sel_o,
    input  wire [31:0] dma_dat_i,
    input  wire        dma_ack_i,
    input  wire        dma_err_i,

    output wire        interrupt_cyc_o,
    output wire        interrupt_stb_o,
    output wire        interrupt_we_o,
    output wire [31:0] interrupt_adr_o,
    output wire [31:0] interrupt_dat_o,
    output wire [3:0]  interrupt_sel_o,
    input  wire [31:0] interrupt_dat_i,
    input  wire        interrupt_ack_i,
    input  wire        interrupt_err_i
);
    wire memory_select = (master_adr_i[31:16] == 16'h0000);
    wire accelerator_select = (master_adr_i[31:12] == 20'h40000);
    wire dma_select = (master_adr_i[31:12] == 20'h40001);
    wire interrupt_select = (master_adr_i[31:12] == 20'h40002);
    wire request = master_cyc_i && master_stb_i;

    assign memory_cyc_o = master_cyc_i && memory_select;
    assign memory_stb_o = master_stb_i && memory_select;
    assign memory_we_o = master_we_i;
    assign memory_adr_o = master_adr_i;
    assign memory_dat_o = master_dat_i;
    assign memory_sel_o = master_sel_i;

    assign accelerator_cyc_o = master_cyc_i && accelerator_select;
    assign accelerator_stb_o = master_stb_i && accelerator_select;
    assign accelerator_we_o = master_we_i;
    assign accelerator_adr_o = master_adr_i;
    assign accelerator_dat_o = master_dat_i;
    assign accelerator_sel_o = master_sel_i;

    assign dma_cyc_o = master_cyc_i && dma_select;
    assign dma_stb_o = master_stb_i && dma_select;
    assign dma_we_o = master_we_i;
    assign dma_adr_o = master_adr_i;
    assign dma_dat_o = master_dat_i;
    assign dma_sel_o = master_sel_i;

    assign interrupt_cyc_o = master_cyc_i && interrupt_select;
    assign interrupt_stb_o = master_stb_i && interrupt_select;
    assign interrupt_we_o = master_we_i;
    assign interrupt_adr_o = master_adr_i;
    assign interrupt_dat_o = master_dat_i;
    assign interrupt_sel_o = master_sel_i;

    assign master_dat_o = memory_select ? memory_dat_i :
                          accelerator_select ? accelerator_dat_i :
                          dma_select ? dma_dat_i : interrupt_dat_i;
    assign master_ack_o = memory_select ? memory_ack_i :
                          accelerator_select ? accelerator_ack_i :
                          dma_select ? dma_ack_i : interrupt_ack_i;
    assign master_err_o = request && !memory_select && !accelerator_select && !dma_select && !interrupt_select ||
                          memory_select && memory_err_i ||
                          accelerator_select && accelerator_err_i ||
                          dma_select && dma_err_i ||
                          interrupt_select && interrupt_err_i;
endmodule

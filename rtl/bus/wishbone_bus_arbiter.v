module wishbone_bus_arbiter (
    input  wire        clk,
    input  wire        rst,
    input  wire        cpu_cyc_i,
    input  wire        cpu_stb_i,
    input  wire        cpu_we_i,
    input  wire [31:0] cpu_adr_i,
    input  wire [31:0] cpu_dat_i,
    input  wire [3:0]  cpu_sel_i,
    output wire [31:0] cpu_dat_o,
    output wire        cpu_ack_o,
    output wire        cpu_err_o,
    input  wire        dma_cyc_i,
    input  wire        dma_stb_i,
    input  wire        dma_we_i,
    input  wire [31:0] dma_adr_i,
    input  wire [31:0] dma_dat_i,
    input  wire [3:0]  dma_sel_i,
    output wire [31:0] dma_dat_o,
    output wire        dma_ack_o,
    output wire        dma_err_o,
    output wire        bus_cyc_o,
    output wire        bus_stb_o,
    output wire        bus_we_o,
    output wire [31:0] bus_adr_o,
    output wire [31:0] bus_dat_o,
    output wire [3:0]  bus_sel_o,
    input  wire [31:0] bus_dat_i,
    input  wire        bus_ack_i,
    input  wire        bus_err_i
);
    reg busy;
    reg owner_dma;
    wire cpu_request = cpu_cyc_i && cpu_stb_i;
    wire dma_request = dma_cyc_i && dma_stb_i;
    wire selected_cyc = owner_dma ? dma_cyc_i : cpu_cyc_i;

    assign bus_cyc_o = busy && selected_cyc;
    assign bus_stb_o = busy && (owner_dma ? dma_stb_i : cpu_stb_i);
    assign bus_we_o = owner_dma ? dma_we_i : cpu_we_i;
    assign bus_adr_o = owner_dma ? dma_adr_i : cpu_adr_i;
    assign bus_dat_o = owner_dma ? dma_dat_i : cpu_dat_i;
    assign bus_sel_o = owner_dma ? dma_sel_i : cpu_sel_i;

    assign cpu_dat_o = bus_dat_i;
    assign dma_dat_o = bus_dat_i;
    assign cpu_ack_o = !owner_dma && bus_ack_i;
    assign cpu_err_o = !owner_dma && bus_err_i;
    assign dma_ack_o = owner_dma && bus_ack_i;
    assign dma_err_o = owner_dma && bus_err_i;

    always @(posedge clk) begin
        if (rst) begin
            busy <= 1'b0;
            owner_dma <= 1'b0;
        end else if (busy) begin
            if (bus_ack_i || bus_err_i) busy <= 1'b0;
        end else if (cpu_request) begin
            busy <= 1'b1;
            owner_dma <= 1'b0;
        end else if (dma_request) begin
            busy <= 1'b1;
            owner_dma <= 1'b1;
        end
    end
endmodule

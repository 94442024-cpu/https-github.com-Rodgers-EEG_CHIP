module wishbone_master_bridge (
    input  wire        clk,
    input  wire        rst,
    input  wire        cpu_req_i,
    input  wire        cpu_we_i,
    input  wire [31:0] cpu_adr_i,
    input  wire [31:0] cpu_dat_i,
    input  wire [3:0]  cpu_sel_i,
    output reg  [31:0] cpu_dat_o,
    output reg         cpu_ack_o,
    output reg         cpu_err_o,
    output wire        wb_cyc_o,
    output wire        wb_stb_o,
    output wire        wb_we_o,
    output wire [31:0] wb_adr_o,
    output wire [31:0] wb_dat_o,
    output wire [3:0]  wb_sel_o,
    input  wire [31:0] wb_dat_i,
    input  wire        wb_ack_i,
    input  wire        wb_err_i
);
    reg        busy;
    reg        request_we;
    reg [31:0] request_adr;
    reg [31:0] request_dat;
    reg [3:0]  request_sel;

    assign wb_cyc_o = busy;
    assign wb_stb_o = busy;
    assign wb_we_o = request_we;
    assign wb_adr_o = request_adr;
    assign wb_dat_o = request_dat;
    assign wb_sel_o = request_sel;

    always @(posedge clk) begin
        if (rst) begin
            busy <= 1'b0;
            request_we <= 1'b0;
            request_adr <= 32'd0;
            request_dat <= 32'd0;
            request_sel <= 4'd0;
            cpu_dat_o <= 32'd0;
            cpu_ack_o <= 1'b0;
            cpu_err_o <= 1'b0;
        end else begin
            cpu_ack_o <= 1'b0;
            cpu_err_o <= 1'b0;

            if (busy) begin
                if (wb_ack_i || wb_err_i) begin
                    busy <= 1'b0;
                    cpu_dat_o <= wb_dat_i;
                    cpu_ack_o <= wb_ack_i;
                    cpu_err_o <= wb_err_i;
                end
            end else if (cpu_req_i) begin
                busy <= 1'b1;
                request_we <= cpu_we_i;
                request_adr <= cpu_adr_i;
                request_dat <= cpu_dat_i;
                request_sel <= cpu_sel_i;
            end
        end
    end
endmodule

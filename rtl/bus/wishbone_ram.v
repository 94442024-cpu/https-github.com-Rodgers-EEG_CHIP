module wishbone_ram #(
    parameter BYTES = 65536
) (
    input  wire        clk,
    input  wire        rst,
    input  wire        cyc_i,
    input  wire        stb_i,
    input  wire        we_i,
    input  wire [31:0] adr_i,
    input  wire [31:0] dat_i,
    input  wire [3:0]  sel_i,
    output reg  [31:0] dat_o,
    output reg         ack_o,
    output reg         err_o
);
    reg [7:0] memory [0:BYTES-1];
    wire request = cyc_i && stb_i;
    integer index;

    always @* begin
        dat_o = {
            memory[adr_i + 3], memory[adr_i + 2],
            memory[adr_i + 1], memory[adr_i]
        };
        err_o = request && (adr_i + 3 >= BYTES);
        ack_o = request && !err_o;
    end

    always @(posedge clk) begin
        if (rst) begin
            for (index = 0; index < BYTES; index = index + 1)
                memory[index] <= 8'd0;
        end else if (request && !err_o && we_i) begin
            if (sel_i[0]) memory[adr_i] <= dat_i[7:0];
            if (sel_i[1]) memory[adr_i + 1] <= dat_i[15:8];
            if (sel_i[2]) memory[adr_i + 2] <= dat_i[23:16];
            if (sel_i[3]) memory[adr_i + 3] <= dat_i[31:24];
        end
    end
endmodule

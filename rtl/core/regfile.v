module regfile (
    input  wire        clk,
    input  wire        reset,
    input  wire [4:0]  rs1_addr,
    input  wire [4:0]  rs2_addr,
    output wire [31:0] rs1_data,
    output wire [31:0] rs2_data,
    input  wire        write_enable,
    input  wire [4:0]  rd_addr,
    input  wire [31:0] rd_data
);
    reg [31:0] registers [0:31];
    integer index;

    assign rs1_data = (rs1_addr == 5'd0) ? 32'd0 : registers[rs1_addr];
    assign rs2_data = (rs2_addr == 5'd0) ? 32'd0 : registers[rs2_addr];

    always @(posedge clk) begin
        if (reset) begin
            for (index = 0; index < 32; index = index + 1)
                registers[index] <= 32'd0;
        end else if (write_enable && (rd_addr != 5'd0)) begin
            registers[rd_addr] <= rd_data;
        end
    end
endmodule

module instr_mem #(
    parameter WORDS = 1024
) (
    input  wire [31:0] address,
    output wire [31:0] instruction
);
    reg [31:0] memory [0:WORDS-1];

    assign instruction = (address[31:2] < WORDS) ? memory[address[31:2]] : 32'd0;
endmodule

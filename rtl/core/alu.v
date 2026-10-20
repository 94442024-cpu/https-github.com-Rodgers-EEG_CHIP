module alu (
    input  wire [31:0] left_operand,
    input  wire [31:0] right_operand,
    input  wire [3:0]  operation,
    output reg  [31:0] result,
    output wire        equal,
    output wire        signed_less_than,
    output wire        unsigned_less_than
);
    localparam ALU_ADD = 4'd0;
    localparam ALU_SUB = 4'd1;
    localparam ALU_SLL = 4'd2;
    localparam ALU_SLT = 4'd3;
    localparam ALU_SLTU = 4'd4;
    localparam ALU_XOR = 4'd5;
    localparam ALU_SRL = 4'd6;
    localparam ALU_SRA = 4'd7;
    localparam ALU_OR = 4'd8;
    localparam ALU_AND = 4'd9;

    assign equal = (left_operand == right_operand);
    assign signed_less_than = ($signed(left_operand) < $signed(right_operand));
    assign unsigned_less_than = (left_operand < right_operand);

    always @* begin
        case (operation)
            ALU_ADD:  result = left_operand + right_operand;
            ALU_SUB:  result = left_operand - right_operand;
            ALU_SLL:  result = left_operand << right_operand[4:0];
            ALU_SLT:  result = {31'd0, signed_less_than};
            ALU_SLTU: result = {31'd0, unsigned_less_than};
            ALU_XOR:  result = left_operand ^ right_operand;
            ALU_SRL:  result = left_operand >> right_operand[4:0];
            ALU_SRA:  result = $signed(left_operand) >>> right_operand[4:0];
            ALU_OR:   result = left_operand | right_operand;
            ALU_AND:  result = left_operand & right_operand;
            default:  result = 32'd0;
        endcase
    end
endmodule

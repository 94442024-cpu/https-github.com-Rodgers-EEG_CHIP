module control (
    input  wire [6:0] opcode,
    input  wire [2:0] funct3,
    input  wire [6:0] funct7,
    output reg        valid,
    output reg        register_write,
    output reg        memory_write,
    output reg        alu_uses_immediate,
    output reg [1:0]  writeback_select,
    output reg [3:0]  alu_operation,
    output reg [2:0]  immediate_type,
    output reg [2:0]  branch_type,
    output reg        branch,
    output reg        jump,
    output reg        jump_register,
    output reg [1:0]  memory_width,
    output reg        load_unsigned
);
    localparam OPCODE_LUI = 7'b0110111;
    localparam OPCODE_AUIPC = 7'b0010111;
    localparam OPCODE_JAL = 7'b1101111;
    localparam OPCODE_JALR = 7'b1100111;
    localparam OPCODE_BRANCH = 7'b1100011;
    localparam OPCODE_LOAD = 7'b0000011;
    localparam OPCODE_STORE = 7'b0100011;
    localparam OPCODE_OP_IMM = 7'b0010011;
    localparam OPCODE_OP = 7'b0110011;

    localparam WB_ALU = 2'd0;
    localparam WB_MEMORY = 2'd1;
    localparam WB_PC_PLUS_4 = 2'd2;
    localparam WB_IMMEDIATE = 2'd3;

    localparam IMM_I = 3'd0;
    localparam IMM_S = 3'd1;
    localparam IMM_B = 3'd2;
    localparam IMM_U = 3'd3;
    localparam IMM_J = 3'd4;

    localparam BRANCH_BEQ = 3'b000;
    localparam BRANCH_BNE = 3'b001;
    localparam BRANCH_BLT = 3'b100;
    localparam BRANCH_BGE = 3'b101;
    localparam BRANCH_BLTU = 3'b110;
    localparam BRANCH_BGEU = 3'b111;

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

    always @* begin
        valid = 1'b0;
        register_write = 1'b0;
        memory_write = 1'b0;
        alu_uses_immediate = 1'b0;
        writeback_select = WB_ALU;
        alu_operation = ALU_ADD;
        immediate_type = IMM_I;
        branch_type = BRANCH_BEQ;
        branch = 1'b0;
        jump = 1'b0;
        jump_register = 1'b0;
        memory_width = 2'd2;
        load_unsigned = 1'b0;

        case (opcode)
            OPCODE_LUI: begin
                valid = 1'b1;
                register_write = 1'b1;
                alu_uses_immediate = 1'b1;
                writeback_select = WB_IMMEDIATE;
                immediate_type = IMM_U;
            end
            OPCODE_AUIPC: begin
                valid = 1'b1;
                register_write = 1'b1;
                alu_uses_immediate = 1'b1;
                immediate_type = IMM_U;
            end
            OPCODE_JAL: begin
                valid = 1'b1;
                register_write = 1'b1;
                writeback_select = WB_PC_PLUS_4;
                immediate_type = IMM_J;
                jump = 1'b1;
            end
            OPCODE_JALR: begin
                if (funct3 == 3'b000) begin
                    valid = 1'b1;
                    register_write = 1'b1;
                    alu_uses_immediate = 1'b1;
                    writeback_select = WB_PC_PLUS_4;
                    immediate_type = IMM_I;
                    jump = 1'b1;
                    jump_register = 1'b1;
                end
            end
            OPCODE_BRANCH: begin
                if (funct3 == BRANCH_BEQ || funct3 == BRANCH_BNE ||
                    funct3 == BRANCH_BLT || funct3 == BRANCH_BGE ||
                    funct3 == BRANCH_BLTU || funct3 == BRANCH_BGEU) begin
                    valid = 1'b1;
                    immediate_type = IMM_B;
                    branch = 1'b1;
                    branch_type = funct3;
                    alu_operation = ALU_SUB;
                end
            end
            OPCODE_LOAD: begin
                if (funct3 == 3'b000 || funct3 == 3'b001 || funct3 == 3'b010 ||
                    funct3 == 3'b100 || funct3 == 3'b101) begin
                    valid = 1'b1;
                    register_write = 1'b1;
                    alu_uses_immediate = 1'b1;
                    writeback_select = WB_MEMORY;
                    immediate_type = IMM_I;
                    memory_width = (funct3 == 3'b000 || funct3 == 3'b100) ? 2'd0 :
                                   (funct3 == 3'b001 || funct3 == 3'b101) ? 2'd1 : 2'd2;
                    load_unsigned = (funct3 == 3'b100 || funct3 == 3'b101);
                end
            end
            OPCODE_STORE: begin
                if (funct3 == 3'b000 || funct3 == 3'b001 || funct3 == 3'b010) begin
                    valid = 1'b1;
                    memory_write = 1'b1;
                    alu_uses_immediate = 1'b1;
                    immediate_type = IMM_S;
                    memory_width = (funct3 == 3'b000) ? 2'd0 :
                                   (funct3 == 3'b001) ? 2'd1 : 2'd2;
                end
            end
            OPCODE_OP_IMM: begin
                if ((funct3 != 3'b001 && funct3 != 3'b101) ||
                    (funct3 == 3'b001 && funct7 == 7'b0000000) ||
                    (funct3 == 3'b101 &&
                     (funct7 == 7'b0000000 || funct7 == 7'b0100000))) begin
                    valid = 1'b1;
                    register_write = 1'b1;
                    alu_uses_immediate = 1'b1;
                    alu_operation = decode_alu(funct3, funct7);
                    immediate_type = IMM_I;
                end
            end
            OPCODE_OP: begin
                if (funct7 == 7'b0000000 || funct7 == 7'b0100000) begin
                    if (!(funct7 == 7'b0100000 && funct3 != 3'b000 && funct3 != 3'b101)) begin
                        valid = 1'b1;
                        register_write = 1'b1;
                        alu_operation = decode_alu(funct3, funct7);
                    end
                end
            end
            default: begin
                valid = 1'b0;
            end
        endcase
    end

    function [3:0] decode_alu;
        input [2:0] function3;
        input [6:0] function7;
        begin
            case (function3)
                3'b000: decode_alu = (function7 == 7'b0100000) ? ALU_SUB : ALU_ADD;
                3'b001: decode_alu = ALU_SLL;
                3'b010: decode_alu = ALU_SLT;
                3'b011: decode_alu = ALU_SLTU;
                3'b100: decode_alu = ALU_XOR;
                3'b101: decode_alu = (function7 == 7'b0100000) ? ALU_SRA : ALU_SRL;
                3'b110: decode_alu = ALU_OR;
                3'b111: decode_alu = ALU_AND;
                default: decode_alu = ALU_ADD;
            endcase
        end
    endfunction
endmodule

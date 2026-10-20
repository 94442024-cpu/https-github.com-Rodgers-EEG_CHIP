`timescale 1ns/1ps

module riscv_core #(
    parameter INSTRUCTION_WORDS = 1024,
    parameter DATA_BYTES = 4096
) (
    input wire clk,
    input wire reset
);
    localparam WB_ALU = 2'd0;
    localparam WB_MEMORY = 2'd1;
    localparam WB_PC_PLUS_4 = 2'd2;
    localparam WB_IMMEDIATE = 2'd3;

    localparam ALU_ADD = 4'd0;

    reg [31:0] pc;
    wire [31:0] instruction;
    wire [6:0] opcode = instruction[6:0];
    wire [4:0] rd = instruction[11:7];
    wire [2:0] funct3 = instruction[14:12];
    wire [4:0] rs1 = instruction[19:15];
    wire [4:0] rs2 = instruction[24:20];
    wire [6:0] funct7 = instruction[31:25];

    wire valid;
    wire register_write;
    wire memory_write;
    wire alu_uses_immediate;
    wire [1:0] writeback_select;
    wire [3:0] alu_operation;
    wire [2:0] immediate_type;
    wire [2:0] branch_type;
    wire branch;
    wire jump;
    wire jump_register;
    wire [1:0] memory_width;
    wire load_unsigned;
    wire [31:0] immediate;
    wire [31:0] rs1_data;
    wire [31:0] rs2_data;
    wire [31:0] alu_right;
    wire [31:0] alu_result;
    wire equal;
    wire signed_less_than;
    wire unsigned_less_than;
    wire [31:0] data_read;
    wire [31:0] writeback_data;
    wire branch_taken;
    wire [31:0] next_pc;
    wire is_auipc = (opcode == 7'b0010111);
    wire [31:0] alu_left = is_auipc ? pc : rs1_data;

    instr_mem #(.WORDS(INSTRUCTION_WORDS)) instruction_memory (
        .address(pc), .instruction(instruction)
    );

    data_mem #(.BYTES(DATA_BYTES)) data_memory (
        .clk(clk), .address(alu_result), .write_data(rs2_data),
        .write_enable(memory_write && valid), .access_width(memory_width),
        .load_unsigned(load_unsigned), .read_data(data_read)
    );

    control decoder (
        .opcode(opcode), .funct3(funct3), .funct7(funct7), .valid(valid),
        .register_write(register_write), .memory_write(memory_write),
        .alu_uses_immediate(alu_uses_immediate), .writeback_select(writeback_select),
        .alu_operation(alu_operation), .immediate_type(immediate_type),
        .branch_type(branch_type), .branch(branch), .jump(jump),
        .jump_register(jump_register), .memory_width(memory_width),
        .load_unsigned(load_unsigned)
    );

    imm_gen immediate_generator (
        .instruction(instruction), .immediate_type(immediate_type), .immediate(immediate)
    );

    regfile register_file (
        .clk(clk), .reset(reset), .rs1_addr(rs1), .rs2_addr(rs2),
        .rs1_data(rs1_data), .rs2_data(rs2_data),
        .write_enable(register_write && valid), .rd_addr(rd), .rd_data(writeback_data)
    );

    alu arithmetic_logic_unit (
        .left_operand(alu_left),
        .right_operand(alu_uses_immediate ? immediate : rs2_data),
        .operation(alu_operation), .result(alu_result), .equal(equal),
        .signed_less_than(signed_less_than), .unsigned_less_than(unsigned_less_than)
    );

    assign writeback_data = (writeback_select == WB_MEMORY) ? data_read :
                            (writeback_select == WB_PC_PLUS_4) ? (pc + 32'd4) :
                            (writeback_select == WB_IMMEDIATE) ? immediate : alu_result;

    assign branch_taken = branch && (
        (branch_type == 3'b000 && equal) ||
        (branch_type == 3'b001 && !equal) ||
        (branch_type == 3'b100 && signed_less_than) ||
        (branch_type == 3'b101 && !signed_less_than) ||
        (branch_type == 3'b110 && unsigned_less_than) ||
        (branch_type == 3'b111 && !unsigned_less_than)
    );

    assign next_pc = jump_register ? ((rs1_data + immediate) & 32'hFFFFFFFE) :
                     jump ? (pc + immediate) :
                     branch_taken ? (pc + immediate) : (pc + 32'd4);

    always @(posedge clk) begin
        if (reset)
            pc <= 32'd0;
        else
            pc <= next_pc;
    end
endmodule

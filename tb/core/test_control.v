`timescale 1ns/1ps

module test_control;
    reg [6:0] opcode;
    reg [2:0] funct3;
    reg [6:0] funct7;
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

    control decoder (
        .opcode(opcode), .funct3(funct3), .funct7(funct7), .valid(valid),
        .register_write(register_write), .memory_write(memory_write),
        .alu_uses_immediate(alu_uses_immediate), .writeback_select(writeback_select),
        .alu_operation(alu_operation), .immediate_type(immediate_type),
        .branch_type(branch_type), .branch(branch), .jump(jump),
        .jump_register(jump_register), .memory_width(memory_width),
        .load_unsigned(load_unsigned)
    );

    task expect_valid;
        input expected;
        begin
            #1;
            if (valid !== expected) $fatal(1, "valid expected %b, got %b", expected, valid);
        end
    endtask

    initial begin
        opcode = 7'b0010011;
        funct3 = 3'b000;
        funct7 = 7'b0000000;
        expect_valid(1'b1);
        if (!register_write || !alu_uses_immediate || alu_operation != 4'd0) $fatal(1, "ADDI decode failed");

        opcode = 7'b0110011;
        funct3 = 3'b000;
        funct7 = 7'b0100000;
        expect_valid(1'b1);
        if (alu_operation != 4'd1) $fatal(1, "SUB decode failed");

        opcode = 7'b0000011;
        funct3 = 3'b100;
        expect_valid(1'b1);
        if (!register_write || !load_unsigned || memory_width != 2'd0) $fatal(1, "LBU decode failed");

        opcode = 7'b0100011;
        funct3 = 3'b001;
        expect_valid(1'b1);
        if (!memory_write || memory_width != 2'd1) $fatal(1, "SH decode failed");

        opcode = 7'b1100011;
        funct3 = 3'b110;
        expect_valid(1'b1);
        if (!branch || branch_type != 3'b110) $fatal(1, "BLTU decode failed");

        opcode = 7'b1100111;
        funct3 = 3'b000;
        expect_valid(1'b1);
        if (!jump || !jump_register || writeback_select != 2'd2) $fatal(1, "JALR decode failed");

        opcode = 7'b0010011;
        funct3 = 3'b001;
        funct7 = 7'b0100000;
        expect_valid(1'b0);

        opcode = 7'b1111111;
        expect_valid(1'b0);
        $display("Control-unit tests passed");
        $finish;
    end
endmodule

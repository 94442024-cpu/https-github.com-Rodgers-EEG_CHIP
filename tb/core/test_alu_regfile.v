`timescale 1ns/1ps

module test_alu_regfile;
    reg clk = 1'b0;
    reg reset = 1'b1;
    reg [4:0] rs1_addr;
    reg [4:0] rs2_addr;
    wire [31:0] rs1_data;
    wire [31:0] rs2_data;
    reg write_enable;
    reg [4:0] rd_addr;
    reg [31:0] rd_data;

    reg [31:0] left_operand;
    reg [31:0] right_operand;
    reg [3:0] operation;
    wire [31:0] result;
    wire equal;
    wire signed_less_than;
    wire unsigned_less_than;

    regfile registers (
        .clk(clk), .reset(reset),
        .rs1_addr(rs1_addr), .rs2_addr(rs2_addr),
        .rs1_data(rs1_data), .rs2_data(rs2_data),
        .write_enable(write_enable), .rd_addr(rd_addr), .rd_data(rd_data)
    );

    alu arithmetic_logic_unit (
        .left_operand(left_operand), .right_operand(right_operand),
        .operation(operation), .result(result), .equal(equal),
        .signed_less_than(signed_less_than), .unsigned_less_than(unsigned_less_than)
    );

    always #5 clk = ~clk;

    task expect_result;
        input [3:0] expected_operation;
        input [31:0] expected_result;
        begin
            operation = expected_operation;
            #1;
            if (result !== expected_result) $fatal(1, "ALU operation %0d expected %h, got %h", expected_operation, expected_result, result);
        end
    endtask

    initial begin
        rs1_addr = 0;
        rs2_addr = 0;
        write_enable = 0;
        rd_addr = 0;
        rd_data = 0;
        left_operand = 32'h80000000;
        right_operand = 32'h00000002;
        operation = 0;

        #1;
        if (rs1_data !== 32'd0 || rs2_data !== 32'd0) $fatal(1, "x0 was not zero after reset assertion");
        #9;
        reset = 1'b0;

        write_enable = 1'b1;
        rd_addr = 5'd5;
        rd_data = 32'h12345678;
        #10;
        write_enable = 1'b0;
        rs1_addr = 5'd5;
        #1;
        if (rs1_data !== 32'h12345678) $fatal(1, "register write/read failed");

        rd_addr = 5'd0;
        rd_data = 32'hFFFFFFFF;
        write_enable = 1'b1;
        #10;
        write_enable = 1'b0;
        rs1_addr = 5'd0;
        #1;
        if (rs1_data !== 32'd0) $fatal(1, "x0 was writable");

        expect_result(4'd0, 32'h80000002);
        expect_result(4'd1, 32'h7FFFFFFE);
        expect_result(4'd3, 32'h00000001);
        expect_result(4'd4, 32'h00000000);
        expect_result(4'd6, 32'h20000000);
        expect_result(4'd7, 32'hE0000000);

        $display("ALU and register-file tests passed");
        $finish;
    end
endmodule

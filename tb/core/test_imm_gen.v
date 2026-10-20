`timescale 1ns/1ps

module test_imm_gen;
    reg [31:0] instruction;
    reg [2:0] immediate_type;
    wire [31:0] immediate;

    imm_gen generator (
        .instruction(instruction),
        .immediate_type(immediate_type),
        .immediate(immediate)
    );

    task expect_immediate;
        input [2:0] expected_type;
        input [31:0] expected_value;
        begin
            immediate_type = expected_type;
            #1;
            if (immediate !== expected_value)
                $fatal(1, "immediate type %0d expected %h, got %h", expected_type, expected_value, immediate);
        end
    endtask

    initial begin
        instruction = 32'hFFF00000;
        expect_immediate(3'd0, 32'hFFFFFFFF);

        instruction = 32'hFE208FA3;
        expect_immediate(3'd1, 32'hFFFFFFFF);

        instruction = 32'h00208463;
        expect_immediate(3'd2, 32'h00000008);

        instruction = 32'hABCDE000;
        expect_immediate(3'd3, 32'hABCDE000);

        instruction = 32'h008000EF;
        expect_immediate(3'd4, 32'h00000008);

        $display("Immediate-generator tests passed");
        $finish;
    end
endmodule

`timescale 1ns/1ps

module test_riscv_core;
    reg clk = 1'b0;
    reg reset = 1'b1;
    riscv_core dut (.clk(clk), .reset(reset));

    always #5 clk = ~clk;

    initial begin
        dut.instruction_memory.memory[0] = 32'h00500093;
        dut.instruction_memory.memory[1] = 32'h00700113;
        dut.instruction_memory.memory[2] = 32'h002081B3;
        dut.instruction_memory.memory[3] = 32'h10302023;
        dut.instruction_memory.memory[4] = 32'h10002203;
        dut.instruction_memory.memory[5] = 32'h00418463;
        dut.instruction_memory.memory[6] = 32'h00100293;
        dut.instruction_memory.memory[7] = 32'h00200293;
        dut.instruction_memory.memory[8] = 32'h00000013;

        #12;
        reset = 1'b0;
        repeat (8) @(posedge clk);
        #1;

        if (dut.register_file.registers[3] !== 32'd12) $fatal(1, "ADD result incorrect");
        if (dut.register_file.registers[4] !== 32'd12) $fatal(1, "LW result incorrect");
        if (dut.register_file.registers[5] !== 32'd2) $fatal(1, "taken branch result incorrect");
        if (dut.register_file.registers[0] !== 32'd0) $fatal(1, "x0 changed");
        if ({dut.data_memory.memory[259], dut.data_memory.memory[258], dut.data_memory.memory[257], dut.data_memory.memory[256]} !== 32'd12)
            $fatal(1, "SW result incorrect");

        $display("RV32I core smoke test passed");
        $finish;
    end
endmodule

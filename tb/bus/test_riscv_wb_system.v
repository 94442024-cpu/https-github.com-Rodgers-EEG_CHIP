`timescale 1ns/1ps

module test_riscv_wb_system;
    reg clk = 1'b0;
    reg reset = 1'b1;
    riscv_wb_system #(.DATA_BYTES(512)) dut (.clk(clk), .reset(reset));

    always #5 clk = ~clk;

    initial begin
        dut.cpu.instruction_memory.memory[0] = 32'h04000093;
        dut.cpu.instruction_memory.memory[1] = 32'h02A00113;
        dut.cpu.instruction_memory.memory[2] = 32'h0020A023;
        dut.cpu.instruction_memory.memory[3] = 32'h0000A183;
        dut.cpu.instruction_memory.memory[4] = 32'h00218463;
        dut.cpu.instruction_memory.memory[5] = 32'h06300213;
        dut.cpu.instruction_memory.memory[6] = 32'h00700213;
        dut.cpu.instruction_memory.memory[7] = 32'h00000013;

        #12;
        reset = 1'b0;
        repeat (14) @(posedge clk);
        #1;

        if (dut.cpu.register_file.registers[3] !== 32'h2A) $fatal(1, "external LW result incorrect");
        if (dut.cpu.register_file.registers[4] !== 32'd7) $fatal(1, "external branch result incorrect");
        if ({dut.memory_target.memory[67], dut.memory_target.memory[66], dut.memory_target.memory[65], dut.memory_target.memory[64]} !== 32'h2A)
            $fatal(1, "external SW result incorrect");

        $display("RISC-V to Wishbone system test passed");
        $finish;
    end
endmodule

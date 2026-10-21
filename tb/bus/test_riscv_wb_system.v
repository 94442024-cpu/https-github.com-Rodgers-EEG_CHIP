`timescale 1ns/1ps

module test_riscv_wb_system;
    reg clk = 1'b0;
    reg reset = 1'b1;
    riscv_wb_system #(.DATA_BYTES(512)) dut (.clk(clk), .reset(reset));

    always #5 clk = ~clk;

    initial begin
        dut.cpu.instruction_memory.memory[0] = 32'h00300093;
        dut.cpu.instruction_memory.memory[1] = 32'hFFC00113;
        dut.cpu.instruction_memory.memory[2] = 32'h400001B7;
        dut.cpu.instruction_memory.memory[3] = 32'h0011A423;
        dut.cpu.instruction_memory.memory[4] = 32'h0021A623;
        dut.cpu.instruction_memory.memory[5] = 32'h0011A023;
        dut.cpu.instruction_memory.memory[6] = 32'h0041A283;
        dut.cpu.instruction_memory.memory[7] = 32'h0101A303;
        dut.cpu.instruction_memory.memory[8] = 32'h00700393;

        #12;
        reset = 1'b0;
        repeat (24) @(posedge clk);
        #1;

        if (dut.cpu.register_file.registers[5] !== 32'h00000002) $fatal(1, "accelerator status read incorrect");
        if (dut.cpu.register_file.registers[6] !== 32'hFFFFFFF4) $fatal(1, "accelerator result read incorrect");
        if (dut.cpu.register_file.registers[7] !== 32'd7) $fatal(1, "CPU did not continue after accelerator access");

        $display("RISC-V to Wishbone system test passed");
        $finish;
    end
endmodule

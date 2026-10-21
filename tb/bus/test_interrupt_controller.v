`timescale 1ns/1ps

module test_interrupt_controller;
    reg clk = 1'b0;
    reg rst = 1'b1;
    reg cyc_i, stb_i, we_i;
    reg [11:0] adr_i;
    reg [31:0] dat_i;
    reg [3:0] sel_i;
    wire [31:0] dat_o;
    wire ack_o, err_o;
    reg [1:0] irq_i;
    wire irq_o;

    interrupt_controller irq (
        .clk(clk), .rst(rst), .cyc_i(cyc_i), .stb_i(stb_i), .we_i(we_i),
        .adr_i(adr_i), .dat_i(dat_i), .sel_i(sel_i), .dat_o(dat_o),
        .ack_o(ack_o), .err_o(err_o), .irq_i(irq_i), .irq_o(irq_o)
    );

    always #5 clk = ~clk;

    task write_reg;
        input [11:0] address;
        input [31:0] value;
        begin
            @(negedge clk);
            adr_i = address;
            dat_i = value;
            we_i = 1'b1;
            cyc_i = 1'b1;
            stb_i = 1'b1;
            #1;
            if (!ack_o || err_o) $fatal(1, "write failed at %h", address);
            @(negedge clk);
            cyc_i = 1'b0;
            stb_i = 1'b0;
            we_i = 1'b0;
        end
    endtask

    task read_reg;
        input [11:0] address;
        input [31:0] expected;
        begin
            @(negedge clk);
            adr_i = address;
            we_i = 1'b0;
            cyc_i = 1'b1;
            stb_i = 1'b1;
            #1;
            if (!ack_o || err_o || dat_o !== expected) $fatal(1, "read failed at %h expected %h got %h", address, expected, dat_o);
            @(negedge clk);
            cyc_i = 1'b0;
            stb_i = 1'b0;
        end
    endtask

    initial begin
        cyc_i = 0; stb_i = 0; we_i = 0; adr_i = 0; dat_i = 0; sel_i = 4'hF; irq_i = 2'b00;
        #12;
        rst = 1'b0;

        irq_i = 2'b01;
        @(posedge clk);
        #1;
        if (!irq_o) $fatal(1, "irq not asserted when pending and masked");
        read_reg(12'h000, 32'h00000001);

        irq_i = 2'b00;
        write_reg(12'h008, 32'h00000001);
        read_reg(12'h000, 32'h00000000);
        if (irq_o) $fatal(1, "irq stayed active after clear");

        irq_i = 2'b10;
        @(posedge clk);
        #1;
        if (!irq_o) $fatal(1, "second pending bit did not assert");
        write_reg(12'h004, 32'h00000000);
        if (irq_o) $fatal(1, "mask write did not disable interrupt");
        irq_i = 2'b00;

        @(negedge clk);
        adr_i = 12'h100;
        cyc_i = 1'b1;
        stb_i = 1'b1;
        #1;
        if (!err_o || ack_o) $fatal(1, "invalid interrupt register address did not error");

        $display("Interrupt controller tests passed");
        $finish;
    end
endmodule

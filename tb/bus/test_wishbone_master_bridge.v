`timescale 1ns/1ps

module test_wishbone_master_bridge;
    reg clk = 1'b0;
    reg rst = 1'b1;
    reg cpu_req_i, cpu_we_i;
    reg [31:0] cpu_adr_i, cpu_dat_i;
    reg [3:0] cpu_sel_i;
    wire [31:0] cpu_dat_o;
    wire cpu_ack_o, cpu_err_o;
    wire wb_cyc_o, wb_stb_o, wb_we_o;
    wire [31:0] wb_adr_o, wb_dat_o;
    wire [3:0] wb_sel_o;
    reg [31:0] wb_dat_i;
    reg wb_ack_i, wb_err_i;

    wishbone_master_bridge bridge (
        .clk(clk), .rst(rst), .cpu_req_i(cpu_req_i), .cpu_we_i(cpu_we_i),
        .cpu_adr_i(cpu_adr_i), .cpu_dat_i(cpu_dat_i), .cpu_sel_i(cpu_sel_i),
        .cpu_dat_o(cpu_dat_o), .cpu_ack_o(cpu_ack_o), .cpu_err_o(cpu_err_o),
        .wb_cyc_o(wb_cyc_o), .wb_stb_o(wb_stb_o), .wb_we_o(wb_we_o),
        .wb_adr_o(wb_adr_o), .wb_dat_o(wb_dat_o), .wb_sel_o(wb_sel_o),
        .wb_dat_i(wb_dat_i), .wb_ack_i(wb_ack_i), .wb_err_i(wb_err_i)
    );

    always #5 clk = ~clk;

    task start_request;
        input write_enable;
        input [31:0] address;
        input [31:0] data;
        begin
            @(negedge clk);
            cpu_we_i = write_enable;
            cpu_adr_i = address;
            cpu_dat_i = data;
            cpu_sel_i = 4'hF;
            cpu_req_i = 1'b1;
            @(negedge clk);
            cpu_req_i = 1'b0;
            #1;
            if (!wb_cyc_o || !wb_stb_o || wb_we_o !== write_enable || wb_adr_o !== address || wb_dat_o !== data)
                $fatal(1, "Wishbone request was not held correctly");
        end
    endtask

    initial begin
        cpu_req_i = 0;
        cpu_we_i = 0;
        cpu_adr_i = 0;
        cpu_dat_i = 0;
        cpu_sel_i = 0;
        wb_dat_i = 0;
        wb_ack_i = 0;
        wb_err_i = 0;
        #12;
        rst = 1'b0;

        start_request(1'b1, 32'h40000010, 32'hAABBCCDD);
        wb_ack_i = 1'b1;
        @(negedge clk);
        #1;
        if (!cpu_ack_o || cpu_err_o || wb_cyc_o) $fatal(1, "write completion failed");
        wb_ack_i = 1'b0;

        wb_dat_i = 32'h12345678;
        start_request(1'b0, 32'h00000020, 32'd0);
        wb_ack_i = 1'b1;
        @(negedge clk);
        #1;
        if (!cpu_ack_o || cpu_err_o || cpu_dat_o !== 32'h12345678) $fatal(1, "read completion failed");
        wb_ack_i = 1'b0;

        start_request(1'b0, 32'h80000000, 32'd0);
        wb_err_i = 1'b1;
        @(negedge clk);
        #1;
        if (cpu_ack_o || !cpu_err_o || wb_cyc_o) $fatal(1, "error completion failed");

        $display("Wishbone master bridge tests passed");
        $finish;
    end
endmodule

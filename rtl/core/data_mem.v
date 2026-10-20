module data_mem #(
    parameter BYTES = 4096
) (
    input  wire        clk,
    input  wire [31:0] address,
    input  wire [31:0] write_data,
    input  wire        write_enable,
    input  wire [1:0]  access_width,
    input  wire        load_unsigned,
    output reg  [31:0] read_data
);
    reg [7:0] memory [0:BYTES-1];
    integer index;

    always @* begin
        case (access_width)
            2'd0: begin
                if (load_unsigned)
                    read_data = {24'd0, memory[address]};
                else
                    read_data = {{24{memory[address][7]}}, memory[address]};
            end
            2'd1: begin
                if (load_unsigned)
                    read_data = {16'd0, memory[address + 1], memory[address]};
                else
                    read_data = {{16{memory[address + 1][7]}}, memory[address + 1], memory[address]};
            end
            default: read_data = {memory[address + 3], memory[address + 2], memory[address + 1], memory[address]};
        endcase
    end

    always @(posedge clk) begin
        if (write_enable) begin
            case (access_width)
                2'd0: memory[address] <= write_data[7:0];
                2'd1: begin
                    memory[address] <= write_data[7:0];
                    memory[address + 1] <= write_data[15:8];
                end
                default: begin
                    memory[address] <= write_data[7:0];
                    memory[address + 1] <= write_data[15:8];
                    memory[address + 2] <= write_data[23:16];
                    memory[address + 3] <= write_data[31:24];
                end
            endcase
        end
    end
endmodule

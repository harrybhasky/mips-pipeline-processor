// Register File Module
// 32 registers, each 32-bit wide
// r0 is always zero

module register_file (
    input wire clk,
    input wire reset,
    input wire reg_write,
    input wire [4:0] read_reg1,
    input wire [4:0] read_reg2,
    input wire [4:0] write_reg,
    input wire [31:0] write_data,
    output wire [31:0] read_data1,
    output wire [31:0] read_data2
);

reg [31:0] registers [31:0];

initial begin 
    integer i;
    for (i = 0; i < 32; i = i + 1) begin
        registers[i] = 32'b0;
    end
end

always @(posedge clk or posedge reset) begin // used sequential for write
    if (reset) begin
        integer j;
        for (j = 0; j < 32; j = j + 1) begin
            registers[j] <= 32'b0;
        end
    end
    else if (reg_write && write_reg != 5'b00000) begin
        registers[write_reg] <= write_data;
    end
end

assign read_data1 = (read_reg1 == 5'b00000) ? 32'b0 : registers[read_reg1];
assign read_data2 = (read_reg2 == 5'b00000) ? 32'b0 : registers[read_reg2];

endmodule

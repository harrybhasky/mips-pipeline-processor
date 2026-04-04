// Register File Module
// 32 registers, each 32-bit wide
// R0 is always zero

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

    // 32 registers, each 32-bit
    reg [31:0] registers [0:31];
    
    integer i;
    
    // Read operations (combinational)
    assign read_data1 = (read_reg1 == 5'b0) ? 32'b0 : registers[read_reg1];
    assign read_data2 = (read_reg2 == 5'b0) ? 32'b0 : registers[read_reg2];
    
    // Write operation (sequential)
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            // Initialize all registers to zero on reset
            for (i = 0; i < 32; i = i + 1)
                registers[i] <= 32'b0;
        end
        else if (reg_write && write_reg != 5'b0) begin
            // Write to register (except R0 which is always 0)
            registers[write_reg] <= write_data;
        end
    end

endmodule

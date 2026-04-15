// Data Memory Module
// Byte-addressable memory

module data_memory (
    input wire clk,
    input wire reset,
    input wire mem_read,
    input wire mem_write,
    input wire [31:0] address,
    input wire [31:0] write_data,
    output wire [31:0] read_data
);

    // Data memory - 1024 bytes
    reg [7:0] dmem [0:1023];
    
    integer i;
    
    // Read operation (combinational) - byte addressed, zero-extended
    assign read_data = mem_read ? {24'b0, dmem[address[9:0]]} : 32'b0;
    
    // Write operation (sequential) - byte store
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            // Initialize all memory to zero
            for (i = 0; i < 1024; i = i + 1)
                dmem[i] <= 8'b0;
            
            // Initialize DMEM[0] = 9, DMEM[1] = 1
            dmem[0] <= 8'd9;
            dmem[1] <= 8'd1;
        end
        else if (mem_write) begin
            // Write byte to memory
            dmem[address[9:0]] <= write_data[7:0];
        end
    end

endmodule

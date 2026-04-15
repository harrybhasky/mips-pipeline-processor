// Instruction Memory Module
// Stores instructions and provides instruction based on PC address

module instruction_memory (
    input wire clk,
    input wire reset,
    input wire [31:0] pc,
    output reg [31:0] instruction
);

    // Instruction memory - 256 words
    reg [31:0] imem [0:255];
    
    integer i;
    
    // Read instruction (word-aligned)
    always @(*) begin
        instruction = imem[pc[9:2]];
    end
    
    // Initialize instruction memory on reset
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            // Initialize all to NOP (zeros)
            for (i = 0; i < 256; i = i + 1)
                imem[i] = 32'b0;
            
            // lw r1, 0(r0)
            imem[0] = 32'b10001100000000010000000000000000;
            // lw r2, 1(r0)
            imem[1] = 32'b10001100000000100000000000000001;
            // mul r1, r1, r2
            imem[2] = 32'b00000000001000100000100000011000;
            // j L (L is at address 20)
            imem[3] = 32'b00001000000000000000000000000101;
            // mul r2, r1, r2 (skipped)
            imem[4] = 32'b00000000001000100001000000011000;
            // L: addi r4, r1, 3
            imem[5] = 32'b00000100001001000000000011000010;
            // sw r4, 4(r0)
            imem[6] = 32'b10101100000001000000000000000100;
        end
    end

endmodule

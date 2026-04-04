// Instruction Fetch Unit
// Fetches instruction from instruction memory and updates PC

module instruction_fetch (
    input wire clk,
    input wire reset,
    input wire stall,
    input wire jump,
    input wire [31:0] jump_address,
    output reg [31:0] pc,
    output reg [31:0] pc_plus_4,
    output wire [31:0] instruction
);

    // Internal PC register
    reg [31:0] pc_reg;
    
    // Instruction memory instance
    instruction_memory imem (
        .clk(clk),
        .reset(reset),
        .pc(pc_reg),
        .instruction(instruction)
    );
    
    // PC update logic
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            pc_reg <= 32'b0;
        end
        else if (!stall) begin
            if (jump) begin
                pc_reg <= jump_address;
            end
            else begin
                pc_reg <= pc_reg + 4;
            end
        end
    end
    
    // Output current PC and PC+4
    always @(*) begin
        pc = pc_reg;
        pc_plus_4 = pc_reg + 4;
    end

endmodule

// Forwarding Unit
// Detects data hazards and controls forwarding paths

module forwarding_unit (
    // Source registers from ID/MUL stage
    input wire [4:0] id_mul_rs,
    input wire [4:0] id_mul_rt,
    
    // Source registers from MUL/ADD stage
    input wire [4:0] mul_add_rs,
    input wire [4:0] mul_add_rt,
    
    // Destination registers from later stages
    input wire [4:0] add_mem_rd,
    input wire [4:0] mem_wb_rd,
    
    // RegWrite signals from later stages
    input wire add_mem_reg_write,
    input wire mem_wb_reg_write,
    
    // Forwarding control signals for MUL stage
    output reg [1:0] forward_a_mul,  // 00: no forward, 01: from ADD/MEM, 10: from MEM/WB
    output reg [1:0] forward_b_mul,
    
    // Forwarding control signals for ADD stage
    output reg [1:0] forward_a_add,
    output reg [1:0] forward_b_add
);

    // Forwarding logic for MUL stage (from ADD/MEM and MEM/WB)
    always @(*) begin
        // Forward A for MUL stage
        if (add_mem_reg_write && (add_mem_rd != 5'b0) && (add_mem_rd == id_mul_rs)) begin
            forward_a_mul = 2'b01;  // Forward from ADD/MEM
        end
        else if (mem_wb_reg_write && (mem_wb_rd != 5'b0) && (mem_wb_rd == id_mul_rs)) begin
            forward_a_mul = 2'b10;  // Forward from MEM/WB
        end
        else begin
            forward_a_mul = 2'b00;  // No forwarding
        end
        
        // Forward B for MUL stage
        if (add_mem_reg_write && (add_mem_rd != 5'b0) && (add_mem_rd == id_mul_rt)) begin
            forward_b_mul = 2'b01;  // Forward from ADD/MEM
        end
        else if (mem_wb_reg_write && (mem_wb_rd != 5'b0) && (mem_wb_rd == id_mul_rt)) begin
            forward_b_mul = 2'b10;  // Forward from MEM/WB
        end
        else begin
            forward_b_mul = 2'b00;  // No forwarding
        end
    end
    
    // Forwarding logic for ADD stage (from ADD/MEM and MEM/WB)
    always @(*) begin
        // Forward A for ADD stage
        if (add_mem_reg_write && (add_mem_rd != 5'b0) && (add_mem_rd == mul_add_rs)) begin
            forward_a_add = 2'b01;  // Forward from ADD/MEM
        end
        else if (mem_wb_reg_write && (mem_wb_rd != 5'b0) && (mem_wb_rd == mul_add_rs)) begin
            forward_a_add = 2'b10;  // Forward from MEM/WB
        end
        else begin
            forward_a_add = 2'b00;  // No forwarding
        end
        
        // Forward B for ADD stage
        if (add_mem_reg_write && (add_mem_rd != 5'b0) && (add_mem_rd == mul_add_rt)) begin
            forward_b_add = 2'b01;  // Forward from ADD/MEM
        end
        else if (mem_wb_reg_write && (mem_wb_rd != 5'b0) && (mem_wb_rd == mul_add_rt)) begin
            forward_b_add = 2'b10;  // Forward from MEM/WB
        end
        else begin
            forward_b_add = 2'b00;  // No forwarding
        end
    end

endmodule

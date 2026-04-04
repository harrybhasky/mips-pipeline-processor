// Hazard Detection Unit
// Detects load-use hazards and generates stall signal

module hazard_detection_unit (
    // Current instruction in IF/ID
    input wire [4:0] if_id_rs,
    input wire [4:0] if_id_rt,
    
    // Instruction in ID/MUL stage
    input wire [4:0] id_mul_rd,
    input wire id_mul_mem_read,
    
    // Instruction in MUL/ADD stage
    input wire [4:0] mul_add_rd,
    input wire mul_add_mem_read,
    
    // Instruction in ADD/MEM stage
    input wire [4:0] add_mem_rd,
    input wire add_mem_mem_read,
    
    // Output stall signal
    output wire stall
);

    // Detect load-use hazard
    // Stall if a load instruction's destination is used by the next instruction
    wire hazard_id_mul = id_mul_mem_read && 
                         ((id_mul_rd == if_id_rs) || (id_mul_rd == if_id_rt)) &&
                         (id_mul_rd != 5'b0);
                         
    wire hazard_mul_add = mul_add_mem_read && 
                          ((mul_add_rd == if_id_rs) || (mul_add_rd == if_id_rt)) &&
                          (mul_add_rd != 5'b0);
                          
    wire hazard_add_mem = add_mem_mem_read && 
                          ((add_mem_rd == if_id_rs) || (add_mem_rd == if_id_rt)) &&
                          (add_mem_rd != 5'b0);
    
    assign stall = hazard_id_mul || hazard_mul_add || hazard_add_mem;

endmodule

// Instruction Decode Unit
// Decodes instruction and generates control signals

module instruction_decode (
    input wire [31:0] instruction,
    output wire [5:0] opcode,
    output wire [4:0] rs,
    output wire [4:0] rt,
    output wire [4:0] rd,
    output wire [4:0] shamt,
    output wire [5:0] funct,
    output wire [15:0] immediate,
    output wire [25:0] address,
    output wire [31:0] sign_extended_imm,
    output wire [31:0] zero_extended_imm,
    output wire reg_write,
    output wire mem_read,
    output wire mem_write,
    output wire mem_to_reg,
    output wire alu_src,
    output wire is_jump,
    output wire is_mul,
    output wire is_addi,
    output wire is_lw,
    output wire is_sw,
    output wire [4:0] write_reg
);

    // Extract instruction fields
    assign opcode = instruction[31:26];
    assign rs = instruction[25:21];
    assign rt = instruction[20:16];
    assign rd = instruction[15:11];
    assign shamt = instruction[10:6];
    assign funct = instruction[5:0];
    assign immediate = instruction[15:0];
    assign address = instruction[25:0];
    
    // Sign extend immediate for lw/sw
    assign sign_extended_imm = {{16{immediate[15]}}, immediate};
    
    // Zero extend and process for addi (10-bit immediate, shift right)
    wire [9:0] addi_imm = instruction[15:6];
    assign zero_extended_imm = {22'b0, addi_imm};
    
    // Instruction type detection
    assign is_lw = (opcode == 6'b100011);
    assign is_sw = (opcode == 6'b101011);
    assign is_jump = (opcode == 6'b000010);
    assign is_mul = (opcode == 6'b000000) && (funct == 6'b011000);
    assign is_addi = (opcode == 6'b000001) && (funct == 6'b000010);
    
    // Control signals
    assign reg_write = is_lw | is_mul | is_addi;
    assign mem_read = is_lw;
    assign mem_write = is_sw;
    assign mem_to_reg = is_lw;
    assign alu_src = is_lw | is_sw | is_addi;
    
    // Determine destination register
    // For R-type (mul): rd
    // For I-type (lw, addi): rt
    assign write_reg = is_mul ? rd : rt;

endmodule

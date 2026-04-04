// 6-Stage MIPS Pipelined Processor
// Stages: IF, ID, MUL, ADD, MEM, WB
// Supports: lw, sw, j, mul, addi
// Pipeline Registers: IF/ID, ID/MUL, MUL/ADD, ADD/MEM, MEM/WB

module mips_processor (
    input wire clk,
    input wire reset
);

    //=========================================================================
    // WIRE DECLARATIONS
    //=========================================================================
    
    // IF Stage signals
    wire [31:0] pc;
    wire [31:0] pc_plus_4;
    wire [31:0] if_instruction;
    wire stall;
    wire jump;
    wire flush;
    wire [31:0] jump_address;
    
    // ID Stage signals (decoded from IF/ID register)
    wire [5:0] id_opcode;
    wire [4:0] id_rs, id_rt, id_rd;
    wire [4:0] id_shamt;
    wire [5:0] id_funct;
    wire [15:0] id_immediate;
    wire [25:0] id_address;
    wire [31:0] id_sign_ext_imm, id_zero_ext_imm;
    wire id_reg_write, id_mem_read, id_mem_write, id_mem_to_reg, id_alu_src;
    wire id_is_jump, id_is_mul, id_is_addi, id_is_lw, id_is_sw;
    wire [4:0] id_write_reg;
    wire [31:0] id_read_data1, id_read_data2;
    
    // Forwarding signals
    wire [1:0] forward_a_mul, forward_b_mul;
    wire [1:0] forward_a_add, forward_b_add;
    
    // MUL stage operands after forwarding
    reg [31:0] mul_operand_a, mul_operand_b;
    wire [31:0] mul_result;
    
    // ADD stage operands after forwarding
    reg [31:0] add_operand_a, add_operand_b;
    wire [31:0] add_result;
    
    // WB Stage signals
    wire [31:0] wb_data;
    
    //=========================================================================
    // PIPELINE REGISTERS
    //=========================================================================
    
    // IF/ID Pipeline Register
    reg [31:0] if_id_pc;
    reg [31:0] if_id_pc_plus_4;
    reg [31:0] if_id_instruction;
    
    // ID/MUL Pipeline Register
    reg [31:0] id_mul_pc;
    reg [31:0] id_mul_read_data1;
    reg [31:0] id_mul_read_data2;
    reg [31:0] id_mul_sign_ext_imm;
    reg [31:0] id_mul_zero_ext_imm;
    reg [4:0] id_mul_rs;
    reg [4:0] id_mul_rt;
    reg [4:0] id_mul_rd;
    reg [4:0] id_mul_write_reg;
    reg id_mul_reg_write;
    reg id_mul_mem_read;
    reg id_mul_mem_write;
    reg id_mul_mem_to_reg;
    reg id_mul_alu_src;
    reg id_mul_is_mul;
    reg id_mul_is_addi;
    reg id_mul_is_lw;
    reg id_mul_is_sw;
    
    // MUL/ADD Pipeline Register
    reg [31:0] mul_add_pc;
    reg [31:0] mul_add_mul_result;  // Result from multiplication
    reg [31:0] mul_add_read_data1;  // Operand A for ADD stage
    reg [31:0] mul_add_read_data2;  // Operand B or store data
    reg [31:0] mul_add_sign_ext_imm;
    reg [31:0] mul_add_zero_ext_imm;
    reg [4:0] mul_add_rs;
    reg [4:0] mul_add_rt;
    reg [4:0] mul_add_write_reg;
    reg mul_add_reg_write;
    reg mul_add_mem_read;
    reg mul_add_mem_write;
    reg mul_add_mem_to_reg;
    reg mul_add_alu_src;
    reg mul_add_is_mul;
    reg mul_add_is_addi;
    reg mul_add_is_lw;
    reg mul_add_is_sw;
    
    // ADD/MEM Pipeline Register
    reg [31:0] add_mem_alu_result;
    reg [31:0] add_mem_read_data2;
    reg [4:0] add_mem_write_reg;
    reg add_mem_reg_write;
    reg add_mem_mem_read;
    reg add_mem_mem_write;
    reg add_mem_mem_to_reg;
    reg add_mem_is_mul;
    
    // MEM/WB Pipeline Register
    reg [31:0] mem_wb_mem_data;
    reg [31:0] mem_wb_alu_result;
    reg [4:0] mem_wb_write_reg;
    reg mem_wb_reg_write;
    reg mem_wb_mem_to_reg;
    
    //=========================================================================
    // INSTRUCTION MEMORY (initialized on reset)
    //=========================================================================
    
    reg [31:0] imem [0:255];
    reg [31:0] pc_reg;
    
    // Instruction fetch
    assign if_instruction = imem[pc_reg[9:2]];
    assign pc = pc_reg;
    assign pc_plus_4 = pc_reg + 4;
    
    //=========================================================================
    // DATA MEMORY
    //=========================================================================
    
    reg [7:0] dmem [0:1023];
    wire [31:0] mem_read_data;
    
    // Read data from memory - byte addressed, zero-extended
    assign mem_read_data = {24'b0, dmem[add_mem_alu_result[9:0]]};
    
    //=========================================================================
    // REGISTER FILE
    //=========================================================================
    
    reg [31:0] registers [0:31];
    
    // Read from register file with forwarding from WB stage
    // This handles the case where WB is writing to a register that ID needs to read
    wire [31:0] id_read_data1_raw = (id_rs == 5'b0) ? 32'b0 : registers[id_rs];
    wire [31:0] id_read_data2_raw = (id_rt == 5'b0) ? 32'b0 : registers[id_rt];
    
    // Forward from WB to ID if WB is writing to the same register ID wants to read
    assign id_read_data1 = (mem_wb_reg_write && mem_wb_write_reg != 5'b0 && mem_wb_write_reg == id_rs) 
                           ? wb_data : id_read_data1_raw;
    assign id_read_data2 = (mem_wb_reg_write && mem_wb_write_reg != 5'b0 && mem_wb_write_reg == id_rt) 
                           ? wb_data : id_read_data2_raw;
    
    //=========================================================================
    // INSTRUCTION DECODE
    //=========================================================================
    
    assign id_opcode = if_id_instruction[31:26];
    assign id_rs = if_id_instruction[25:21];
    assign id_rt = if_id_instruction[20:16];
    assign id_rd = if_id_instruction[15:11];
    assign id_shamt = if_id_instruction[10:6];
    assign id_funct = if_id_instruction[5:0];
    assign id_immediate = if_id_instruction[15:0];
    assign id_address = if_id_instruction[25:0];
    
    // Sign/zero extend
    assign id_sign_ext_imm = {{16{id_immediate[15]}}, id_immediate};
    assign id_zero_ext_imm = {22'b0, if_id_instruction[15:6]};  // 10-bit for addi
    
    // Instruction type detection
    assign id_is_lw = (id_opcode == 6'b100011);
    assign id_is_sw = (id_opcode == 6'b101011);
    assign id_is_jump = (id_opcode == 6'b000010);
    assign id_is_mul = (id_opcode == 6'b000000) && (id_funct == 6'b011000);
    assign id_is_addi = (id_opcode == 6'b000001) && (id_funct == 6'b000010);
    
    // Control signals
    assign id_reg_write = id_is_lw | id_is_mul | id_is_addi;
    assign id_mem_read = id_is_lw;
    assign id_mem_write = id_is_sw;
    assign id_mem_to_reg = id_is_lw;
    assign id_alu_src = id_is_lw | id_is_sw | id_is_addi;
    
    // Destination register selection
    assign id_write_reg = id_is_mul ? id_rd : id_rt;
    
    // Jump control - detected in ID stage
    assign jump = id_is_jump;
    assign jump_address = {if_id_pc_plus_4[31:28], id_address, 2'b00};
    assign flush = jump;  // Flush the instruction fetched after jump
    
    //=========================================================================
    // HAZARD DETECTION UNIT
    //=========================================================================
    
    // Load-use hazard detection - check if instruction in ID/MUL or MUL/ADD
    // is a load and the current instruction uses that register
    wire hazard_id_mul = id_mul_mem_read && 
                         (id_mul_write_reg != 5'b0) &&
                         ((id_mul_write_reg == id_rs) || (id_mul_write_reg == id_rt));
    
    wire hazard_mul_add = mul_add_mem_read && 
                          (mul_add_write_reg != 5'b0) &&
                          ((mul_add_write_reg == id_rs) || (mul_add_write_reg == id_rt));
    
    assign stall = hazard_id_mul || hazard_mul_add;
    
    //=========================================================================
    // FORWARDING UNIT
    //=========================================================================
    
    forwarding_unit fwd_unit (
        .id_mul_rs(id_mul_rs),
        .id_mul_rt(id_mul_rt),
        .mul_add_rs(mul_add_rs),
        .mul_add_rt(mul_add_rt),
        .add_mem_rd(add_mem_write_reg),
        .mem_wb_rd(mem_wb_write_reg),
        .add_mem_reg_write(add_mem_reg_write),
        .mem_wb_reg_write(mem_wb_reg_write),
        .forward_a_mul(forward_a_mul),
        .forward_b_mul(forward_b_mul),
        .forward_a_add(forward_a_add),
        .forward_b_add(forward_b_add)
    );
    
    //=========================================================================
    // MUL STAGE - Multiplication
    //=========================================================================
    
    // Forwarding mux for MUL stage operand A
    always @(*) begin
        case (forward_a_mul)
            2'b01: mul_operand_a = add_mem_alu_result;  // Forward from ADD/MEM
            2'b10: mul_operand_a = wb_data;              // Forward from MEM/WB
            default: mul_operand_a = id_mul_read_data1;  // No forwarding
        endcase
    end
    
    // Forwarding mux for MUL stage operand B
    always @(*) begin
        case (forward_b_mul)
            2'b01: mul_operand_b = add_mem_alu_result;  // Forward from ADD/MEM
            2'b10: mul_operand_b = wb_data;              // Forward from MEM/WB
            default: mul_operand_b = id_mul_read_data2;  // No forwarding
        endcase
    end
    
    // Multiplication result (for mul instruction)
    assign mul_result = mul_operand_a * mul_operand_b;
    
    //=========================================================================
    // ADD STAGE - Addition (for lw/sw address calculation, addi)
    //=========================================================================
    
    // Forwarding mux for ADD stage operand A
    always @(*) begin
        case (forward_a_add)
            2'b01: add_operand_a = add_mem_alu_result;   // Forward from ADD/MEM
            2'b10: add_operand_a = wb_data;               // Forward from MEM/WB
            default: add_operand_a = mul_add_read_data1;  // From MUL/ADD register
        endcase
    end
    
    // ADD stage operand B selection
    always @(*) begin
        if (mul_add_is_lw || mul_add_is_sw) begin
            add_operand_b = mul_add_sign_ext_imm;  // Immediate for lw/sw
        end
        else if (mul_add_is_addi) begin
            add_operand_b = mul_add_zero_ext_imm;  // Zero-extended for addi
        end
        else begin
            add_operand_b = 32'b0;
        end
    end
    
    // Addition result
    assign add_result = add_operand_a + add_operand_b;
    
    //=========================================================================
    // WRITEBACK DATA MUX
    //=========================================================================
    
    assign wb_data = mem_wb_mem_to_reg ? mem_wb_mem_data : mem_wb_alu_result;
    
    //=========================================================================
    // MAIN SEQUENTIAL LOGIC
    //=========================================================================
    
    integer i;
    
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            //=================================================================
            // RESET: Initialize all pipeline registers and memories
            //=================================================================
            
            // Initialize PC
            pc_reg <= 32'b0;
            
            // Initialize IF/ID register
            if_id_pc <= 32'b0;
            if_id_pc_plus_4 <= 32'b0;
            if_id_instruction <= 32'b0;
            
            // Initialize ID/MUL register
            id_mul_pc <= 32'b0;
            id_mul_read_data1 <= 32'b0;
            id_mul_read_data2 <= 32'b0;
            id_mul_sign_ext_imm <= 32'b0;
            id_mul_zero_ext_imm <= 32'b0;
            id_mul_rs <= 5'b0;
            id_mul_rt <= 5'b0;
            id_mul_rd <= 5'b0;
            id_mul_write_reg <= 5'b0;
            id_mul_reg_write <= 1'b0;
            id_mul_mem_read <= 1'b0;
            id_mul_mem_write <= 1'b0;
            id_mul_mem_to_reg <= 1'b0;
            id_mul_alu_src <= 1'b0;
            id_mul_is_mul <= 1'b0;
            id_mul_is_addi <= 1'b0;
            id_mul_is_lw <= 1'b0;
            id_mul_is_sw <= 1'b0;
            
            // Initialize MUL/ADD register
            mul_add_pc <= 32'b0;
            mul_add_mul_result <= 32'b0;
            mul_add_read_data1 <= 32'b0;
            mul_add_read_data2 <= 32'b0;
            mul_add_sign_ext_imm <= 32'b0;
            mul_add_zero_ext_imm <= 32'b0;
            mul_add_rs <= 5'b0;
            mul_add_rt <= 5'b0;
            mul_add_write_reg <= 5'b0;
            mul_add_reg_write <= 1'b0;
            mul_add_mem_read <= 1'b0;
            mul_add_mem_write <= 1'b0;
            mul_add_mem_to_reg <= 1'b0;
            mul_add_alu_src <= 1'b0;
            mul_add_is_mul <= 1'b0;
            mul_add_is_addi <= 1'b0;
            mul_add_is_lw <= 1'b0;
            mul_add_is_sw <= 1'b0;
            
            // Initialize ADD/MEM register
            add_mem_alu_result <= 32'b0;
            add_mem_read_data2 <= 32'b0;
            add_mem_write_reg <= 5'b0;
            add_mem_reg_write <= 1'b0;
            add_mem_mem_read <= 1'b0;
            add_mem_mem_write <= 1'b0;
            add_mem_mem_to_reg <= 1'b0;
            add_mem_is_mul <= 1'b0;
            
            // Initialize MEM/WB register
            mem_wb_mem_data <= 32'b0;
            mem_wb_alu_result <= 32'b0;
            mem_wb_write_reg <= 5'b0;
            mem_wb_reg_write <= 1'b0;
            mem_wb_mem_to_reg <= 1'b0;
            
            // Initialize register file (all zeros)
            for (i = 0; i < 32; i = i + 1)
                registers[i] <= 32'b0;
            
            // Initialize instruction memory
            for (i = 0; i < 256; i = i + 1)
                imem[i] <= 32'b0;
            
            // Load program into instruction memory
            // PC addresses are byte-addressed but word-aligned
            // imem index = PC / 4
            
            // Address 0: lw r1, 0(r0)
            imem[0] <= 32'b10001100000000010000000000000000;
            // Address 4: lw r2, 1(r0)
            imem[1] <= 32'b10001100000000100000000000000001;
            // Address 8: mul r1, r1, r2
            imem[2] <= 32'b00000000001000100000100000011000;
            // Address 12: j L (L is at address 20, so address field = 20/4 = 5)
            // Jump address = PC[31:28] | (address << 2) = 0 | (5 << 2) = 20
            imem[3] <= 32'b00001000000000000000000000000101;
            // Address 16: mul r2, r1, r2 (skipped due to jump)
            imem[4] <= 32'b00000000001000100001000000011000;
            // Address 20 (L): addi r4, r1, 3
            imem[5] <= 32'b00000100001001000000000011000010;
            // Address 24: sw r4, 4(r0)
            imem[6] <= 32'b10101100000001000000000000000100;
            
            // Initialize data memory (all zeros first)
            for (i = 0; i < 1024; i = i + 1)
                dmem[i] <= 8'b0;
            
            // DMEM[0] = 9, DMEM[1] = 1
            dmem[0] <= 8'd9;
            dmem[1] <= 8'd1;
        end
        else begin
            //=================================================================
            // NORMAL OPERATION
            //=================================================================
            
            //-------------------------------------------------------------
            // WB Stage: Write back to register file
            //-------------------------------------------------------------
            if (mem_wb_reg_write && mem_wb_write_reg != 5'b0) begin
                registers[mem_wb_write_reg] <= wb_data;
            end
            
            //-------------------------------------------------------------
            // MEM Stage: Memory access
            //-------------------------------------------------------------
            // Memory write for sw instruction
            // Need to forward store data if there's a RAW hazard
            if (add_mem_mem_write) begin
                // Check if store data needs forwarding from WB stage
                if (mem_wb_reg_write && mem_wb_write_reg != 5'b0 && 
                    mem_wb_write_reg == add_mem_write_reg) begin
                    // Forward from WB
                    dmem[add_mem_alu_result[9:0]] <= wb_data[7:0];
                end
                else begin
                    dmem[add_mem_alu_result[9:0]] <= add_mem_read_data2[7:0];
                end
            end
            
            // MEM/WB Pipeline Register Update
            mem_wb_mem_data <= mem_read_data;
            mem_wb_alu_result <= add_mem_alu_result;
            mem_wb_write_reg <= add_mem_write_reg;
            mem_wb_reg_write <= add_mem_reg_write;
            mem_wb_mem_to_reg <= add_mem_mem_to_reg;
            
            //-------------------------------------------------------------
            // ADD/MEM Pipeline Register Update
            //-------------------------------------------------------------
            // For mul: bypass ADD stage (use multiplication result)
            // For lw/sw: use addition result (address calculation)
            // For addi: use addition result
            if (mul_add_is_mul) begin
                add_mem_alu_result <= mul_add_mul_result;  // Bypass addition for mul
            end
            else begin
                add_mem_alu_result <= add_result;          // Normal addition
            end
            add_mem_read_data2 <= mul_add_read_data2;
            add_mem_write_reg <= mul_add_write_reg;
            add_mem_reg_write <= mul_add_reg_write;
            add_mem_mem_read <= mul_add_mem_read;
            add_mem_mem_write <= mul_add_mem_write;
            add_mem_mem_to_reg <= mul_add_mem_to_reg;
            add_mem_is_mul <= mul_add_is_mul;
            
            //-------------------------------------------------------------
            // MUL/ADD Pipeline Register Update
            //-------------------------------------------------------------
            // For addi: bypass MUL stage
            // For mul: perform multiplication
            if (id_mul_is_addi) begin
                // ADDI bypasses multiplication
                mul_add_mul_result <= 32'b0;
                mul_add_read_data1 <= mul_operand_a;  // Pass operand for addition
            end
            else if (id_mul_is_mul) begin
                mul_add_mul_result <= mul_result;     // Store multiplication result
                mul_add_read_data1 <= 32'b0;
            end
            else begin
                // For lw/sw: pass through operand A for address calculation
                mul_add_mul_result <= 32'b0;
                mul_add_read_data1 <= mul_operand_a;
            end
            mul_add_read_data2 <= mul_operand_b;
            mul_add_sign_ext_imm <= id_mul_sign_ext_imm;
            mul_add_zero_ext_imm <= id_mul_zero_ext_imm;
            mul_add_rs <= id_mul_rs;
            mul_add_rt <= id_mul_rt;
            mul_add_write_reg <= id_mul_write_reg;
            mul_add_reg_write <= id_mul_reg_write;
            mul_add_mem_read <= id_mul_mem_read;
            mul_add_mem_write <= id_mul_mem_write;
            mul_add_mem_to_reg <= id_mul_mem_to_reg;
            mul_add_alu_src <= id_mul_alu_src;
            mul_add_is_mul <= id_mul_is_mul;
            mul_add_is_addi <= id_mul_is_addi;
            mul_add_is_lw <= id_mul_is_lw;
            mul_add_is_sw <= id_mul_is_sw;
            
            //-------------------------------------------------------------
            // ID/MUL Pipeline Register Update
            //-------------------------------------------------------------
            if (stall || flush) begin
                // Insert bubble (NOP) on stall or flush
                id_mul_reg_write <= 1'b0;
                id_mul_mem_read <= 1'b0;
                id_mul_mem_write <= 1'b0;
                id_mul_mem_to_reg <= 1'b0;
                id_mul_is_mul <= 1'b0;
                id_mul_is_addi <= 1'b0;
                id_mul_is_lw <= 1'b0;
                id_mul_is_sw <= 1'b0;
                id_mul_write_reg <= 5'b0;
            end
            else begin
                id_mul_pc <= if_id_pc;
                id_mul_read_data1 <= id_read_data1;
                id_mul_read_data2 <= id_read_data2;
                id_mul_sign_ext_imm <= id_sign_ext_imm;
                id_mul_zero_ext_imm <= id_zero_ext_imm;
                id_mul_rs <= id_rs;
                id_mul_rt <= id_rt;
                id_mul_rd <= id_rd;
                id_mul_write_reg <= id_write_reg;
                id_mul_reg_write <= id_reg_write;
                id_mul_mem_read <= id_mem_read;
                id_mul_mem_write <= id_mem_write;
                id_mul_mem_to_reg <= id_mem_to_reg;
                id_mul_alu_src <= id_alu_src;
                id_mul_is_mul <= id_is_mul;
                id_mul_is_addi <= id_is_addi;
                id_mul_is_lw <= id_is_lw;
                id_mul_is_sw <= id_is_sw;
            end
            
            //-------------------------------------------------------------
            // IF/ID Pipeline Register Update
            //-------------------------------------------------------------
            if (!stall) begin
                if (flush) begin
                    // Flush instruction on jump (insert bubble)
                    if_id_instruction <= 32'b0;
                    if_id_pc <= 32'b0;
                    if_id_pc_plus_4 <= 32'b0;
                end
                else begin
                    if_id_pc <= pc;
                    if_id_pc_plus_4 <= pc_plus_4;
                    if_id_instruction <= if_instruction;
                end
            end
            
            //-------------------------------------------------------------
            // PC Update
            //-------------------------------------------------------------
            if (!stall) begin
                if (jump) begin
                    pc_reg <= jump_address;
                end
                else begin
                    pc_reg <= pc_reg + 4;
                end
            end
        end
    end

endmodule

// 6-Stage MIPS Pipelined Processor
// Stages: IF, ID, MUL, ADD, MEM, WB
// Supports: lw, sw, j, mul, addi

module mips_processor (
    input wire clk,
    input wire reset
);

    //=========================================================================
    // IF STAGE WIRES
    //=========================================================================
    wire [31:0] if_pc;
    wire [31:0] if_pc_plus_4;
    wire [31:0] if_instruction;
    wire stall;
    wire jump;
    wire flush;
    wire [31:0] jump_address;

    //=========================================================================
    // ID STAGE WIRES
    //=========================================================================
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

    wire [31:0] rf_read_data1, rf_read_data2;
    wire [31:0] id_read_data1, id_read_data2;

    //=========================================================================
    // FORWARDING WIRES
    //=========================================================================
    wire [1:0] forward_a_mul, forward_b_mul;
    wire [1:0] forward_a_add, forward_b_add;

    reg [31:0] mul_operand_a, mul_operand_b;
    reg [31:0] add_operand_a, add_operand_b;
    reg [31:0] add_store_data;

    wire [31:0] mul_result;
    wire [31:0] add_result;
    wire [31:0] mem_read_data;
    wire [31:0] wb_data;

    //=========================================================================
    // PIPELINE REGISTERS
    //=========================================================================
    // IF/ID
    reg [31:0] if_id_pc;
    reg [31:0] if_id_pc_plus_4;
    reg [31:0] if_id_instruction;

    // ID/MUL
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

    // MUL/ADD
    reg [31:0] mul_add_mul_result;
    reg [31:0] mul_add_read_data1;
    reg [31:0] mul_add_read_data2;
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

    // ADD/MEM
    reg [31:0] add_mem_alu_result;
    reg [31:0] add_mem_read_data2;
    reg [4:0] add_mem_write_reg;
    reg add_mem_reg_write;
    reg add_mem_mem_read;
    reg add_mem_mem_write;
    reg add_mem_mem_to_reg;
    reg add_mem_is_mul;

    // MEM/WB
    reg [31:0] mem_wb_mem_data;
    reg [31:0] mem_wb_alu_result;
    reg [4:0] mem_wb_write_reg;
    reg mem_wb_reg_write;
    reg mem_wb_mem_to_reg;

    //=========================================================================
    // MODULE INSTANTIATION
    //=========================================================================
    instruction_fetch fetch (
        .clk(clk),
        .reset(reset),
        .stall(stall),
        .jump(jump),
        .jump_address(jump_address),
        .pc(if_pc),
        .pc_plus_4(if_pc_plus_4),
        .instruction(if_instruction)
    );

    instruction_decode decode (
        .instruction(if_id_instruction),
        .opcode(id_opcode),
        .rs(id_rs),
        .rt(id_rt),
        .rd(id_rd),
        .shamt(id_shamt),
        .funct(id_funct),
        .immediate(id_immediate),
        .address(id_address),
        .sign_extended_imm(id_sign_ext_imm),
        .zero_extended_imm(id_zero_ext_imm),
        .reg_write(id_reg_write),
        .mem_read(id_mem_read),
        .mem_write(id_mem_write),
        .mem_to_reg(id_mem_to_reg),
        .alu_src(id_alu_src),
        .is_jump(id_is_jump),
        .is_mul(id_is_mul),
        .is_addi(id_is_addi),
        .is_lw(id_is_lw),
        .is_sw(id_is_sw),
        .write_reg(id_write_reg)
    );

    register_file rf (
        .clk(clk),
        .reset(reset),
        .reg_write(mem_wb_reg_write),
        .read_reg1(id_rs),
        .read_reg2(id_rt),
        .write_reg(mem_wb_write_reg),
        .write_data(wb_data),
        .read_data1(rf_read_data1),
        .read_data2(rf_read_data2)
    );

    hazard_detection_unit hazard (
        .if_id_rs(id_rs),
        .if_id_rt(id_rt),
        .id_mul_rd(id_mul_write_reg),
        .id_mul_mem_read(id_mul_mem_read),
        .mul_add_rd(mul_add_write_reg),
        .mul_add_mem_read(mul_add_mem_read),
        .add_mem_rd(add_mem_write_reg),
        .add_mem_mem_read(add_mem_mem_read),
        .stall(stall)
    );

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

    wire [31:0] mem_write_data =
        (mem_wb_reg_write && (mem_wb_write_reg != 5'b0) && (mem_wb_write_reg == add_mem_write_reg))
            ? wb_data
            : add_mem_read_data2;

    data_memory dmem_inst (
        .clk(clk),
        .reset(reset),
        .mem_read(add_mem_mem_read),
        .mem_write(add_mem_mem_write),
        .address(add_mem_alu_result),
        .write_data(mem_write_data),
        .read_data(mem_read_data)
    );

    //=========================================================================
    // CONTROL / MUX LOGIC
    //=========================================================================
    assign jump = id_is_jump;
    assign jump_address = {if_id_pc_plus_4[31:28], id_address, 2'b00};
    assign flush = jump;

    // Forward WB value directly to ID reads for same-cycle dependency.
    assign id_read_data1 =
        (mem_wb_reg_write && (mem_wb_write_reg != 5'b0) && (mem_wb_write_reg == id_rs))
            ? wb_data
            : rf_read_data1;

    assign id_read_data2 =
        (mem_wb_reg_write && (mem_wb_write_reg != 5'b0) && (mem_wb_write_reg == id_rt))
            ? wb_data
            : rf_read_data2;

    // MUL stage operand forwarding
    always @(*) begin
        case (forward_a_mul)
            2'b01: mul_operand_a = add_mem_alu_result;
            2'b10: mul_operand_a = wb_data;
            default: mul_operand_a = id_mul_read_data1;
        endcase
    end

    always @(*) begin
        case (forward_b_mul)
            2'b01: mul_operand_b = add_mem_alu_result;
            2'b10: mul_operand_b = wb_data;
            default: mul_operand_b = id_mul_read_data2;
        endcase
    end

    assign mul_result = mul_operand_a * mul_operand_b;

    // ADD stage forwarding and operand selection
    always @(*) begin
        case (forward_a_add)
            2'b01: add_operand_a = add_mem_alu_result;
            2'b10: add_operand_a = wb_data;
            default: add_operand_a = mul_add_read_data1;
        endcase
    end

    always @(*) begin
        if (mul_add_is_lw || mul_add_is_sw) begin
            add_operand_b = mul_add_sign_ext_imm;
        end
        else if (mul_add_is_addi) begin
            add_operand_b = mul_add_zero_ext_imm;
        end
        else begin
            add_operand_b = 32'b0;
        end
    end

    always @(*) begin
        case (forward_b_add)
            2'b01: add_store_data = add_mem_alu_result;
            2'b10: add_store_data = wb_data;
            default: add_store_data = mul_add_read_data2;
        endcase
    end

    assign add_result = add_operand_a + add_operand_b;
    assign wb_data = mem_wb_mem_to_reg ? mem_wb_mem_data : mem_wb_alu_result;

    //=========================================================================
    // SEQUENTIAL PIPELINE UPDATES
    //=========================================================================
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            if_id_pc <= 32'b0;
            if_id_pc_plus_4 <= 32'b0;
            if_id_instruction <= 32'b0;

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

            add_mem_alu_result <= 32'b0;
            add_mem_read_data2 <= 32'b0;
            add_mem_write_reg <= 5'b0;
            add_mem_reg_write <= 1'b0;
            add_mem_mem_read <= 1'b0;
            add_mem_mem_write <= 1'b0;
            add_mem_mem_to_reg <= 1'b0;
            add_mem_is_mul <= 1'b0;

            mem_wb_mem_data <= 32'b0;
            mem_wb_alu_result <= 32'b0;
            mem_wb_write_reg <= 5'b0;
            mem_wb_reg_write <= 1'b0;
            mem_wb_mem_to_reg <= 1'b0;
        end
        else begin
            // MEM/WB update
            mem_wb_mem_data <= mem_read_data;
            mem_wb_alu_result <= add_mem_alu_result;
            mem_wb_write_reg <= add_mem_write_reg;
            mem_wb_reg_write <= add_mem_reg_write;
            mem_wb_mem_to_reg <= add_mem_mem_to_reg;

            // ADD/MEM update
            if (mul_add_is_mul) begin
                add_mem_alu_result <= mul_add_mul_result;
            end
            else begin
                add_mem_alu_result <= add_result;
            end
            add_mem_read_data2 <= add_store_data;
            add_mem_write_reg <= mul_add_write_reg;
            add_mem_reg_write <= mul_add_reg_write;
            add_mem_mem_read <= mul_add_mem_read;
            add_mem_mem_write <= mul_add_mem_write;
            add_mem_mem_to_reg <= mul_add_mem_to_reg;
            add_mem_is_mul <= mul_add_is_mul;

            // MUL/ADD update
            if (id_mul_is_addi) begin
                mul_add_mul_result <= 32'b0;
                mul_add_read_data1 <= mul_operand_a;
            end
            else if (id_mul_is_mul) begin
                mul_add_mul_result <= mul_result;
                mul_add_read_data1 <= 32'b0;
            end
            else begin
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

            // ID/MUL update
            if (stall || flush) begin
                id_mul_reg_write <= 1'b0;
                id_mul_mem_read <= 1'b0;
                id_mul_mem_write <= 1'b0;
                id_mul_mem_to_reg <= 1'b0;
                id_mul_alu_src <= 1'b0;
                id_mul_is_mul <= 1'b0;
                id_mul_is_addi <= 1'b0;
                id_mul_is_lw <= 1'b0;
                id_mul_is_sw <= 1'b0;
                id_mul_write_reg <= 5'b0;
            end
            else begin
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

            // IF/ID update
            if (!stall) begin
                if (flush) begin
                    if_id_instruction <= 32'b0;
                    if_id_pc <= 32'b0;
                    if_id_pc_plus_4 <= 32'b0;
                end
                else begin
                    if_id_instruction <= if_instruction;
                    if_id_pc <= if_pc;
                    if_id_pc_plus_4 <= if_pc_plus_4;
                end
            end
        end
    end

endmodule

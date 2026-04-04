# 6-Stage MIPS Pipelined Processor

A Verilog implementation of a 6-stage MIPS pipelined processor with forwarding and hazard detection.

## Pipeline Stages
1. **IF** - Instruction Fetch
2. **ID** - Instruction Decode
3. **MUL** - Multiplication Stage
4. **ADD** - Addition Stage
5. **MEM** - Memory Access
6. **WB** - Write Back

## Supported Instructions
- `lw` - Load Word
- `sw` - Store Word
- `j` - Jump
- `mul` - Multiply
- `addi` - Add Immediate

## Features
- 5 Pipeline Registers: IF/ID, ID/MUL, MUL/ADD, ADD/MEM, MEM/WB
- Forwarding unit for data hazard resolution
- Hazard detection with stalling for load-use hazards
- Jump handling with pipeline flush
- Bypass paths (MUL bypassed for addi, ADD bypassed for mul)

## Files
| File | Description |
|------|-------------|
| `mips_processor.v` | Main processor (top module) |
| `mips_processor_tb.v` | Testbench |
| `instruction_memory.v` | Instruction memory |
| `instruction_decode.v` | Instruction decoder |
| `instruction_fetch.v` | Instruction fetch unit |
| `register_file.v` | 32x32-bit register file |
| `data_memory.v` | Byte-addressable data memory |
| `forwarding_unit.v` | Forwarding unit |
| `hazard_detection_unit.v` | Hazard detection |

## Simulation (Icarus Verilog)
```bash
iverilog -o mips_sim mips_processor.v forwarding_unit.v mips_processor_tb.v
vvp mips_sim
```

## Test Program
```assembly
lw r1, 0(r0)      # r1 = 9
lw r2, 1(r0)      # r2 = 1
mul r1, r1, r2    # r1 = 9*1 = 9
j L
mul r2, r1, r2    # skipped
L: addi r4, r1, 3 # r4 = 9+3 = 12
sw r4, 4(r0)      # DMEM[4] = 12
```

## Expected Results
- R1 = 9
- R4 = 12
- DMEM[4] = 12

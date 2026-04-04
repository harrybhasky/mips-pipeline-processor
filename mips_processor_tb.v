// Testbench for 6-Stage MIPS Pipelined Processor
// Tests the processor with the given instruction sequence

`timescale 1ns/1ps

module mips_processor_tb;

    // Testbench signals
    reg clk;
    reg reset;
    
    // Instantiate the processor
    mips_processor uut (
        .clk(clk),
        .reset(reset)
    );
    
    // Clock generation - 10ns period (100MHz)
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end
    
    // Monitoring signals
    initial begin
        $dumpfile("mips_processor.vcd");
        $dumpvars(0, mips_processor_tb);
    end
    
    // Test sequence
    initial begin
        $display("========================================");
        $display("6-Stage MIPS Pipelined Processor Test");
        $display("========================================");
        
        // Apply reset
        reset = 1;
        #20;
        
        $display("\nInitial Memory State:");
        $display("DMEM[0] = %d", uut.dmem[0]);
        $display("DMEM[1] = %d", uut.dmem[1]);
        $display("DMEM[4] = %d", uut.dmem[4]);
        
        // Release reset
        reset = 0;
        $display("\n--- Reset Released ---\n");
        
        // Run for enough cycles to complete all instructions
        repeat (20) begin
            @(posedge clk);
            $display("Cycle: PC=%h", uut.pc_reg);
        end
        
        // Final state check
        $display("\n========================================");
        $display("Final State:");
        $display("========================================");
        
        $display("\nRegister File:");
        $display("R0  = %d (should be 0)", uut.registers[0]);
        $display("R1  = %d (should be 9: 9*1=9)", uut.registers[1]);
        $display("R2  = %d (should be 1)", uut.registers[2]);
        $display("R4  = %d (should be 12: 9+3=12)", uut.registers[4]);
        
        $display("\nData Memory:");
        $display("DMEM[0] = %d (initial: 9)", uut.dmem[0]);
        $display("DMEM[1] = %d (initial: 1)", uut.dmem[1]);
        $display("DMEM[4] = %d (should be 12: R4 stored)", uut.dmem[4]);
        
        // Verify results
        $display("\n========================================");
        $display("Verification:");
        $display("========================================");
        
        if (uut.registers[1] == 32'd9) begin
            $display("PASS: R1 = 9 (correct: 9*1=9)");
        end else begin
            $display("FAIL: R1 = %d (expected 9)", uut.registers[1]);
        end
        
        if (uut.registers[4] == 32'd12) begin
            $display("PASS: R4 = 12 (correct: 9+3=12)");
        end else begin
            $display("FAIL: R4 = %d (expected 12)", uut.registers[4]);
        end
        
        if (uut.dmem[4] == 8'd12) begin
            $display("PASS: DMEM[4] = 12 (correct)");
        end else begin
            $display("FAIL: DMEM[4] = %d (expected 12)", uut.dmem[4]);
        end
        
        $display("\n========================================");
        $display("Test Complete");
        $display("========================================");
        
        #50;
        $finish;
    end
    
    // Timeout watchdog
    initial begin
        #10000;
        $display("ERROR: Simulation timeout!");
        $finish;
    end

endmodule

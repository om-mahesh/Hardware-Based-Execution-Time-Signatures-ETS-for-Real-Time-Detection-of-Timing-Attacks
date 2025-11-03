/**
 * tb_ets_monitor.v
 * 
 * Testbench for ETS monitoring module.
 * Verifies:
 * - Cycle counting
 * - Signature comparison
 * - Anomaly detection
 * - Alert generation
 */

`timescale 1ns/1ps

module tb_ets_monitor;

    // Clock and reset
    reg clk;
    reg rst_n;
    
    // RISC-V core interface
    reg        instr_start;
    reg        instr_active;
    reg        instr_done;
    reg [31:0] instr_pc;
    reg [6:0]  instr_opcode;
    
    // Register interface
    reg        reg_wr_en;
    reg [15:0] reg_addr;
    reg [31:0] reg_wr_data;
    wire [31:0] reg_rd_data;
    
    // Outputs
    wire alert_interrupt;
    wire alert_flag;
    wire [31:0] dbg_cycle_count;
    wire dbg_anomaly_detected;
    
    // DUT instantiation
    ets_monitor uut (
        .clk                 (clk),
        .rst_n               (rst_n),
        .instr_start         (instr_start),
        .instr_active        (instr_active),
        .instr_done          (instr_done),
        .instr_pc            (instr_pc),
        .instr_opcode        (instr_opcode),
        .reg_wr_en           (reg_wr_en),
        .reg_addr            (reg_addr),
        .reg_wr_data         (reg_wr_data),
        .reg_rd_data         (reg_rd_data),
        .alert_interrupt     (alert_interrupt),
        .alert_flag          (alert_flag),
        .dbg_cycle_count     (dbg_cycle_count),
        .dbg_anomaly_detected(dbg_anomaly_detected)
    );
    
    // Clock generation (100 MHz)
    always #5 clk = ~clk;
    
    // Test counter
    integer test_num;
    
    initial begin
        $dumpfile("tb_ets_monitor.vcd");
        $dumpvars(0, tb_ets_monitor);
        
        // Initialize
        clk = 0;
        rst_n = 0;
        instr_start = 0;
        instr_active = 0;
        instr_done = 0;
        instr_pc = 0;
        instr_opcode = 0;
        reg_wr_en = 0;
        reg_addr = 0;
        reg_wr_data = 0;
        test_num = 0;
        
        // Reset
        #20;
        rst_n = 1;
        #20;
        
        $display("========================================");
        $display("ETS Monitor Testbench");
        $display("========================================");
        
        // Test 1: Configure ETS
        test_num = 1;
        $display("\n[Test %0d] Configure ETS", test_num);
        write_reg(16'h0000, 32'h0000_0011);  // Enable, fine-grained mode
        write_reg(16'h000C, 32'h0000_000F);  // Alert config: all enabled
        #20;
        
        // Test 2: Set timing signature for ADDI (opcode 0x13)
        test_num = 2;
        $display("\n[Test %0d] Set signature for ADDI (0x13)", test_num);
        // Signature index 0x13 (19), expected=5 cycles, tolerance=1
        write_reg(16'h014C, 32'h0005_0101);  // Offset 0x100 + 0x4C = entry 19
        #20;
        
        // Test 3: Simulate normal instruction (within tolerance)
        test_num = 3;
        $display("\n[Test %0d] Execute ADDI with normal timing (5 cycles)", test_num);
        execute_instruction(7'h13, 32'h0000_0100, 5);
        #50;
        
        if (!dbg_anomaly_detected)
            $display("  PASS: No anomaly detected");
        else
            $display("  FAIL: False anomaly!");
        
        // Test 4: Simulate slow instruction (triggers anomaly)
        test_num = 4;
        $display("\n[Test %0d] Execute ADDI with slow timing (10 cycles)", test_num);
        execute_instruction(7'h13, 32'h0000_0104, 10);
        #50;
        
        if (dbg_anomaly_detected)
            $display("  PASS: Anomaly detected!");
        else
            $display("  FAIL: Anomaly not detected!");
        
        // Test 5: Check anomaly count
        test_num = 5;
        $display("\n[Test %0d] Check anomaly count", test_num);
        read_reg(16'h001C);
        #20;
        $display("  Anomaly count: %0d", reg_rd_data);
        
        // Test 6: Read last anomaly PC
        test_num = 6;
        $display("\n[Test %0d] Check last anomaly PC", test_num);
        read_reg(16'h0014);
        #20;
        $display("  Last anomaly PC: 0x%08x", reg_rd_data);
        
        #100;
        $display("\n========================================");
        $display("Testbench Complete");
        $display("========================================");
        $finish;
    end
    
    // Task: Write to ETS register
    task write_reg(input [15:0] addr, input [31:0] data);
        begin
            @(posedge clk);
            reg_wr_en <= 1;
            reg_addr <= addr;
            reg_wr_data <= data;
            @(posedge clk);
            reg_wr_en <= 0;
        end
    endtask
    
    // Task: Read from ETS register
    task read_reg(input [15:0] addr);
        begin
            @(posedge clk);
            reg_addr <= addr;
            @(posedge clk);
            #1;  // Allow time for combinational read
        end
    endtask
    
    // Task: Simulate instruction execution
    task execute_instruction(
        input [6:0] opcode,
        input [31:0] pc,
        input integer cycles
    );
        integer i;
        begin
            @(posedge clk);
            instr_opcode <= opcode;
            instr_pc <= pc;
            instr_start <= 1;
            instr_active <= 1;
            @(posedge clk);
            instr_start <= 0;
            
            // Execute for specified cycles
            for (i = 1; i < cycles; i = i + 1) begin
                @(posedge clk);
            end
            
            // Complete instruction
            instr_done <= 1;
            @(posedge clk);
            instr_done <= 0;
            instr_active <= 0;
        end
    endtask

endmodule


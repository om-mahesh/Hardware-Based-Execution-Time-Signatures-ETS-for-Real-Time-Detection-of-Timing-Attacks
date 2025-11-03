/**
 * ets_riscv_top.v
 * 
 * Top-level integration of RISC-V core + ETS monitoring module.
 * This module connects PicoRV32 with the ETS monitor and provides
 * a unified memory interface.
 */

module ets_riscv_top (
    input  wire        clk,
    input  wire        rst_n,
    
    // External memory interface (to BRAM/peripherals)
    output wire        mem_valid,
    output wire        mem_instr,
    input  wire        mem_ready,
    output wire [31:0] mem_addr,
    output wire [31:0] mem_wdata,
    output wire [3:0]  mem_wstrb,
    input  wire [31:0] mem_rdata,
    
    // Interrupts
    input  wire [31:0] irq,
    output wire [31:0] eoi,
    
    // ETS outputs
    output wire        ets_alert_flag,
    output wire        ets_alert_interrupt,
    
    // Debug
    output wire [31:0] dbg_pc,
    output wire [31:0] dbg_cycle_count,
    output wire        dbg_anomaly
);

    // ========== RISC-V Core (PicoRV32) ==========
    // Note: Replace with actual PicoRV32 instantiation
    // This is a placeholder showing the interface
    
    wire [31:0] picorv_mem_addr;
    wire [31:0] picorv_mem_wdata;
    wire [3:0]  picorv_mem_wstrb;
    wire        picorv_mem_valid;
    wire        picorv_mem_instr;
    wire        picorv_mem_ready;
    wire [31:0] picorv_mem_rdata;
    
    wire [31:0] picorv_irq;
    wire [31:0] picorv_eoi;
    
    // Internal signals for ETS monitoring
    wire [31:0] core_pc;
    wire        core_instr_valid;
    wire        core_instr_done;
    wire [31:0] core_instr;
    
    // PicoRV32 instantiation
    picorv32 #(
        .ENABLE_COUNTERS    (1),
        .ENABLE_COUNTERS64  (0),
        .ENABLE_REGS_16_31  (1),
        .ENABLE_REGS_DUALPORT(0),
        .LATCHED_MEM_RDATA  (0),    // Changed to 0 for better BRAM inference
        .TWO_STAGE_SHIFT    (1),
        .BARREL_SHIFTER     (0),
        .TWO_CYCLE_COMPARE  (0),
        .TWO_CYCLE_ALU      (0),
        .COMPRESSED_ISA     (0),
        .CATCH_MISALIGN     (1),
        .CATCH_ILLINSN      (1),
        .ENABLE_PCPI        (0),
        .ENABLE_MUL         (0),
        .ENABLE_FAST_MUL    (0),
        .ENABLE_DIV         (0),
        .ENABLE_IRQ         (1),
        .ENABLE_IRQ_QREGS   (0),
        .ENABLE_IRQ_TIMER   (1),
        .ENABLE_TRACE       (0),    // Trace disabled - use memory interface for ETS
        .REGS_INIT_ZERO     (0),
        .MASKED_IRQ         (32'h0000_0000),
        .LATCHED_IRQ        (32'hFFFF_FFFF),
        .PROGADDR_RESET     (32'h0000_0000),
        .PROGADDR_IRQ       (32'h0000_0010),
        .STACKADDR          (32'h0000_0400)
    ) riscv_core (
        .clk        (clk),
        .resetn     (rst_n),
        .trap       (),
        
        .mem_valid  (picorv_mem_valid),
        .mem_instr  (picorv_mem_instr),
        .mem_ready  (picorv_mem_ready),
        .mem_addr   (picorv_mem_addr),
        .mem_wdata  (picorv_mem_wdata),
        .mem_wstrb  (picorv_mem_wstrb),
        .mem_rdata  (picorv_mem_rdata),
        
        .mem_la_read (),
        .mem_la_write(),
        .mem_la_addr (),
        .mem_la_wdata(),
        .mem_la_wstrb(),
        
        .pcpi_valid (),
        .pcpi_insn  (),
        .pcpi_rs1   (),
        .pcpi_rs2   (),
        .pcpi_wr    (1'b0),
        .pcpi_rd    (32'h0),
        .pcpi_wait  (1'b0),
        .pcpi_ready (1'b0),
        
        .irq        (picorv_irq),
        .eoi        (picorv_eoi),
        
        .trace_valid(),
        .trace_data ()
    );
    
    // Use memory interface for ETS monitoring
    // PC is inferred from instruction fetch addresses
    assign core_pc          = picorv_mem_addr;
    assign core_instr       = picorv_mem_rdata;
    assign core_instr_valid = picorv_mem_valid && picorv_mem_instr;
    assign core_instr_done  = picorv_mem_valid && picorv_mem_ready && picorv_mem_instr;
    
    // ========== ETS Signal Extraction ==========
    // Derive ETS monitoring signals from PicoRV32 state
    wire instr_start  = picorv_mem_valid && picorv_mem_instr && picorv_mem_ready;
    wire instr_active = picorv_mem_valid && !picorv_mem_ready;
    wire instr_done   = picorv_mem_valid && picorv_mem_ready && !picorv_mem_instr;
    wire [6:0] instr_opcode = picorv_mem_rdata[6:0];  // RISC-V opcode field
    
    // ========== ETS Memory-Mapped Access ==========
    // ETS registers mapped to 0x80000000 - 0x8000FFFF
    wire        ets_reg_access = (picorv_mem_addr[31:16] == 16'h8000);
    wire        ets_reg_wr_en  = ets_reg_access && picorv_mem_valid && (|picorv_mem_wstrb);
    wire [15:0] ets_reg_addr   = picorv_mem_addr[15:0];
    wire [31:0] ets_reg_rdata;
    
    // ========== ETS Monitor Instantiation ==========
    ets_monitor ets (
        .clk                (clk),
        .rst_n              (rst_n),
        
        .instr_start        (instr_start),
        .instr_active       (instr_active),
        .instr_done         (instr_done),
        .instr_pc           (core_pc),
        .instr_opcode       (instr_opcode),
        
        .reg_wr_en          (ets_reg_wr_en),
        .reg_addr           (ets_reg_addr),
        .reg_wr_data        (picorv_mem_wdata),
        .reg_rd_data        (ets_reg_rdata),
        
        .alert_interrupt    (ets_alert_interrupt),
        .alert_flag         (ets_alert_flag),
        
        .dbg_cycle_count    (dbg_cycle_count),
        .dbg_anomaly_detected(dbg_anomaly)
    );
    
    // ========== Memory Arbiter ==========
    // Route memory requests: ETS registers vs. external memory
    assign mem_valid = picorv_mem_valid && !ets_reg_access;
    assign mem_instr = picorv_mem_instr;
    assign mem_addr  = picorv_mem_addr;
    assign mem_wdata = picorv_mem_wdata;
    assign mem_wstrb = picorv_mem_wstrb;
    
    assign picorv_mem_ready = ets_reg_access ? 1'b1 : mem_ready;
    assign picorv_mem_rdata = ets_reg_access ? ets_reg_rdata : mem_rdata;
    
    // ========== Interrupt Routing ==========
    // Combine external IRQ with ETS alert interrupt
    assign picorv_irq = irq | {31'b0, ets_alert_interrupt};
    assign eoi        = picorv_eoi;
    
    // ========== Debug Outputs ==========
    assign dbg_pc = core_pc;

endmodule


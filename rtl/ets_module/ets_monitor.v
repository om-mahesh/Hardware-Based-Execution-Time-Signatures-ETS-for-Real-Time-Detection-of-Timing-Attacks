/**
 * ets_monitor.v
 * 
 * Top-level Execution Time Signatures (ETS) monitoring module.
 * Integrates all ETS submodules into a cohesive monitoring system.
 */

module ets_monitor (
    input  wire        clk,
    input  wire        rst_n,
    
    // ========== RISC-V Core Interface ==========
    // Execution monitoring
    input  wire        instr_start,      // New instruction starting
    input  wire        instr_active,     // Instruction executing
    input  wire        instr_done,       // Instruction completed
    input  wire [31:0] instr_pc,         // Program counter
    input  wire [6:0]  instr_opcode,     // Instruction opcode (for indexing)
    
    // ========== Memory-Mapped Register Interface ==========
    input  wire        reg_wr_en,
    input  wire [15:0] reg_addr,         // 16-bit address (64KB space)
    input  wire [31:0] reg_wr_data,
    output reg  [31:0] reg_rd_data,
    
    // ========== Alert Outputs ==========
    output wire        alert_interrupt,  // To processor interrupt controller
    output wire        alert_flag,       // To GPIO/LED
    
    // ========== Debug Outputs ==========
    output wire [31:0] dbg_cycle_count,
    output wire        dbg_anomaly_detected
);

    // ========== ETS Control Registers ==========
    reg [31:0] ets_ctrl;           // 0x000
    reg [31:0] ets_status;         // 0x004
    reg [31:0] ets_alert_config;   // 0x00C
    
    wire       ets_enable      = ets_ctrl[0];
    wire [3:0] monitor_mode    = ets_ctrl[7:4];
    wire       learning_mode   = ets_ctrl[3];
    
    // ========== Cycle Counter ==========
    wire [31:0] cycle_count;
    wire        count_valid;
    
    cycle_counter counter (
        .clk            (clk),
        .rst_n          (rst_n),
        .instr_start    (instr_start),
        .instr_active   (instr_active),
        .instr_done     (instr_done),
        .cycle_count    (cycle_count),
        .count_valid    (count_valid)
    );
    
    // ========== Signature Database ==========
    wire [5:0]  sig_rd_addr;
    wire [31:0] sig_rd_data;
    wire [15:0] expected_cycles;
    wire [7:0]  tolerance;
    wire [7:0]  sig_flags;
    
    wire        sig_wr_en;
    wire [5:0]  sig_wr_addr;
    wire [31:0] sig_wr_data;
    
    // Index signature DB by opcode (7 bits -> 6 bits via hashing/truncation)
    assign sig_rd_addr = instr_opcode[5:0];
    
    signature_db sig_db (
        .clk             (clk),
        .rst_n           (rst_n),
        .rd_addr         (sig_rd_addr),
        .rd_data         (sig_rd_data),
        .wr_en           (sig_wr_en),
        .wr_addr         (sig_wr_addr),
        .wr_data         (sig_wr_data),
        .expected_cycles (expected_cycles),
        .tolerance       (tolerance),
        .flags           (sig_flags)
    );
    
    // ========== Comparator ==========
    wire        anomaly_detected;
    wire [31:0] timing_delta;
    wire        too_slow;
    wire        too_fast;
    
    comparator comp (
        .clk             (clk),
        .rst_n           (rst_n),
        .actual_cycles   (cycle_count),
        .expected_cycles (expected_cycles),
        .tolerance       (tolerance),
        .compare_enable  (count_valid),
        .monitor_enable  (ets_enable && !learning_mode),
        .anomaly_detected(anomaly_detected),
        .timing_delta    (timing_delta),
        .too_slow        (too_slow),
        .too_fast        (too_fast)
    );
    
    // ========== Alert Controller ==========
    wire [31:0] anomaly_count;
    wire [31:0] last_anomaly_pc;
    wire [31:0] last_timing_delta;
    wire        log_wr_en;
    wire [4:0]  log_wr_addr;
    wire [95:0] log_wr_data;
    
    alert_controller alert (
        .clk              (clk),
        .rst_n            (rst_n),
        .anomaly_detected (anomaly_detected),
        .anomaly_pc       (instr_pc),
        .timing_delta     (timing_delta),
        .too_slow         (too_slow),
        .too_fast         (too_fast),
        .alert_config     (ets_alert_config[7:0]),
        .alert_interrupt  (alert_interrupt),
        .alert_flag       (alert_flag),
        .anomaly_count    (anomaly_count),
        .last_anomaly_pc  (last_anomaly_pc),
        .last_timing_delta(last_timing_delta),
        .log_wr_en        (log_wr_en),
        .log_wr_addr      (log_wr_addr),
        .log_wr_data      (log_wr_data)
    );
    
    // ========== Memory-Mapped Register Access ==========
    // Decode addresses
    wire addr_ctrl           = (reg_addr == 16'h0000);
    wire addr_status         = (reg_addr == 16'h0004);
    wire addr_alert_config   = (reg_addr == 16'h000C);
    wire addr_current_cycles = (reg_addr == 16'h0010);
    wire addr_last_pc        = (reg_addr == 16'h0014);
    wire addr_last_delta     = (reg_addr == 16'h0018);
    wire addr_anomaly_count  = (reg_addr == 16'h001C);
    wire addr_sig_db         = (reg_addr >= 16'h0100 && reg_addr < 16'h0200);
    
    wire [5:0] sig_db_index = reg_addr[7:2];  // Word-aligned
    
    assign sig_wr_en   = reg_wr_en && addr_sig_db;
    assign sig_wr_addr = sig_db_index;
    assign sig_wr_data = reg_wr_data;
    
    // Register writes
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            ets_ctrl         <= 32'h0000_0001;  // Default: enabled, fine-grained mode
            ets_alert_config <= 32'h0000_000F;  // All alerts enabled
        end
        else if (reg_wr_en) begin
            if (addr_ctrl)
                ets_ctrl <= reg_wr_data;
            if (addr_alert_config)
                ets_alert_config <= reg_wr_data;
        end
    end
    
    // Register reads
    always @(*) begin
        case (1'b1)
            addr_ctrl:           reg_rd_data = ets_ctrl;
            addr_status:         reg_rd_data = {anomaly_count[31:16], 8'd0, 
                                                 4'd0, learning_mode, 2'd0, 
                                                 alert_flag};
            addr_alert_config:   reg_rd_data = ets_alert_config;
            addr_current_cycles: reg_rd_data = cycle_count;
            addr_last_pc:        reg_rd_data = last_anomaly_pc;
            addr_last_delta:     reg_rd_data = last_timing_delta;
            addr_anomaly_count:  reg_rd_data = anomaly_count;
            addr_sig_db:         reg_rd_data = sig_rd_data;
            default:             reg_rd_data = 32'hDEADBEEF;
        endcase
    end
    
    // ========== Debug Outputs ==========
    assign dbg_cycle_count      = cycle_count;
    assign dbg_anomaly_detected = anomaly_detected;

endmodule


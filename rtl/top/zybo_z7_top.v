/**
 * zybo_z7_top.v
 * 
 * Top-level module for Zybo Z7-10 FPGA board.
 * Instantiates ETS-enhanced RISC-V processor with:
 * - Block RAM for instruction/data memory
 * - UART for console
 * - GPIO for LEDs, switches, buttons
 * - Pmod debug outputs
 */

module zybo_z7_top (
    // ========== Clock and Reset ==========
    input  wire        clk,              // 125 MHz system clock
    input  wire        rst_n,            // BTN0 (active low)
    
    // ========== LEDs (Status) ==========
    output wire        ets_alert_flag,   // LED0: ETS alert
    output wire        dbg_anomaly,      // LED1: Anomaly detected
    output wire        led_active,       // LED2: System active
    output wire        led_heartbeat,    // LED3: Heartbeat
    
    // ========== Switches (Config) ==========
    input  wire        sw_ets_enable,    // SW0: Enable ETS
    input  wire        sw_learning_mode, // SW1: Learning mode
    
    // ========== Buttons (Control) ==========
    input  wire        btn_clear_ets,    // BTN1: Clear ETS
    input  wire        btn_test_anomaly, // BTN2: Test anomaly
    
    // ========== UART (via Pmod JE) ==========
    output wire        uart_tx,
    
    // ========== Pmod JE (Debug) ==========
    output wire        pmod_ets_irq,
    output wire        pmod_instr_valid,
    output wire        pmod_instr_done,
    output wire        pmod_anomaly
);

    // ========== Clock & Reset Management ==========
    wire sys_clk;
    wire sys_rst_n;
    
    // Optional: Clock divider for slower operation (easier debugging)
    // For now, use 125 MHz directly
    assign sys_clk = clk;
    
    // Synchronize reset (avoid metastability)
    reg [2:0] rst_sync;
    always @(posedge sys_clk or negedge rst_n) begin
        if (!rst_n)
            rst_sync <= 3'b000;
        else
            rst_sync <= {rst_sync[1:0], 1'b1};
    end
    assign sys_rst_n = rst_sync[2];
    
    // ========== Memory Bus (from CPU) ==========
    wire        mem_valid;
    wire        mem_instr;
    wire        mem_ready;
    wire [31:0] mem_addr;
    wire [31:0] mem_wdata;
    wire [3:0]  mem_wstrb;
    wire [31:0] mem_rdata;
    
    // ========== Block RAM ==========
    wire        ram_valid;
    wire        ram_ready;
    wire [31:0] ram_rdata;
    
    // Address decode: 0x00000000-0x00003FFF = RAM (16KB)
    assign ram_valid = mem_valid && (mem_addr[31:14] == 18'h0);
    
    memory #(
        .MEM_SIZE(16384)  // 16 KB
    ) mem (
        .clk       (sys_clk),
        .rst_n     (sys_rst_n),
        .valid     (ram_valid),
        .ready     (ram_ready),
        .addr      (mem_addr),
        .wdata     (mem_wdata),
        .wstrb     (mem_wstrb),
        .rdata     (ram_rdata)
    );
    
    // ========== UART Interface ==========
    wire        uart_valid;
    wire        uart_ready;
    wire [31:0] uart_rdata;
    
    // Address decode: 0x80000000-0x80000FFF = UART
    assign uart_valid = mem_valid && (mem_addr[31:12] == 20'h80000);
    
    uart_interface #(
        .CLOCK_FREQ(125_000_000),  // 125 MHz system clock
        .BAUD_RATE(115200)
    ) uart (
        .clk       (sys_clk),
        .rst_n     (sys_rst_n),
        .mem_valid (uart_valid),
        .mem_addr  (mem_addr),
        .mem_wdata (mem_wdata),
        .mem_wstrb (mem_wstrb),
        .mem_rdata (uart_rdata),
        .mem_ready (uart_ready),
        .uart_tx   (uart_tx)
    );
    
    // ========== Memory Bus Multiplexer ==========
    // Combine responses from RAM and UART
    assign mem_ready = ram_ready || uart_ready;
    assign mem_rdata = ram_valid ? ram_rdata : uart_rdata;
    
    // ========== RISC-V + ETS Processor ==========
    wire [31:0] irq;
    wire [31:0] eoi;
    wire [31:0] dbg_pc;
    wire [31:0] dbg_cycle_count;
    wire        ets_alert_interrupt;
    
    ets_riscv_top processor (
        .clk                 (sys_clk),
        .rst_n               (sys_rst_n),
        
        .mem_valid           (mem_valid),
        .mem_instr           (mem_instr),
        .mem_ready           (mem_ready),
        .mem_addr            (mem_addr),
        .mem_wdata           (mem_wdata),
        .mem_wstrb           (mem_wstrb),
        .mem_rdata           (mem_rdata),
        
        .irq                 (irq),
        .eoi                 (eoi),
        
        .ets_alert_flag      (ets_alert_flag),
        .ets_alert_interrupt (ets_alert_interrupt),
        
        .dbg_pc              (dbg_pc),
        .dbg_cycle_count     (dbg_cycle_count),
        .dbg_anomaly         (dbg_anomaly)
    );
    
    // ========== Peripherals ==========
    // UART not available in PL-only design (on PS side)
    // assign uart_tx = 1'b1;  // Idle high
    
    // ========== Interrupt Controller (Simple) ==========
    // For now, just connect external interrupts
    assign irq = 32'h0000_0000;
    
    // ========== LED Control ==========
    // LED2: System active (toggles with PC changes)
    reg [31:0] last_pc;
    reg        active_flag;
    always @(posedge sys_clk) begin
        last_pc <= dbg_pc;
        if (dbg_pc != last_pc)
            active_flag <= ~active_flag;
    end
    assign led_active = active_flag;
    
    // LED3: Heartbeat (blink at ~1 Hz)
    reg [25:0] heartbeat_counter;
    reg        heartbeat_led;
    always @(posedge sys_clk or negedge sys_rst_n) begin
        if (!sys_rst_n) begin
            heartbeat_counter <= 26'd0;
            heartbeat_led     <= 1'b0;
        end
        else begin
            heartbeat_counter <= heartbeat_counter + 26'd1;
            if (heartbeat_counter == 26'd62_500_000) begin  // 0.5 sec at 125 MHz
                heartbeat_counter <= 26'd0;
                heartbeat_led     <= ~heartbeat_led;
            end
        end
    end
    assign led_heartbeat = heartbeat_led;
    
    // ========== Pmod Debug Outputs ==========
    assign pmod_ets_irq      = ets_alert_interrupt;
    assign pmod_instr_valid  = mem_valid && mem_instr;
    assign pmod_instr_done   = mem_valid && mem_ready;
    assign pmod_anomaly      = dbg_anomaly;
    
    // ========== Switch/Button Handling ==========
    // (Future: Use these to control ETS via memory-mapped writes)
    // For now, unused

endmodule


// ========== Simple Block RAM Module ==========
module memory #(
    parameter MEM_SIZE = 16384  // Bytes (16 KB)
) (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        valid,
    output reg         ready,
    input  wire [31:0] addr,
    input  wire [31:0] wdata,
    input  wire [3:0]  wstrb,
    output reg  [31:0] rdata
);

    // Memory array (word-addressed)
    localparam WORDS = MEM_SIZE / 4;
    reg [31:0] mem [0:WORDS-1];
    
    // Initialize with compiled firmware (test_basic.c)
    integer i;
    initial begin
        // Initialize all to NOPs first
        for (i = 0; i < WORDS; i = i + 1)
            mem[i] = 32'h0000_0013;
        
        // Load firmware from test_basic.hex (245 words = 980 bytes)
        // This is a complete C program with ETS library support
        `include "firmware_init.vh"
    end
    
    wire [31:0] word_addr = addr[31:2];  // Word-aligned
    
    // Separate always blocks for better BRAM inference
    always @(posedge clk) begin
        if (valid && !ready) begin
            // Write
            if (word_addr < WORDS) begin
                if (wstrb[0]) mem[word_addr][7:0]   <= wdata[7:0];
                if (wstrb[1]) mem[word_addr][15:8]  <= wdata[15:8];
                if (wstrb[2]) mem[word_addr][23:16] <= wdata[23:16];
                if (wstrb[3]) mem[word_addr][31:24] <= wdata[31:24];
            end
        end
    end
    
    always @(posedge clk) begin
        if (valid && !ready) begin
            // Read
            if (word_addr < WORDS)
                rdata <= mem[word_addr];
            else
                rdata <= 32'hDEADBEEF;
        end
    end
    
    always @(posedge clk) begin
        if (!rst_n)
            ready <= 1'b0;
        else begin
            if (valid && !ready)
                ready <= 1'b1;
            else
                ready <= 1'b0;
        end
    end

endmodule


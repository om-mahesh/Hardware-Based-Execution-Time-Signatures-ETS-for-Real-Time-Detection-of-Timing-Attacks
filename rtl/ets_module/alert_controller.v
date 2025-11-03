/**
 * alert_controller.v
 * 
 * Manages alerts when timing anomalies are detected.
 * - Maintains anomaly counter
 * - Generates interrupts
 * - Controls alert outputs (LEDs, GPIO)
 * - Logs anomalies to circular buffer
 */

module alert_controller (
    input  wire        clk,
    input  wire        rst_n,
    
    // Anomaly detection inputs
    input  wire        anomaly_detected,
    input  wire [31:0] anomaly_pc,
    input  wire [31:0] timing_delta,
    input  wire        too_slow,
    input  wire        too_fast,
    
    // Configuration
    input  wire [7:0]  alert_config,
    // [0] - Enable alerts
    // [1] - Generate interrupt
    // [2] - Halt processor (future)
    // [3] - Log to buffer
    
    // Outputs
    output reg         alert_interrupt,    // Interrupt to processor
    output reg         alert_flag,         // GPIO/LED output
    output reg  [31:0] anomaly_count,      // Total anomalies detected
    
    // Status
    output wire [31:0] last_anomaly_pc,
    output wire [31:0] last_timing_delta,
    
    // Log buffer interface
    output reg         log_wr_en,
    output reg  [4:0]  log_wr_addr,        // 32-entry circular buffer
    output reg  [95:0] log_wr_data         // {PC[31:0], delta[31:0], flags[31:0]}
);

    // Configuration bits
    wire enable_alerts    = alert_config[0];
    wire enable_interrupt = alert_config[1];
    wire enable_logging   = alert_config[3];
    
    // Last anomaly info (for status registers)
    reg [31:0] last_pc;
    reg [31:0] last_delta;
    
    assign last_anomaly_pc    = last_pc;
    assign last_timing_delta  = last_delta;
    
    // Interrupt generation (one-cycle pulse)
    reg anomaly_detected_prev;
    wire anomaly_edge;
    
    assign anomaly_edge = anomaly_detected && !anomaly_detected_prev;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            anomaly_detected_prev <= 1'b0;
            alert_interrupt       <= 1'b0;
            alert_flag            <= 1'b0;
            anomaly_count         <= 32'd0;
            last_pc               <= 32'd0;
            last_delta            <= 32'd0;
            log_wr_en             <= 1'b0;
            log_wr_addr           <= 5'd0;
            log_wr_data           <= 96'd0;
        end
        else begin
            anomaly_detected_prev <= anomaly_detected;
            
            if (anomaly_edge && enable_alerts) begin
                // Increment counter
                if (anomaly_count < 32'hFFFFFFFF)
                    anomaly_count <= anomaly_count + 32'd1;
                
                // Save last anomaly info
                last_pc    <= anomaly_pc;
                last_delta <= timing_delta;
                
                // Set alert flag (sticky - cleared by software)
                alert_flag <= 1'b1;
                
                // Generate interrupt pulse
                if (enable_interrupt)
                    alert_interrupt <= 1'b1;
                
                // Log to buffer
                if (enable_logging) begin
                    log_wr_en   <= 1'b1;
                    log_wr_data <= {anomaly_pc, timing_delta, 
                                    {30'd0, too_slow, too_fast}};
                    log_wr_addr <= log_wr_addr + 5'd1;  // Circular
                end
            end
            else begin
                alert_interrupt <= 1'b0;
                log_wr_en       <= 1'b0;
            end
        end
    end

endmodule


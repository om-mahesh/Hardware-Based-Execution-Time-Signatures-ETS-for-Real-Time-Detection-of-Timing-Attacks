/**
 * comparator.v
 * 
 * Compares actual instruction execution time against expected signature.
 * Generates anomaly flag if timing deviates beyond tolerance.
 */

module comparator (
    input  wire        clk,
    input  wire        rst_n,
    
    // Inputs
    input  wire [31:0] actual_cycles,      // From cycle counter
    input  wire [15:0] expected_cycles,    // From signature DB
    input  wire [7:0]  tolerance,          // From signature DB
    input  wire        compare_enable,     // Enable comparison
    input  wire        monitor_enable,     // Global ETS enable
    
    // Outputs
    output reg         anomaly_detected,   // Timing violation detected
    output reg  [31:0] timing_delta,       // Signed difference (actual - expected)
    output reg         too_slow,           // Took longer than expected
    output reg         too_fast            // Took shorter than expected
);

    wire signed [31:0] expected_signed;
    wire signed [31:0] actual_signed;
    wire signed [31:0] delta_signed;
    wire signed [31:0] upper_bound;
    wire signed [31:0] lower_bound;
    
    assign expected_signed = {16'd0, expected_cycles};
    assign actual_signed   = actual_cycles;
    assign delta_signed    = actual_signed - expected_signed;
    
    assign upper_bound = expected_signed + {24'd0, tolerance};
    assign lower_bound = expected_signed - {24'd0, tolerance};
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            anomaly_detected <= 1'b0;
            timing_delta     <= 32'd0;
            too_slow         <= 1'b0;
            too_fast         <= 1'b0;
        end
        else if (compare_enable && monitor_enable) begin
            timing_delta <= delta_signed;
            
            // Check if actual timing is outside tolerance bounds
            if (actual_signed > upper_bound) begin
                anomaly_detected <= 1'b1;
                too_slow         <= 1'b1;
                too_fast         <= 1'b0;
            end
            else if (actual_signed < lower_bound) begin
                anomaly_detected <= 1'b1;
                too_slow         <= 1'b0;
                too_fast         <= 1'b1;
            end
            else begin
                anomaly_detected <= 1'b0;
                too_slow         <= 1'b0;
                too_fast         <= 1'b0;
            end
        end
        else begin
            anomaly_detected <= 1'b0;
            too_slow         <= 1'b0;
            too_fast         <= 1'b0;
        end
    end

endmodule


/**
 * cycle_counter.v
 * 
 * Counts clock cycles for instruction execution timing.
 * Resets on instruction start, increments during execution,
 * latches final count when instruction completes.
 */

module cycle_counter (
    input  wire        clk,
    input  wire        rst_n,
    
    // Control signals from RISC-V core
    input  wire        instr_start,    // Pulse: new instruction starting
    input  wire        instr_active,   // High: instruction executing
    input  wire        instr_done,     // Pulse: instruction completed
    
    // Output
    output reg  [31:0] cycle_count,    // Current/latched cycle count
    output reg         count_valid     // High: count is latched and valid
);

    reg [31:0] counter_reg;
    reg        counting;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            counter_reg  <= 32'd0;
            cycle_count  <= 32'd0;
            count_valid  <= 1'b0;
            counting     <= 1'b0;
        end
        else begin
            // Start counting on new instruction
            if (instr_start) begin
                counter_reg <= 32'd1;  // First cycle
                count_valid <= 1'b0;
                counting    <= 1'b1;
            end
            
            // Increment while instruction is active
            else if (counting && instr_active) begin
                counter_reg <= counter_reg + 32'd1;
            end
            
            // Latch final count when done
            if (instr_done) begin
                cycle_count <= counter_reg;
                count_valid <= 1'b1;
                counting    <= 1'b0;
            end
            
            // Clear valid flag after one cycle (allows next monitoring)
            else if (count_valid && !instr_done) begin
                count_valid <= 1'b0;
            end
        end
    end

endmodule


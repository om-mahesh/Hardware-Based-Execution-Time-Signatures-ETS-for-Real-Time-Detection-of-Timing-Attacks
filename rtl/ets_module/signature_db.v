/**
 * signature_db.v
 * 
 * Stores expected execution timing signatures for instructions.
 * 
 * Memory Organization:
 *   - 64 entries (indexed by opcode/instruction type)
 *   - Each entry: {expected_cycles, tolerance, flags}
 */

module signature_db (
    input  wire        clk,
    input  wire        rst_n,
    
    // Read port (for timing comparison)
    input  wire [5:0]  rd_addr,        // Instruction ID to look up
    output reg  [31:0] rd_data,        // Signature data
    
    // Write port (for configuration/learning)
    input  wire        wr_en,
    input  wire [5:0]  wr_addr,
    input  wire [31:0] wr_data,
    
    // Decoded signature fields (from rd_data)
    output wire [15:0] expected_cycles,
    output wire [7:0]  tolerance,
    output wire [7:0]  flags
);

    // Signature database: 64 entries × 32 bits
    // Entry format: {expected_cycles[31:16], tolerance[15:8], flags[7:0]}
    reg [31:0] signature_mem [0:63];
    
    // Initialize with safe defaults (tolerant thresholds)
    integer i;
    initial begin
        for (i = 0; i < 64; i = i + 1) begin
            signature_mem[i] = 32'h00_0A_FF_01;
            // expected=10 cycles, tolerance=255 (very permissive), enabled
        end
    end
    
    // Read port (combinational for low latency)
    always @(*) begin
        rd_data = signature_mem[rd_addr];
    end
    
    // Write port (synchronous)
    always @(posedge clk) begin
        if (wr_en) begin
            signature_mem[wr_addr] <= wr_data;
        end
    end
    
    // Decode signature fields
    assign expected_cycles = rd_data[31:16];
    assign tolerance       = rd_data[15:8];
    assign flags           = rd_data[7:0];

endmodule


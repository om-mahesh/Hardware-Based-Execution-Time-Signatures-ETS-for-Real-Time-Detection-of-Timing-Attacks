/**
 * uart_interface.v
 * 
 * Memory-mapped UART interface wrapper
 * Provides simple register interface for software to use UART
 * 
 * Memory Map:
 *   0x80000000 - TX_DATA (write only) - Write byte to transmit
 *   0x80000004 - TX_READY (read only) - 1 = ready, 0 = busy
 */

module uart_interface #(
    parameter CLOCK_FREQ = 100_000_000,
    parameter BAUD_RATE  = 115200
)(
    input  wire        clk,
    input  wire        rst_n,
    
    // Memory interface (from CPU)
    input  wire        mem_valid,
    input  wire [31:0] mem_addr,
    input  wire [31:0] mem_wdata,
    input  wire [3:0]  mem_wstrb,
    output reg  [31:0] mem_rdata,
    output reg         mem_ready,
    
    // UART TX pin
    output wire        uart_tx
);

    // Address decode
    localparam ADDR_TX_DATA  = 32'h80000000;
    localparam ADDR_TX_READY = 32'h80000004;
    
    wire addr_tx_data  = (mem_addr == ADDR_TX_DATA);
    wire addr_tx_ready = (mem_addr == ADDR_TX_READY);
    wire write_op = |mem_wstrb;
    
    // UART TX signals
    reg [7:0] tx_data;
    reg       tx_valid;
    wire      tx_ready;
    
    // UART TX module
    uart_tx #(
        .CLOCK_FREQ(CLOCK_FREQ),
        .BAUD_RATE(BAUD_RATE)
    ) uart_tx_inst (
        .clk      (clk),
        .rst_n    (rst_n),
        .tx_data  (tx_data),
        .tx_valid (tx_valid),
        .tx_ready (tx_ready),
        .tx_pin   (uart_tx)
    );
    
    // Memory interface logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            mem_ready <= 1'b0;
            mem_rdata <= 32'h0;
            tx_data   <= 8'h0;
            tx_valid  <= 1'b0;
        end else begin
            // Default: clear tx_valid (pulse)
            tx_valid <= 1'b0;
            
            if (mem_valid && !mem_ready) begin
                mem_ready <= 1'b1;
                
                if (write_op) begin
                    // Write operation
                    if (addr_tx_data) begin
                        tx_data  <= mem_wdata[7:0];
                        tx_valid <= 1'b1;  // Start transmission
                    end
                end else begin
                    // Read operation
                    if (addr_tx_ready) begin
                        mem_rdata <= {31'h0, tx_ready};
                    end else begin
                        mem_rdata <= 32'h0;
                    end
                end
            end else if (!mem_valid) begin
                mem_ready <= 1'b0;
            end
        end
    end

endmodule


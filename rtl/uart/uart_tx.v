/**
 * uart_tx.v
 * 
 * Simple UART Transmitter for data logging
 * 
 * Parameters:
 *   CLOCK_FREQ - System clock frequency in Hz (default 100 MHz)
 *   BAUD_RATE  - UART baud rate (default 115200)
 * 
 * Interface:
 *   clk        - System clock
 *   rst_n      - Active-low reset
 *   tx_data    - 8-bit data to transmit
 *   tx_valid   - Pulse high to start transmission
 *   tx_ready   - High when ready for next byte
 *   tx_pin     - UART TX output pin
 */

module uart_tx #(
    parameter CLOCK_FREQ = 100_000_000,  // 100 MHz
    parameter BAUD_RATE  = 115200        // 115200 baud
)(
    input  wire       clk,
    input  wire       rst_n,
    input  wire [7:0] tx_data,
    input  wire       tx_valid,
    output reg        tx_ready,
    output reg        tx_pin
);

    // Calculate baud rate divisor
    localparam DIVISOR = CLOCK_FREQ / BAUD_RATE;
    localparam DIVISOR_WIDTH = $clog2(DIVISOR);
    
    // State machine
    localparam IDLE  = 2'b00;
    localparam START = 2'b01;
    localparam DATA  = 2'b10;
    localparam STOP  = 2'b11;
    
    reg [1:0] state;
    reg [2:0] bit_count;
    reg [7:0] shift_reg;
    reg [DIVISOR_WIDTH-1:0] baud_count;
    
    // Baud rate tick generation
    wire baud_tick = (baud_count == DIVISOR - 1);
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state      <= IDLE;
            tx_pin     <= 1'b1;  // Idle high
            tx_ready   <= 1'b1;
            bit_count  <= 3'd0;
            shift_reg  <= 8'd0;
            baud_count <= {DIVISOR_WIDTH{1'b0}};
        end else begin
            // Baud rate counter
            if (state == IDLE) begin
                baud_count <= {DIVISOR_WIDTH{1'b0}};
            end else if (baud_tick) begin
                baud_count <= {DIVISOR_WIDTH{1'b0}};
            end else begin
                baud_count <= baud_count + 1;
            end
            
            // State machine
            case (state)
                IDLE: begin
                    tx_pin   <= 1'b1;  // Idle high
                    tx_ready <= 1'b1;
                    
                    if (tx_valid && tx_ready) begin
                        shift_reg <= tx_data;
                        tx_ready  <= 1'b0;
                        state     <= START;
                    end
                end
                
                START: begin
                    tx_pin <= 1'b0;  // Start bit (low)
                    
                    if (baud_tick) begin
                        bit_count <= 3'd0;
                        state     <= DATA;
                    end
                end
                
                DATA: begin
                    tx_pin <= shift_reg[0];  // LSB first
                    
                    if (baud_tick) begin
                        shift_reg <= {1'b0, shift_reg[7:1]};  // Shift right
                        bit_count <= bit_count + 1;
                        
                        if (bit_count == 3'd7) begin
                            state <= STOP;
                        end
                    end
                end
                
                STOP: begin
                    tx_pin <= 1'b1;  // Stop bit (high)
                    
                    if (baud_tick) begin
                        state <= IDLE;
                    end
                end
                
                default: begin
                    state <= IDLE;
                end
            endcase
        end
    end

endmodule


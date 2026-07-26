

module uart_tx #(
    parameter CLK_FREQ_HZ = 50_000_000,   
    parameter BAUD_RATE   = 9600          
)(
    input  wire       clk,
    input  wire       rst_n,
    input  wire [7:0] tx_data,
    input  wire       tx_start,
    output reg        tx_serial_out,
    output reg        tx_busy
);


    localparam CLKS_PER_BIT = CLK_FREQ_HZ / BAUD_RATE;

 
    localparam S_IDLE      = 2'd0;
    localparam S_START_BIT = 2'd1;
    localparam S_DATA_BITS = 2'd2;
    localparam S_STOP_BIT  = 2'd3;

    reg [1:0]                       state;
    reg [$clog2(CLKS_PER_BIT)-1:0] clk_count;
    reg [2:0]                       bit_index;
    reg [7:0]                       tx_shift_reg;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state         <= S_IDLE;
            clk_count     <= 0;
            bit_index     <= 0;
            tx_shift_reg  <= 8'd0;
            tx_serial_out <= 1'b1;   
            tx_busy       <= 1'b0;
        end else begin
            case (state)
                
                S_IDLE: begin
                    tx_serial_out <= 1'b1;
                    clk_count     <= 0;
                    bit_index     <= 0;
                    if (tx_start) begin
                        tx_busy      <= 1'b1;
                        tx_shift_reg <= tx_data;
                        state        <= S_START_BIT;
                    end else begin
                        tx_busy <= 1'b0;
                    end
                end

                
                S_START_BIT: begin
                    tx_serial_out <= 1'b0;
                    if (clk_count < CLKS_PER_BIT - 1) begin
                        clk_count <= clk_count + 1'b1;
                    end else begin
                        clk_count <= 0;
                        state     <= S_DATA_BITS;
                    end
                end

                
                S_DATA_BITS: begin
                    tx_serial_out <= tx_shift_reg[bit_index];
                    if (clk_count < CLKS_PER_BIT - 1) begin
                        clk_count <= clk_count + 1'b1;
                    end else begin
                        clk_count <= 0;
                        if (bit_index < 7) begin
                            bit_index <= bit_index + 1'b1;
                        end else begin
                            bit_index <= 0;
                            state     <= S_STOP_BIT;
                        end
                    end
                end

                
                S_STOP_BIT: begin
                    tx_serial_out <= 1'b1;
                    if (clk_count < CLKS_PER_BIT - 1) begin
                        clk_count <= clk_count + 1'b1;
                    end else begin
                        clk_count <= 0;
                        tx_busy   <= 1'b0;
                        state     <= S_IDLE;
                    end
                end

                default: state <= S_IDLE;
            endcase
        end
    end

endmodule

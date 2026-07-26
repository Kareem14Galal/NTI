

module uart_rx #(
    parameter CLK_FREQ_HZ = 50_000_000,   
    parameter BAUD_RATE   = 9600          
)(
    input  wire       clk,
    input  wire       rst_n,
    input  wire       rx_serial_in,
    output reg  [7:0] rx_byte,
    output reg        rx_valid,
    output reg        start_cmd,   
    output reg        reset_cmd
    
);

    
    localparam CLKS_PER_BIT = CLK_FREQ_HZ / BAUD_RATE;


    localparam CMD_START = 8'h53;  
    localparam CMD_RESET = 8'h52;  

    // ---- FSM states ----
    localparam S_IDLE       = 3'd0;
    localparam S_START_BIT  = 3'd1;
    localparam S_DATA_BITS  = 3'd2;
    localparam S_STOP_BIT   = 3'd3;
    localparam S_CLEANUP    = 3'd4;

    reg [2:0]                        state;
    reg [$clog2(CLKS_PER_BIT)-1:0]  clk_count;
    reg [2:0]                        bit_index;
    reg [7:0]                        rx_shift_reg;


    reg rx_ff1, rx_ff2;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rx_ff1 <= 1'b1;
            rx_ff2 <= 1'b1;
        end else begin
            rx_ff1 <= rx_serial_in;
            rx_ff2 <= rx_ff1;
        end
    end

 
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state        <= S_IDLE;
            clk_count    <= 0;
            bit_index    <= 0;
            rx_shift_reg <= 8'd0;
            rx_byte      <= 8'd0;
            rx_valid     <= 1'b0;
            start_cmd    <= 1'b0;
            reset_cmd    <= 1'b0;
        end else begin

            rx_valid  <= 1'b0;
            start_cmd <= 1'b0;
            reset_cmd <= 1'b0;

            case (state)
                
                S_IDLE: begin
                    clk_count <= 0;
                    bit_index <= 0;
                    if (rx_ff2 == 1'b0)
                        state <= S_START_BIT;
                end

        
                S_START_BIT: begin
                    if (clk_count == (CLKS_PER_BIT - 1) / 2) begin
                        if (rx_ff2 == 1'b0) begin
                            clk_count <= 0;
                            state     <= S_DATA_BITS;
                        end else begin
                            state <= S_IDLE;  
                        end
                    end else begin
                        clk_count <= clk_count + 1'b1;
                    end
                end


                S_DATA_BITS: begin
                    if (clk_count < CLKS_PER_BIT - 1) begin
                        clk_count <= clk_count + 1'b1;
                    end else begin
                        clk_count <= 0;
                        rx_shift_reg[bit_index] <= rx_ff2;
                        if (bit_index < 7) begin
                            bit_index <= bit_index + 1'b1;
                        end else begin
                            bit_index <= 0;
                            state     <= S_STOP_BIT;
                        end
                    end
                end


                S_STOP_BIT: begin
                    if (clk_count < CLKS_PER_BIT - 1) begin
                        clk_count <= clk_count + 1'b1;
                    end else begin
                        rx_byte   <= rx_shift_reg;
                        rx_valid  <= 1'b1;
                        if (rx_shift_reg == CMD_START)
                            start_cmd <= 1'b1;
                        else if (rx_shift_reg == CMD_RESET)
                            reset_cmd <= 1'b1;
                        clk_count <= 0;
                        state     <= S_CLEANUP;
                    end
                end


                S_CLEANUP: begin
                    state <= S_IDLE;
                end

                default: state <= S_IDLE;
            endcase
        end
    end

endmodule

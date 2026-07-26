
module adc_controller #(
    parameter ADC_DATA_WIDTH = 12
)(
    input  wire                      clk,
    input  wire                      rst_n,              // active-low synchronous reset
    input  wire                      start_conversion,   // trigger command from central FSM
    input  wire [ADC_DATA_WIDTH-1:0] adc_data_in,        // raw data directly from ADC pins
    input  wire                      eoc,                // end-of-conversion flag from ADC
    output reg                       adc_trigger,        // trigger pulse to start ADC sampling
    output reg  [ADC_DATA_WIDTH-1:0] data_out,           // latched sample data
    output reg                       data_valid          // high for 1 cycle when output is ready
);

    // FSM State Encoding
    localparam S_IDLE     = 2'b00;
    localparam S_TRIGGER  = 2'b01;
    localparam S_WAIT_EOC = 2'b10;
    localparam S_VALID    = 2'b11;

    reg [1:0] state, next_state;

    // Synchronous State Register Logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= S_IDLE;
        end else begin
            state <= next_state;
        end
    end

    // Combinational Next-State Logic
    always @(*) begin
        case (state)
            S_IDLE: begin
                if (start_conversion)
                    next_state = S_TRIGGER;
                else
                    next_state = S_IDLE;
            end

            S_TRIGGER: begin
                next_state = S_WAIT_EOC;
            end

            S_WAIT_EOC: begin
                if (eoc)
                    next_state = S_VALID;
                else
                    next_state = S_WAIT_EOC;
            end

            S_VALID: begin
                next_state = S_IDLE;
            end

            default: next_state = S_IDLE;
        endcase
    end

    // Output Registers and Data Latching Logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            adc_trigger <= 1'b0;
            data_valid  <= 1'b0;
            data_out    <= {ADC_DATA_WIDTH{1'b0}};
        end else begin
            // Default pulse resets
            adc_trigger <= 1'b0;
            data_valid  <= 1'b0;

            case (state)
                S_IDLE: begin
                    // Waiting state
                end

                S_TRIGGER: begin
                    adc_trigger <= 1'b1; // Send pulse trigger out to ADC pin
                end

                S_WAIT_EOC: begin
                    if (eoc) begin
                        data_out <= adc_data_in; // Latch input data when conversion is done
                    end
                end

                S_VALID: begin
                    data_valid <= 1'b1; // Assert pulse to central FSM & memory write logic
                end

                default: ;
            endcase
        end
    end

endmodule
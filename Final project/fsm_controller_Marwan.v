`timescale 1ns / 1ps
// ============================================================
// Module      : fsm_controller
// Author      : Marwan Mostafa
// Description : The main digital controller for the complete
//               16-antenna microwave imaging scan. It sequences the
//               RF switch matrix, ADC data collection, memory storage,
//               and UART transmission.
//               select antenna -> enable RF switch -> trigger ADC
//               -> wait for data -> store in memory -> repeat for
//               all antennas -> send results over UART -> idle.
// ============================================================
module fsm_controller (
    input  wire clk,
    input  wire rst_n,
    input  wire start_cmd,
    input  wire adc_data_ready,
    input  wire last_antenna_flag,
    output reg  antenna_inc,
    output reg  switch_en,
    output reg  adc_start,
    output reg  mem_write_en,
    output reg  send_uart_en,
    output reg  busy
);

    // ========================================================
    // Defines the states of the measurement sequence.
    // A dedicated S_WAIT_ADC state is intentionally included to so that the ADC trigger is a one-cycle pulse while the system pauses for the analog conversion to finish.
    // ========================================================

    localparam S_IDLE            = 3'd0;
    localparam S_INIT            = 3'd1;
    localparam S_SELECT_ANTENNA  = 3'd2;
    localparam S_TRIGGER_ADC     = 3'd3;
    localparam S_WAIT_ADC        = 3'd4;
    localparam S_STORE_DATA      = 3'd5;
    localparam S_NEXT_ANTENNA    = 3'd6;
    localparam S_SEND_UART       = 3'd7;

    reg [2:0] state, next_state;

    // ========================================================
    // State Register (Sequential)
    // Updates the active state of the controller on every rising clock edge and forces the system back to the S_IDLE state whenever the active-low reset is triggered.
    // ========================================================

    always @(posedge clk or negedge rst_n)
    begin
        if (!rst_n)
            state <= S_IDLE;
        else
            state <= next_state;
    end

    // ========================================================
    // Next-State Logic (Combinational)
    // Evaluates the current active state alongside  external feedback flags (such as start commands or ADC readiness) to calculate exactly which state the machine must transition to on the upcoming clock cycle.
    // ========================================================

    always @(*)
    begin
        next_state = state;
        case (state)
            S_IDLE:           next_state = start_cmd      ? S_INIT           : S_IDLE;
            S_INIT:           next_state = S_SELECT_ANTENNA;
            S_SELECT_ANTENNA: next_state = S_TRIGGER_ADC;
            S_TRIGGER_ADC:    next_state = S_WAIT_ADC;
            S_WAIT_ADC:       next_state = adc_data_ready ? S_STORE_DATA     : S_WAIT_ADC;
            S_STORE_DATA:     next_state = S_NEXT_ANTENNA;
            S_NEXT_ANTENNA:   next_state = last_antenna_flag ? S_SEND_UART   : S_SELECT_ANTENNA;
            S_SEND_UART:      next_state = S_IDLE;
            default:          next_state = S_IDLE;
        endcase
    end

    // ========================================================
    // Moore Output Logic
    // Manages the control signals for the rest of the modules.
    // It defaults all outputs to zero every cycle and only selectively overrides them based on the current state, safely coordinating the RF switch, ADC, memory, and UART.
    // ========================================================

    always @(posedge clk or negedge rst_n)
    begin
        if (!rst_n)
        begin
            antenna_inc  <= 1'b0;
            switch_en    <= 1'b0;
            adc_start    <= 1'b0;
            mem_write_en <= 1'b0;
            send_uart_en <= 1'b0;
            busy         <= 1'b0;
        end else
        begin
            antenna_inc  <= 1'b0;
            switch_en    <= 1'b0;
            adc_start    <= 1'b0;
            mem_write_en <= 1'b0;
            send_uart_en <= 1'b0;
            busy         <= (state != S_IDLE);
            case (state)
                S_SELECT_ANTENNA: switch_en <= 1'b1;
                S_TRIGGER_ADC:    begin
                                       switch_en <= 1'b1;
                                       adc_start <= 1'b1;
                                   end
                S_WAIT_ADC:       switch_en <= 1'b1;
                S_STORE_DATA:     mem_write_en <= 1'b1;
                S_NEXT_ANTENNA:   if (!last_antenna_flag)
                                       antenna_inc <= 1'b1;
                S_SEND_UART:      send_uart_en <= 1'b1;
                default: ;
            endcase
        end
    end
endmodule

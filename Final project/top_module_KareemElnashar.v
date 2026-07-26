`timescale 1ns / 1ps
// ============================================================
// Module      : top_module
// Author      : Kareem Elnashar (Top Module Integration & Testbench)
// Description : Wires together the real modules delivered by the team:
//                 - uart_rx / uart_tx                (Kyrillos)
//                 - fsm_controller                    (Marwan)
//                 - adc_controller / memory_module     (Mohamed)
//                 - antenna_selector / switch_controller (Kareem Galal)
//               and adds the "send sequencer" glue logic needed to
//               stream 16 x 12-bit memory samples out over the 8-bit
//               UART TX byte interface (2 bytes per antenna).
//
// Integration notes (please read before editing):
//  1. memory_module has a SYNCHRONOUS (registered) read: data_out is
//     valid one clock cycle AFTER 'address' changes. The send
//     sequencer below has an explicit SQ_READ_WAIT state to account
//     for this, both on the first antenna and after every increment.
//  2. ADC_DATA_WIDTH (12 bits) does not fit uart_tx's 8-bit tx_data
//     port. This module splits every sample into a high byte and a
//     low byte and sends them back-to-back per antenna (32 bytes
//     total for 16 antennas). CONFIRM this 2-byte protocol with
//     Kyrillos / whatever reads the data on the PC side — an
//     alternative would be an ASCII "Ax=###" text format instead of
//     raw binary, as the original spec examples implied.
//  3. fsm_controller's send_uart_en is a single-cycle pulse; the FSM
//     does NOT wait for the transmission to actually finish before
//     returning to IDLE. Do not issue a new START before the previous
//     transmission completes, until the team adds a "tx done"
//     handshake back into the FSM.
//  4. memory_module's MEM_ADDR_WIDTH parameter defaults to a fixed 4,
//     while antenna_selector derives its width from
//     $clog2(NUM_ANTENNAS). This module explicitly overrides
//     MEM_ADDR_WIDTH to $clog2(NUM_ANTENNAS) at instantiation so the
//     two can never silently drift apart if NUM_ANTENNAS changes.
//  5. Port names uart_rx_serial / uart_tx_serial are used here
//     instead of uart_rx / uart_tx (as in the original skeleton) to
//     avoid a port name colliding with a module type name of the
//     same name. Purely cosmetic — flagging it since it is a change
//     from the originally agreed interface.
// ============================================================
module top_module #(
    parameter NUM_ANTENNAS   = 16,
    parameter ADC_DATA_WIDTH = 12,
    parameter CLK_FREQ_HZ    = 50_000_000,
    parameter BAUD_RATE      = 9600
)(
    input  wire                            clk,
    input  wire                            rst_n,
    input  wire                            uart_rx_serial,   // PC -> board
    input  wire [ADC_DATA_WIDTH-1:0]       adc_data_in,      // from external ADC pins
    input  wire                            adc_eoc,          // from external ADC
    output wire                            uart_tx_serial,   // board -> PC
    output wire [$clog2(NUM_ANTENNAS)-1:0] antenna_sel,
    output wire [NUM_ANTENNAS-1:0]         switch_control,
    output wire                            adc_trigger
);

    localparam SEL_WIDTH = $clog2(NUM_ANTENNAS);

    // ---- inter-module wires ----
    wire        start_cmd, reset_cmd;
    wire [7:0]  rx_byte;
    wire        rx_valid;
    wire        antenna_inc, switch_en, adc_start, mem_write_en, send_uart_en, busy;
    wire        all_antennas_done;
    wire        adc_data_valid;
    wire [ADC_DATA_WIDTH-1:0] adc_sample;
    wire [ADC_DATA_WIDTH-1:0] mem_data_out;
    wire        tx_busy;
    reg  [7:0]  tx_data;
    reg         tx_start;

    // ==================== UART RX (Kyrillos) ====================
    uart_rx #(.CLK_FREQ_HZ(CLK_FREQ_HZ), .BAUD_RATE(BAUD_RATE)) u_uart_rx (
        .clk          (clk),
        .rst_n        (rst_n),
        .rx_serial_in (uart_rx_serial),
        .rx_byte      (rx_byte),
        .rx_valid     (rx_valid),
        .start_cmd    (start_cmd),
        .reset_cmd    (reset_cmd)
    );

    // ==================== FSM (Marwan) ====================
    fsm_controller u_fsm (
        .clk               (clk),
        .rst_n             (rst_n),
        .start_cmd         (start_cmd),
        .adc_data_ready    (adc_data_valid),
        .last_antenna_flag (all_antennas_done),
        .antenna_inc       (antenna_inc),
        .switch_en         (switch_en),
        .adc_start         (adc_start),
        .mem_write_en      (mem_write_en),
        .send_uart_en      (send_uart_en),
        .busy              (busy)
    );

    // ==================== Antenna Selector (Kareem Galal) ====================
    antenna_selector #(.NUM_ANTENNAS(NUM_ANTENNAS)) u_antenna_selector (
        .clk               (clk),
        .rst_n             (rst_n),
        .enable            (antenna_inc),
        .antenna_sel       (antenna_sel),
        .all_antennas_done (all_antennas_done)
    );

    // ==================== Switch Controller (Kareem Galal) ====================
    switch_controller #(.NUM_ANTENNAS(NUM_ANTENNAS)) u_switch_controller (
        .antenna_sel    (antenna_sel),
        .switch_en      (switch_en),
        .switch_control (switch_control)
    );

    // ==================== ADC Controller (Mohamed) ====================
    adc_controller #(.ADC_DATA_WIDTH(ADC_DATA_WIDTH)) u_adc_controller (
        .clk              (clk),
        .rst_n            (rst_n),
        .start_conversion (adc_start),
        .adc_data_in      (adc_data_in),
        .eoc              (adc_eoc),
        .adc_trigger      (adc_trigger),
        .data_out         (adc_sample),
        .data_valid       (adc_data_valid)
    );

    // ==================== Send sequencer (integration glue — new) ====================
    // Streams the NUM_ANTENNAS stored measurements out over UART TX,
    // 2 bytes each (high byte then low byte), once triggered by a
    // send_uart_en pulse from the FSM.
    localparam SQ_IDLE      = 3'd0;
    localparam SQ_READ_WAIT = 3'd1;
    localparam SQ_SEND_HI   = 3'd2;
    localparam SQ_HI_RISE   = 3'd3;
    localparam SQ_HI_FALL   = 3'd4;
    localparam SQ_SEND_LO   = 3'd5;
    localparam SQ_LO_RISE   = 3'd6;
    localparam SQ_LO_FALL   = 3'd7;

    reg [2:0]           sq_state;
    reg                  sending;
    reg [SEL_WIDTH-1:0]  send_addr;

    wire [SEL_WIDTH-1:0] mem_addr_mux = sending ? send_addr : antenna_sel;
    wire [7:0] hi_byte = {{(16-ADC_DATA_WIDTH){1'b0}}, mem_data_out[ADC_DATA_WIDTH-1:8]};
    wire [7:0] lo_byte = mem_data_out[7:0];

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sq_state  <= SQ_IDLE;
            sending   <= 1'b0;
            send_addr <= {SEL_WIDTH{1'b0}};
            tx_start  <= 1'b0;
            tx_data   <= 8'd0;
        end else begin
            tx_start <= 1'b0;
            case (sq_state)
                SQ_IDLE: begin
                    sending <= 1'b0;
                    if (send_uart_en) begin
                        sending   <= 1'b1;
                        send_addr <= {SEL_WIDTH{1'b0}};
                        sq_state  <= SQ_READ_WAIT;
                    end
                end

                // one cycle for memory_module's registered read to settle
                SQ_READ_WAIT: sq_state <= SQ_SEND_HI;

                SQ_SEND_HI: begin
                    if (!tx_busy) begin
                        tx_data  <= hi_byte;
                        tx_start <= 1'b1;
                        sq_state <= SQ_HI_RISE;
                    end
                end
                SQ_HI_RISE: if (tx_busy) sq_state <= SQ_HI_FALL;
                SQ_HI_FALL: if (!tx_busy) sq_state <= SQ_SEND_LO;

                SQ_SEND_LO: begin
                    if (!tx_busy) begin
                        tx_data  <= lo_byte;
                        tx_start <= 1'b1;
                        sq_state <= SQ_LO_RISE;
                    end
                end
                SQ_LO_RISE: if (tx_busy) sq_state <= SQ_LO_FALL;
                SQ_LO_FALL: begin
                    if (!tx_busy) begin
                        if (send_addr == NUM_ANTENNAS - 1) begin
                            sq_state <= SQ_IDLE;             // all antennas sent
                        end else begin
                            send_addr <= send_addr + 1'b1;
                            sq_state  <= SQ_READ_WAIT;
                        end
                    end
                end

                default: sq_state <= SQ_IDLE;
            endcase
        end
    end

    // ==================== Memory Module (Mohamed) ====================
    memory_module #(
        .MEM_ADDR_WIDTH (SEL_WIDTH),
        .MEM_DATA_WIDTH (ADC_DATA_WIDTH),
        .NUM_ANTENNAS   (NUM_ANTENNAS)
    ) u_memory (
        .clk      (clk),
        .write_en (mem_write_en),
        .address  (mem_addr_mux),
        .data_in  (adc_sample),
        .data_out (mem_data_out)
    );

    // ==================== UART TX (Kyrillos) ====================
    uart_tx #(.CLK_FREQ_HZ(CLK_FREQ_HZ), .BAUD_RATE(BAUD_RATE)) u_uart_tx (
        .clk           (clk),
        .rst_n         (rst_n),
        .tx_data       (tx_data),
        .tx_start      (tx_start),
        .tx_serial_out (uart_tx_serial),
        .tx_busy       (tx_busy)
    );

endmodule

`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Module Name : top_module_tb
// Author      : Kareem Elnashar
// Description : Full-system integration testbench for the real modules
//               delivered by the team. Drives a real UART "START" byte
//               (0x53) into uart_rx_serial exactly as the PC would,
//               acts as the external ADC (replies to adc_trigger with
//               a known per-antenna value + eoc pulse), and then checks:
//                 1) memory ends up holding the expected value for
//                    every antenna
//                 2) switch_control is one-hot and matches antenna_sel
//                    whenever switch_en is asserted (continuous monitor)
//                 3) the send sequencer streams the correct
//                    high-byte/low-byte pair for every antenna out of
//                    uart_tx_serial (decoded here with a bit-banged
//                    UART receiver model)
//										
//////////////////////////////////////////////////////////////////////////////////
module top_module_tb;

    localparam NUM_ANTENNAS   = 16;
    localparam ADC_DATA_WIDTH = 12;
    localparam CLK_FREQ_HZ    = 80;
    localparam BAUD_RATE      = 10;
    localparam CLKS_PER_BIT   = CLK_FREQ_HZ / BAUD_RATE;
    localparam SEL_WIDTH      = $clog2(NUM_ANTENNAS);

    reg                       clk;
    reg                       rst_n;
    reg                       uart_rx_serial;
    reg  [ADC_DATA_WIDTH-1:0] adc_data_in;
    reg                       adc_eoc;
    wire                      uart_tx_serial;
    wire [SEL_WIDTH-1:0]      antenna_sel;
    wire [NUM_ANTENNAS-1:0]   switch_control;
    wire                      adc_trigger;

    integer error_count = 0;
    integer i;
    reg [ADC_DATA_WIDTH-1:0] exp_val;

    top_module #(
        .NUM_ANTENNAS  (NUM_ANTENNAS),
        .ADC_DATA_WIDTH(ADC_DATA_WIDTH),
        .CLK_FREQ_HZ   (CLK_FREQ_HZ),
        .BAUD_RATE     (BAUD_RATE)
    ) dut (
        .clk            (clk),
        .rst_n          (rst_n),
        .uart_rx_serial (uart_rx_serial),
        .adc_data_in    (adc_data_in),
        .adc_eoc        (adc_eoc),
        .uart_tx_serial (uart_tx_serial),
        .antenna_sel    (antenna_sel),
        .switch_control (switch_control),
        .adc_trigger    (adc_trigger)
    );

    // ---- clock: 20ns period ----
    initial begin
        clk = 0;
        forever #10 clk = ~clk;
    end

    // ---- expected value per antenna (unique, fits in 12 bits) ----
    function [ADC_DATA_WIDTH-1:0] expected_value;
        input [SEL_WIDTH-1:0] idx;
        begin
            expected_value = idx * 20 + 100;
        end
    endfunction

    // ---- bit-bangs one UART byte (LSB first) onto uart_rx_serial ----
    task uart_send_byte(input [7:0] data);
        integer b;
        begin
            uart_rx_serial = 1'b0;                       // start bit
            repeat (CLKS_PER_BIT) @(posedge clk);
            for (b = 0; b < 8; b = b + 1) begin
                uart_rx_serial = data[b];
                repeat (CLKS_PER_BIT) @(posedge clk);
            end
            uart_rx_serial = 1'b1;                        // stop bit
            repeat (CLKS_PER_BIT) @(posedge clk);
        end
    endtask

    // ---- acts as the external ADC ----
    initial begin
        adc_data_in = 0;
        adc_eoc     = 0;
        forever begin
            @(posedge adc_trigger);
            @(posedge clk);
            adc_data_in <= expected_value(antenna_sel);
            repeat (3) @(posedge clk);
            adc_eoc <= 1'b1;
            @(posedge clk);
            adc_eoc <= 1'b0;
        end
    end

    // ---- background monitor: switch_control must be one-hot and
    //      match antenna_sel whenever switch_en is asserted ----
    always @(posedge clk) begin
        if (rst_n && dut.switch_en) begin
            if (switch_control !== ({{(NUM_ANTENNAS-1){1'b0}}, 1'b1} << antenna_sel)) begin
                $display("ERROR [%0t]: switch_control=%b does not match one-hot(antenna_sel=%0d)",
                          $time, switch_control, antenna_sel);
                error_count = error_count + 1;
            end
        end
    end

    // ---- bit-bangs a UART receiver model for uart_tx_serial and
    //      stores every decoded byte for later comparison ----
    reg [7:0] rx_bytes [0:63];
    integer   rx_count;

    task capture_uart_byte;
        integer b;
        reg [7:0] byte_val;
        begin
            @(negedge uart_tx_serial);                          // start bit begins
            repeat (CLKS_PER_BIT + CLKS_PER_BIT/2) @(posedge clk); // reach middle of bit0
            for (b = 0; b < 8; b = b + 1) begin
                byte_val[b] = uart_tx_serial;
                repeat (CLKS_PER_BIT) @(posedge clk);           // advance to middle of next bit
            end
            rx_bytes[rx_count] = byte_val;
            rx_count = rx_count + 1;
        end
    endtask

    initial begin
        rx_count = 0;
        forever capture_uart_byte;
    end

    // ---- main test sequence ----
    initial begin
        uart_rx_serial = 1'b1;   // idle line
        rst_n = 0;
        repeat (5) @(posedge clk);
        rst_n = 1;
        repeat (5) @(posedge clk);
        $display("[%0t] Reset released, sending START (0x53)", $time);

        uart_send_byte(8'h53);   // CMD_START

        // give the full sweep + full transmission time to finish
        repeat (NUM_ANTENNAS * (10 * CLKS_PER_BIT * 2 + 200)) @(posedge clk);

        // ---- check memory contents ----
        for (i = 0; i < NUM_ANTENNAS; i = i + 1) begin
            if (dut.u_memory.ram[i] !== expected_value(i)) begin
                $display("ERROR: memory[%0d] = %0d, expected %0d",
                          i, dut.u_memory.ram[i], expected_value(i));
                error_count = error_count + 1;
            end
        end

        // ---- check the bytes that came out over UART TX ----
        if (rx_count < NUM_ANTENNAS * 2) begin
            $display("ERROR: only received %0d bytes over UART TX, expected %0d",
                      rx_count, NUM_ANTENNAS * 2);
            error_count = error_count + 1;
        end else begin
            for (i = 0; i < NUM_ANTENNAS; i = i + 1) begin
                exp_val = expected_value(i);
                if (rx_bytes[2*i] !== {{(16-ADC_DATA_WIDTH){1'b0}}, exp_val[ADC_DATA_WIDTH-1:8]}) begin
                    $display("ERROR: UART high byte for antenna %0d wrong: got %0d", i, rx_bytes[2*i]);
                    error_count = error_count + 1;
                end
                if (rx_bytes[2*i+1] !== exp_val[7:0]) begin
                    $display("ERROR: UART low byte for antenna %0d wrong: got %0d", i, rx_bytes[2*i+1]);
                    error_count = error_count + 1;
                end
            end
        end

        if (error_count == 0)
            $display(">>> FULL-SYSTEM INTEGRATION TEST: SUCCESSFULLY (0 errors)");
        else
            $display(">>> FULL-SYSTEM INTEGRATION TEST: FAILED (%0d errors)", error_count);

        $stop;
    end

endmodule

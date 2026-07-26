`timescale 1ns / 1ps
//============================================================
// Module      : switch_controller
// Author      : Kareem Galal
// Description : Decodes antenna_sel into a one-hot pattern, gated by switch_en
// ============================================================


/*acts as a combinational decoder. It takes the binary antenna index 
and converts it into a one-hot encoded signal. If switch_en is low, all 
outputs are forced to zero to prevent any RF signal leakage.*/

module switch_controller  #(parameter NUM_ANTENNAS=16)(     
input wire [$clog2(NUM_ANTENNAS)-1:0] antenna_sel, // received from antenna_selector
input wire switch_en, // received from fsm
output reg [NUM_ANTENNAS-1:0] switch_control // sended to RF hardware
    );

// Combinational logic for the decoder
always @(*) begin
if (switch_en) begin
// Shift '1' to the left by the value of antenna_sel
switch_control = 1'b1 << antenna_sel; 
end
else begin
switch_control = 0; 
end
end
endmodule
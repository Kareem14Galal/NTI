`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/09/2026 05:16:56 PM
// Design Name: 
// Module Name: sheif_register
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module sheif_register #(parameter N=8)(
    input wire clk, rst_n, shift_en, serial_in,  
    output reg [N-1:0] parallel_out
    );
    
always @(posedge clk or negedge rst_n) begin
    if (~rst_n)
        parallel_out <= 'b0 ;
    else if (shift_en)
        parallel_out <= {parallel_out[N-2:0], serial_in} ;
end
endmodule

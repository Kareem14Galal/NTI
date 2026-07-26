`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/11/2026 05:23:37 PM
// Design Name: 
// Module Name: FULL_ADDER_B
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


module FULL_ADDER_B(
input A , B , Cin ,
output reg sum , carry 
    );
    
always@(*) begin
case({A,B,Cin})
3'b000 : {carry, sum} = 2'b00;
3'b001 : {carry, sum} = 2'b10;
3'b010 : {carry, sum} = 2'b10;
3'b011 : {carry, sum} = 2'b01;
3'b100 : {carry, sum} = 2'b10;
3'b101 : {carry, sum} = 2'b01;
3'b110 : {carry, sum} = 2'b01;
3'b111 : {carry, sum} = 2'b11;
endcase
end    
endmodule

`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/06/2026 10:14:12 PM
// Design Name: 
// Module Name: Q1
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


module lab_1_Q1(
input A ,B ,Cin , 
output S ,Cout
    );
    
wire Z1 , Z2 , Z3;
assign Z1 = A^B;
assign Z2 = A&B;
assign Z3 = Z1 & Cin;
assign S = Z1 ^ Cin;
assign Cout =  Z3 | Z2 ;
   
endmodule

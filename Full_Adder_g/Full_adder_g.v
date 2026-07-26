`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/11/2026 05:32:38 PM
// Design Name: 
// Module Name: Full_adder_g
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


module Full_adder_g(
input A , B , Cin ,
output sum , carry 
    );

wire w1 , w2 , w3;
xor(w1,A,B);
xor(sum,Cin,w1);
and(w2,A,B);
and(w3,w1,Cin);
or(carry,w2,w3);
    
endmodule

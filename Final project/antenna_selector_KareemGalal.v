`timescale 1ns / 1ps
//============================================================
// Module      : antenna_selector
// Author      : Kareem Galal
// Description : Increments antenna selection and flags when done
// ============================================================

// I use only NUM_ANTENNAS as paramter and use log function instead of using ANTENNA_SEL_WIDTH


/*This part of the code takes the enable as a pulse, meaning whoever 
writes the FSM code must take into account that with each antenna they 
raise and lower the enable for a clock duration in order for the system 
to pick it up (we will need to adjust the timing).*/

module antenna_selector  #(parameter NUM_ANTENNAS=16)(     
input wire clk ,
input wire rst_n, //recived from fsm
input wire enable, //recived from fsm
output reg [$clog2(NUM_ANTENNAS)-1:0] antenna_sel, 
output wire all_antennas_done //sended to fsm
    );
reg enable_d;
//     
always@(posedge clk or negedge rst_n) begin
if (~rst_n)begin
        antenna_sel <= 0;
        enable_d    <= 1'b0;
    end
    else begin 
         enable_d <= enable;
         if (enable == 1'b1 && enable_d == 1'b0)  
            antenna_sel <= antenna_sel + 1;      
end
end
assign all_antennas_done = (antenna_sel == NUM_ANTENNAS-1)? 1'b1:1'b0; /*all antennas done then rise 
reset to make all of them zeros and start again  */
endmodule

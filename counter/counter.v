`timescale 1ns / 1ps

module dff (
    input d,
    input clk,
    input rst,
    output reg q
);
    always @(posedge clk or posedge rst) begin
        if (rst) 
            q <= 1'b0;
        else 
            q <= d;
    end
endmodule

module counter_structural (
    input clock,
    input reset,
    input up,
    output [1:0] count
);
    wire d0, d1;
    wire not_q0, not_up, up_and_q0, not_up_and_not_q0, toggle_cond;
    
    not u1 (not_q0, count[0]);
    not u2 (not_up, up);
    and u3 (up_and_q0, up, count[0]);
    and u4 (not_up_and_not_q0, not_up, not_q0);
    or  u5 (toggle_cond, up_and_q0, not_up_and_not_q0);
    xor u6 (d1, count[1], toggle_cond);
    
    dff ff0 (.d(not_q0), .clk(clock), .rst(reset), .q(count[0]));
    dff ff1 (.d(d1), .clk(clock), .rst(reset), .q(count[1]));

endmodule
`timescale 1ns / 1ps

module counter_gate (
    input clock,
    input reset,
    input up,
    output reg [1:0] count
);

    wire d0, d1;
    wire not_q0, not_up, up_and_q0, not_up_and_not_q0, toggle_cond;

    not (not_q0, count[0]);
    not (not_up, up);
    and (up_and_q0, up, count[0]);
    and (not_up_and_not_q0, not_up, not_q0);
    or (toggle_cond, up_and_q0, not_up_and_not_q0);
    xor (d1, count[1], toggle_cond);
    
    always @(posedge clock or posedge reset) begin
        if (reset) begin
            count[0] <= 1'b0;
            count[1] <= 1'b0;
        end else begin
            count[0] <= not_q0;
            count[1] <= d1;
        end
    end

endmodule
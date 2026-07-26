`timescale 1ns / 1ps

module counter_behavioral (
    input clock,
    input reset,
    input up,
    output reg [1:0] count
);

    always @(posedge clock or posedge reset) begin
        if (reset)
            count <= 2'b00;
        else if (up)
            count <= count + 1'b1;
        else
            count <= count - 1'b1;
    end

endmodule
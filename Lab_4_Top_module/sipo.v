`timescale 1ns / 1ps

module sipo_reg #(parameter WIDTH = 20)(
    input clk,
    input rst_n,
    input shift_en,
    input serial_in,
    output reg [WIDTH-1:0] parallel_out
);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            parallel_out <= {WIDTH{1'b0}};
        else if (shift_en)
            parallel_out <= {parallel_out[WIDTH-2:0], serial_in};
    end

endmodule
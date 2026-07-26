`timescale 1ns / 1ps

module Lab_7_register #(parameter WIDTH = 8)(
    input [WIDTH-1:0] data_in,
    input load,
    input clk,
    input rst,
    output reg [WIDTH-1:0] data_out
);

    always @(posedge clk) begin
        if (rst) begin
            data_out <= {WIDTH{1'b0}};
        end
        else if (load) begin
            data_out <= data_in;
        end
    end

endmodule
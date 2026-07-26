`timescale 1ns / 1ps

module Lab_5_alu #(parameter WIDTH = 8)(
    input  [WIDTH-1:0] in_a,
    input  [WIDTH-1:0] in_b,
    input  [2:0] opcode,
    output reg [WIDTH-1:0] alu_out,
    output a_is_zero
);

    assign a_is_zero = (in_a == {WIDTH{1'b0}}) ? 1'b1 : 1'b0;

    always @(*) begin
        case (opcode)
            3'b000: alu_out = in_a;
            3'b001: alu_out = in_a;
            3'b010: alu_out = in_a + in_b;
            3'b011: alu_out = in_a & in_b;
            3'b100: alu_out = in_a ^ in_b;
            3'b101: alu_out = in_b;
            3'b110: alu_out = in_a;
            3'b111: alu_out = in_a;
            default: alu_out = {WIDTH{1'b0}};
        endcase
    end

endmodule
`timescale 1ns / 1ps

module fsm (
    input clk,
    input rst,
    input a,
    input b,
    output reg y1,
    output reg y0
);

    localparam  s0 = 2'b00;
    localparam s1 = 2'b01;
    localparam s2 = 2'b10;

    reg [1:0] state, next_state;

    always @(posedge clk or posedge rst) begin
        if (rst)
            state <= s0;
        else
            state <= next_state;
    end

    always @(*) begin
        next_state = state;
        
        case (state)
            s0: begin
                if (!a) begin
                    next_state = s0;
                end else if (a && b) begin
                    next_state = s2;
                end else begin
                    next_state = s1;
                end
            end
            s1: begin
                if (!a) begin
                    next_state = s1;
                end else begin
                    next_state = s0;
                end
            end
            s2: begin
                next_state = s0;
            end
            default: begin
                next_state = s0;
            end
        endcase
    end

    always @(*) begin
        y1 = 1'b0;
        y0 = 1'b0;

        case (state)
            s0: begin
                y1 = 1'b1;
                if (a && b) begin
                    y0 = 1'b1;
                end
            end
            s1: begin
                y1 = 1'b1;
            end
            s2: begin
                y1 = 1'b0;
                y0 = 1'b0;
            end
            default: begin
                y1 = 1'b0;
                y0 = 1'b0;
            end
        endcase
    end

endmodule
`timescale 1ns / 1ps

module piso_reg #(parameter WIDTH = 20, ADDR_WIDTH = 8)(
    input clk,
    input rst_n,
    input [WIDTH-1:0] parallel_in,
    output reg en,
    output reg [ADDR_WIDTH-1:0] addr,
    output reg serial_out,
    output reg valid
);

    reg [WIDTH-1:0] shift_reg;
    reg [4:0] count;
    reg [1:0] state;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            en <= 0;
            addr <= 0;
            serial_out <= 0;
            valid <= 0;
            count <= 0;
            state <= 0;
            shift_reg <= 0;
        end else begin
            case (state)
                2'd0: begin
                    en <= 1;
                    valid <= 0;
                    serial_out <= 0;
                    state <= 2'd1;
                end
                2'd1: begin
                    en <= 0;
                    shift_reg <= parallel_in;
                    count <= WIDTH - 1;
                    state <= 2'd2;
                end
                2'd2: begin
                    valid <= 1;
                    serial_out <= shift_reg[WIDTH-1];
                    shift_reg <= {shift_reg[WIDTH-2:0], 1'b0};
                    if (count == 0)
                        state <= 2'd3;
                    else
                        count <= count - 1;
                end
                2'd3: begin
                    valid <= 0;
                    serial_out <= 0;
                    addr <= addr + 1;
                    state <= 2'd0;
                end
                default: state <= 2'd0;
            endcase
        end
    end

endmodule
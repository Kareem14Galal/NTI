`timescale 1ns / 1ps

module ram #(parameter ADDR_WIDTH = 8, DATA_WIDTH = 20)(
    input clk,
    input rst_n,
    input wr_en,
    input [ADDR_WIDTH-1:0] addr,
    input [DATA_WIDTH-1:0] din,
    input rd_en,
    output reg [DATA_WIDTH-1:0] dout,
    output reg valid
);

    reg [DATA_WIDTH-1:0] mem [0:(1<<ADDR_WIDTH)-1];

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            dout <= {DATA_WIDTH{1'b0}};
            valid <= 1'b0;
        end else begin
            if (wr_en)
                mem[addr] <= din;
            if (rd_en)
                dout <= mem[addr];
            valid <= rd_en;
        end
    end

endmodule
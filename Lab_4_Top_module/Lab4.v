`timescale 1ns / 1ps

module Lab_4_top_module #(
    parameter ADDR_WIDTH = 8,
    parameter DATA_WIDTH = 20,
    parameter ALU_WIDTH = 8
)(
    input clk,
    input rst_n,
    input wr_en,
    input [ADDR_WIDTH-1:0] ext_addr,
    input [DATA_WIDTH-1:0] ext_din,
    output [ALU_WIDTH-1:0] alu_out,
    output a_is_zero
);

    wire [DATA_WIDTH-1:0] ram_dout;
    wire ram_valid;
    
    wire piso_en;
    wire [ADDR_WIDTH-1:0] piso_addr;
    wire serial_data;
    wire shift_valid;
    
    wire [DATA_WIDTH-1:0] parallel_data;

    ram #(.ADDR_WIDTH(ADDR_WIDTH), .DATA_WIDTH(DATA_WIDTH)) u_ram (
        .clk(clk),
        .rst_n(rst_n),
        .wr_en(wr_en),
        .addr(wr_en ? ext_addr : piso_addr),
        .din(ext_din),
        .rd_en(piso_en),
        .dout(ram_dout),
        .valid(ram_valid)
    );

    piso_reg #(.WIDTH(DATA_WIDTH), .ADDR_WIDTH(ADDR_WIDTH)) u_piso (
        .clk(clk),
        .rst_n(rst_n),
        .parallel_in(ram_dout),
        .en(piso_en),
        .addr(piso_addr),
        .serial_out(serial_data),
        .valid(shift_valid)
    );

    sipo_reg #(.WIDTH(DATA_WIDTH)) u_sipo (
        .clk(clk),
        .rst_n(rst_n),
        .shift_en(shift_valid),
        .serial_in(serial_data),
        .parallel_out(parallel_data)
    );

    alu #(.N(ALU_WIDTH)) u_alu (
        .in_a(parallel_data[15:8]),
        .in_b(parallel_data[7:0]),
        .opcode(parallel_data[18:16]),
        .alu_en(parallel_data[19]),
        .alu_out(alu_out),
        .a_is_zero(a_is_zero)
    );

endmodule
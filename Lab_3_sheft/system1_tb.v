`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 07/09/2026 05:48:58 PM
// Design Name: 
// Module Name: system1_tb
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module Lab_3_sheft #(parameter N=20)(
    );
reg clk, rst_n, shift_en, serial_in  ;
wire [N-1:0] parallel_out;
wire [7:0] alu_out;

sheif_register #(.N(20)) sheift (
.clk(clk),
.rst_n(rst_n),
.shift_en(shift_en),
.serial_in(serial_in),
.parallel_out(parallel_out)
);   

alu #(.N(8)) alu (
.in_a(parallel_out[15:8]),
.in_b(parallel_out[7:0]),
.opcode(parallel_out[18:16]),
.alu_en(parallel_out[19]),
.alu_out(alu_out)
);

always #5 clk = ~clk;

task send_data;
        input [19:0] data_word;
        integer i;
        begin
            shift_en = 1;
            
            for (i = 19; i >= 0; i = i - 1) begin
                serial_in = data_word[i];
                #10; 
            end
            shift_en = 0; 
            #20;          
        end
    endtask

    initial begin
  
        clk = 0;
        shift_en = 0;
        serial_in = 0;
        
        rst_n = 0;
        #10;
        rst_n = 1; 


        send_data(20'b1_000_00000101_00000011);

        send_data(20'b1_001_00001010_00000100);

  
        send_data(20'b1_010_00000000_00001111);


        send_data(20'b0_000_00000111_00000001);

   
        $display("All Test Cases Finished!");
        $finish; 
    end


endmodule

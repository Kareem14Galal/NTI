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
            // بنبدأ من البت رقم 19 (MSB) لحد البت رقم 0
            for (i = 19; i >= 0; i = i - 1) begin
                serial_in = data_word[i];
                #10; // بنستنى دورة كلوك كاملة لكل بت
            end
            shift_en = 0; // بنقفل الإزاحة بعد ما الـ 20 بت يخلصوا
            #20;          // بنستنى شوية عشان نتفرج على الناتج النهائي على الـ Waveform
        end
    endtask

    // =========================================================
    // بلوك الاختبار (Test Cases)
    // =========================================================
    initial begin
        // 1. تهيئة مبدئية وتفعيل الريسيت
        clk = 0;
        shift_en = 0;
        serial_in = 0;
        
        rst_n = 0;
        #10;
        rst_n = 1; // قفلنا الريسيت

        // 2. الاختبار الأول (عملية جمع ADD)
        // alu_en=1 | opcode=000 | in_a=00000101 (5) | in_b=00000011 (3)
        // الكلمة كاملة: 20'b1_000_00000101_00000011
        // الناتج المتوقع: alu_out = 8 (00001000)
        send_data(20'b1_000_00000101_00000011);

        // 3. الاختبار الثاني (عملية طرح SUB)
        // alu_en=1 | opcode=001 | in_a=00001010 (10) | in_b=00000100 (4)
        // الكلمة كاملة: 20'b1_001_00001010_00000100
        // الناتج المتوقع: alu_out = 6 (00000110)
        send_data(20'b1_001_00001010_00000100);

        // 4. الاختبار الثالث (اختبار الـ Zero Flag والـ AND)
        // alu_en=1 | opcode=010 | in_a=00000000 (0) | in_b=00001111 (15)
        // الناتج المتوقع: alu_out = 0, a_is_zero = 1
        send_data(20'b1_010_00000000_00001111);

        // 5. الاختبار الرابع (اختبار قفل الـ ALU)
        // alu_en=0 | opcode=000 | in_a=00000111 (7) | in_b=00000001 (1)
        // الناتج المتوقع: alu_out = 0 (لأن الـ alu_en مقفول)
        send_data(20'b0_000_00000111_00000001);

        // إنهاء المحاكاة
        $display("All Test Cases Finished!");
        $finish; 
    end


endmodule

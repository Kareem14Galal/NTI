`timescale 1ns / 1ps

module fsm_tb;

    reg clk;
    reg rst;
    reg a;
    reg b;

    wire y1;
    wire y0;

    fsm uut (
        .clk(clk),
        .rst(rst),
        .a(a),
        .b(b),
        .y1(y1),
        .y0(y0)
    );

    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    initial begin
        rst = 1;
        a = 0;
        b = 0;
        #20;
        
        rst = 0;
        
        a = 0;
        b = 0;
        #20;
        
        a = 1;
        b = 0;
        #10;
        
        a = 0;
        b = 0;
        #20;
        
        a = 1;
        b = 0;
        #10;
        
        a = 1;
        b = 1;
        #10;
        
        a = 0;
        b = 0;
        #20;
        
        a = 1;
        b = 1;
        #10;
        
        a = 1;
        b = 1;
        #20;
        
        rst = 1;
        #10;
        
        rst = 0;
        a = 1;
        b = 0;
        #20;
        
        $stop;
    end

endmodule
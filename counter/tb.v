`timescale 1ns / 1ps

module counter_tb;

    reg clock;
    reg reset;
    reg up;
    wire [1:0] count;
    
    counter_structural uut (
        .clock(clock),
        .reset(reset),
        .up(up),
        .count(count)
    );
    
    initial begin
        clock = 0;
        forever #5 clock = ~clock;
    end
    
    task apply_reset;
        begin
            reset = 1;
            #10;
            reset = 0;
        end
    endtask
    
    function [1:0] calc_next;
        input [1:0] current_val;
        input dir_up;
        begin
            if (dir_up) 
                calc_next = current_val + 1;
            else 
                calc_next = current_val - 1;
        end
    endfunction
    
    initial begin
        up = 1;
        apply_reset();
        
        #45;
        
        up = 0;
        
        #40;
        
        apply_reset();
        
        #20;
        
        $stop;
    end

endmodule
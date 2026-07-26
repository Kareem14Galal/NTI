`timescale 1ns / 1ps

module LAB_6_controller (
    input clk,
    input rst,
    input zero,
    input [2:0] opcode,
    input [2:0] phase,
    output reg sel,
    output reg rd,
    output reg ld_ir,
    output reg halt,
    output reg inc_pc,
    output reg ld_ac,
    output reg ld_pc,
    output reg wr,
    output reg data_e
);

    reg HLT, SKZ, ADD, AND, XOR, LDA, STO, JMP, ALU_OP;

    always @(*) begin
        HLT = (opcode == 3'b000);
        SKZ = (opcode == 3'b001);
        ADD = (opcode == 3'b010);
        AND = (opcode == 3'b011);
        XOR = (opcode == 3'b100);
        LDA = (opcode == 3'b101);
        STO = (opcode == 3'b110);
        JMP = (opcode == 3'b111);
        
        ALU_OP = ADD | AND | XOR | LDA;

        sel = 0;
        rd = 0;
        ld_ir = 0;
        halt = 0;
        inc_pc = 0;
        ld_ac = 0;
        ld_pc = 0;
        wr = 0;
        data_e = 0;

        case (phase)
            3'd0: begin
                sel = 0;
            end
            3'd1: begin
                sel = 1;
                rd = 1;
            end
            3'd2: begin
                sel = 1;
                rd = 1;
                ld_ir = 1;
            end
            3'd3: begin
                sel = 1;
                rd = 1;
                ld_ir = 1;
            end
            3'd4: begin
                halt = HLT;
                inc_pc = 1;
            end
            3'd5: begin
                rd = ALU_OP;
                data_e = STO;
            end
            3'd6: begin
                rd = ALU_OP;
                inc_pc = SKZ & zero;
                ld_pc = JMP;
                wr = STO;
                data_e = STO;
            end
            3'd7: begin
                rd = ALU_OP;
                ld_ac = ALU_OP;
                ld_pc = JMP;
                wr = STO;
                data_e = STO;
            end
            default: begin
                sel = 0;
                rd = 0;
                ld_ir = 0;
                halt = 0;
                inc_pc = 0;
                ld_ac = 0;
                ld_pc = 0;
                wr = 0;
                data_e = 0;
            end
        endcase
    end

endmodule
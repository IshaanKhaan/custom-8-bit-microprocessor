`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 22.11.2025 09:42:05
// Design Name: 
// Module Name: microprocessor_tb
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
module tb_debug();

    reg clk;
    reg rst;

    wire [1:0] dbg_state;
    wire [7:0] dbg_pc;
    wire [7:0] dbg_IR;
    wire [7:0] dbg_ALUOut;
    wire [7:0] dbg_r0, dbg_r1, dbg_r2, dbg_r3;

    processor DUT (
        .clk(clk),
        .rst(rst),
        .dbg_state(dbg_state),
        .dbg_pc(dbg_pc),
        .dbg_IR(dbg_IR),
        .dbg_ALUOut(dbg_ALUOut),
        .dbg_r0(dbg_r0),
        .dbg_r1(dbg_r1),
        .dbg_r2(dbg_r2),
        .dbg_r3(dbg_r3)
    );

    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    initial begin
        #1;
        $display("Program memory at start:");
        $display("pc0=%b pc1=%b pc2=%b pc3=%b pc4=%b",
            DUT.pm.instr,          // not reliable for hierarchical read but left for example
            DUT.pm.instr, DUT.pm.instr, DUT.pm.instr, DUT.pm.instr);
    end

    initial begin
        $dumpfile("cpu_debug.vcd");
        $dumpvars(0, tb_debug);
    end

    initial begin
        rst = 1;
        #25;
        rst = 0;
        #700;
        $display("Simulation done.");
        $finish;
    end

    function [127:0] opcode_name;
        input [2:0] op;
        begin
            case (op)
                3'b000: opcode_name = "ADD";
                3'b001: opcode_name = "SUB";
                3'b010: opcode_name = "AND";
                3'b011: opcode_name = "OR";
                3'b100: opcode_name = "MOV";
                default: opcode_name = "UNK";
            endcase
        end
    endfunction

    function [31:0] state_name;
        input [1:0] s;
        begin
            case (s)
                2'b00: state_name = "FETCH";
                2'b01: state_name = "DECD";
                2'b10: state_name = "EXEC";
                2'b11: state_name = "WB";
                default: state_name = "???";
            endcase
        end
    endfunction

    reg [2:0] opc;
    always @(posedge clk) begin
        opc = dbg_IR[7:5];

        $display("T=%4t | STATE=%s PC=%0d IR=0x%02h OPC=%s ALUOut=0x%02h | R0=0x%02h R1=0x%02h R2=0x%02h R3=0x%02h",
            $time,
            state_name(dbg_state),
            dbg_pc,
            dbg_IR,
            opcode_name(opc),
            dbg_ALUOut,
            dbg_r0, dbg_r1, dbg_r2, dbg_r3
        );
    end

endmodule

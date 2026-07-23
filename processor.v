`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Design Name: Custom 8-bit Microprocessor
// Description: Single-cycle-per-state 8-bit RISC-style processor.
//              4-stage FSM: FETCH -> DECODE -> EXEC -> WRITEBACK
// Create Date: 22.11.2025
//////////////////////////////////////////////////////////////////////////////////

module program_memory(
    input  [7:0] pc,
    output reg [7:0] instr
);
    always @(*) begin
        case (pc)
            8'd0: instr = 8'b100_00_01_0; // MOV R0 = R1
            8'd1: instr = 8'b000_00_10_0; // ADD R0 = R0 + R2
            8'd2: instr = 8'b001_11_00_0; // SUB R3 = R3 - R0
            8'd3: instr = 8'b011_01_11_0; // OR  R1 = R1 | R3
            8'd4: instr = 8'b010_10_01_0; // AND R2 = R2 & R1
            default: instr = 8'h00;
        endcase
    end
endmodule

module register_file(
    input  wire       clk,
    input  wire       write_en,
    input  wire [1:0] waddr,      // write address (rd)
    input  wire [1:0] raddr1,     // read address 1 (rd)
    input  wire [1:0] raddr2,     // read address 2 (rs)
    input  wire [7:0] wdata,
    output wire [7:0] rdata1,
    output wire [7:0] rdata2,
    // debug outputs (optional)
    output wire [7:0] dbg_r0,
    output wire [7:0] dbg_r1,
    output wire [7:0] dbg_r2,
    output wire [7:0] dbg_r3
);
    reg [7:0] regs [0:3];

    initial begin
        regs[0] = 8'hAA; // R0
        regs[1] = 8'h10; // R1
        regs[2] = 8'h05; // R2
        regs[3] = 8'h00; // R3
    end

    assign rdata1 = regs[raddr1];
    assign rdata2 = regs[raddr2];
    
    always @(posedge clk) begin
        if (write_en)
            regs[waddr] <= wdata;
    end

    assign dbg_r0 = regs[0];
    assign dbg_r1 = regs[1];
    assign dbg_r2 = regs[2];
    assign dbg_r3 = regs[3];

endmodule

module alu(
    input  wire [7:0] A,
    input  wire [7:0] B,
    input  wire [2:0] opcode,
    output reg  [7:0] result
);
    always @(*) begin
        case (opcode)
            3'b000: result = A + B;   // ADD
            3'b001: result = A - B;   // SUB
            3'b010: result = A & B;   // AND
            3'b011: result = A | B;   // OR
            3'b100: result = B;       // MOV (rd = rs)
            default: result = 8'h00;
        endcase
    end
endmodule

module control_unit(
    input  wire       clk,
    input  wire       rst,
    output reg        pc_en,
    output reg        ir_en,
    output reg        ex_en,
    output reg        reg_write,
    output reg [1:0]  state_out   
);
    localparam [1:0] FETCH  = 2'b00;
    localparam [1:0] DECODE = 2'b01;
    localparam [1:0] EXEC   = 2'b10;
    localparam [1:0] WRITEB = 2'b11;

    reg [1:0] state;

    always @(posedge clk or posedge rst) begin
        if (rst) state <= FETCH;
        else begin
            case (state)
                FETCH:  state <= DECODE;
                DECODE: state <= EXEC;
                EXEC:   state <= WRITEB;
                WRITEB: state <= FETCH;
                default: state <= FETCH;
            endcase
        end
    end

    always @(*) begin
        // default
        pc_en     = 1'b0;
        ir_en     = 1'b0;
        ex_en     = 1'b0;
        reg_write = 1'b0;

        case (state)
            FETCH: begin
                pc_en = 1'b1;
                ir_en = 1'b1;
            end
            DECODE: begin
               
            end
            EXEC: begin
                ex_en = 1'b1;
            end
            WRITEB: begin
                reg_write = 1'b1;
            end
            default: begin end
        endcase
    end

    always @(*) state_out = state;

endmodule

module processor(
    input  wire       clk,
    input  wire       rst,      
  
    output wire [1:0] dbg_state,
    output wire [7:0] dbg_pc,
    output wire [7:0] dbg_IR,
    output wire [7:0] dbg_ALUOut,
    output wire [7:0] dbg_r0,
    output wire [7:0] dbg_r1,
    output wire [7:0] dbg_r2,
    output wire [7:0] dbg_r3
);

    reg [7:0] pc;
    reg [7:0] IR;
    reg [7:0] ALUOut;       

    wire pc_en, ir_en, ex_en, reg_write;
    wire [1:0] cu_state;

    wire [2:0] opcode;
    wire [1:0] rd, rs;

  
    wire [7:0] instr;
    wire [7:0] rf_rd, rf_rs;
    wire [7:0] alu_out;

 
    program_memory pm (
        .pc(pc),
        .instr(instr)
    );

    control_unit cu (
        .clk(clk),
        .rst(rst),
        .pc_en(pc_en),
        .ir_en(ir_en),
        .ex_en(ex_en),
        .reg_write(reg_write),
        .state_out(cu_state)
    );

    assign opcode = IR[7:5];
    assign rd     = IR[4:3];
    assign rs     = IR[2:1];

 
    register_file rf (
        .clk(clk),
        .write_en(reg_write),
        .waddr(rd),
        .raddr1(rd),
        .raddr2(rs),
        .wdata(ALUOut),
        .rdata1(rf_rd),
        .rdata2(rf_rs),
        .dbg_r0(dbg_r0),
        .dbg_r1(dbg_r1),
        .dbg_r2(dbg_r2),
        .dbg_r3(dbg_r3)
    );

    // ALU
    alu the_alu (
        .A(rf_rd),
        .B(rf_rs),
        .opcode(opcode),
        .result(alu_out)
    );

   
    always @(posedge clk or posedge rst) begin
        if (rst) IR <= 8'h00;
        else if (ir_en) IR <= instr;
    end

  
    always @(posedge clk or posedge rst) begin
        if (rst) pc <= 8'h00;
        else if (pc_en) pc <= pc + 1'b1;
    end

  
    always @(posedge clk or posedge rst) begin
        if (rst) ALUOut <= 8'h00;
        else if (ex_en) ALUOut <= alu_out;
    end

  
    assign dbg_state  = cu_state;
    assign dbg_pc     = pc;
    assign dbg_IR     = IR;
    assign dbg_ALUOut = ALUOut;

endmodule

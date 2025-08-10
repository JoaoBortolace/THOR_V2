/*
    THOR-V2: RISC-V RV32(I/E)MA pipeline CPU 
*/
module THOR_V2 #(
    parameter XLEN = 32,            // Width of GPR (32 or 64)
    parameter NUM_REG = 32,         // Nuumber of GPR (16 or 32)
    parameter SRAM_SIZE = 4096,     // Size of SRAM in bytes
    parameter ROM_SIZE  = 4096,     // Size of ROM in bytes
    parameter PREDITOR_DEPTH = 128,
    parameter BTB_DEPTH = 128,
    parameter QUEUE_DEPTH = 16
)(
    input clock,
    input resetn,                   // Asynchronous reset on low level
    // Instruction BUS
    output iMemEn,                  // Enable for instruction memory
    output [XLEN-1:0] iAddr,        // Address of current instruction to be fetched
    input  [XLEN-1:0] iData,        // Instruction Data
    // Data BUS
    output dMemEn,                  // Enable for instruction memory
    output dMemCmd,                 // Read / Write command
    output [XLEN-1:0] dAddr,        // Address of data to be loaded/stored
    input  [XLEN-1:0] dData,        // Data content
    // Interrupt
    input  interruptRequest,
    input  [XLEN-1:0] handlerAddr,  // Address of interrupt handler
    output interruptTaken           // Interrupt accepted
);
    //================================
    // Fetch Stage
    //================================

    wire flushQueue;
    wire bufferEmpty;
    wire bufferFull;
    wire push;
    wire [29:0] instr;
    wire pop;
    wire [29:0] instrA;
    wire [29:0] instrB;

    wire redirectBranch;
    wire [XLEN-1:0] redirectTarget;

    IF_STAGE #(
        .XLEN(XLEN),
        .PREDITOR_DEPTH(PREDITOR_DEPTH),
        .BTB_DEPTH(BTB_DEPTH)
    ) F1 (
        .clock(clock),
        .resetn(resetn),
        .iMemEn(iMemEn),
        .iAddr(iAddr),
        .iData(iData),
        .bufferFull(bufferFull),
        .push(push),
        .instr(instr),
        .redirectBranch(redirectBranch),
        .redirectTarget(redirectTarget)
    );

    INSTRUCTION_BUFFER #(
        .XLEN(XLEN),
        .DEPTH(QUEUE_DEPTH)
    ) Q1 (
        .clock(clock),
        .resetn(resetn),
        .flush(flushQueue),
        .bufferEmpty(bufferEmpty),
        .bufferFull(bufferFull),
        .push(push),
        .instrIn(instr),
        .iAddrIn(iAddr),
        .pop(pop),
        .instrOutA(instrA),
        .iAddrOutA(iAddrOutA),
        .instrOutB(instrB),
        .iAddrOutB(iAddrOutB)
    );

    //================================
    // Decode and Register Read Stage
    //================================

    // ID/RD pipeline
    always @(posedge clock or negedge resetn) begin
        
    end

    //================================
    // Rename and Dispatch Stage
    //================================

    // RD/EX pipeline
    always @(posedge clock or negedge resetn) begin
        
    end

    //================================
    // Execution Stage
    //================================
    
    // EX/WB pipeline
    always @(posedge clock or negedge resetn) begin
        
    end

    //================================
    // Write Back Stage
    //================================
    
    // WB/RT pipeline
    always @(posedge clock or negedge resetn) begin
        
    end

    //================================
    // Retirement Stage
    //================================
endmodule
module IF_STAGE #(
    parameter XLEN = 32,            // Width of GPR (32 or 64)
    parameter PREDITOR_DEPTH = 256,
    parameter BTB_DEPTH = 256,
    parameter NOP = 32'h00000013    // NOP
)(
    input clock,
    input resetn,                   // Asynchronous reset on low level
    // Instruction BUS
    output iMemEn,                  // Enable for instruction memory
    output reg [XLEN-1:0] iAddr,    // Address of current instruction to be fetched
    input  [XLEN-1:0] iData,        // Instruction Data
    // Instruction Fetched
    input bufferFull,               // Fifo buffer full
    output reg push,                // Push instruction to fifo buffer
    output reg [29:0] instr,        // Instruction fetched
    // Redirect Branch
    input redirectBranch,           // Redirect when a prediction error occurs or interrupts
    input [XLEN-1:0] redirectTarget,
    // Branch Preditor
    input bpuFlush,
    input preditorUpdate,
    input globalPreditorUpdate,
    input lastBranch,
    input [$clog2(PREDITOR_DEPTH)-1:0] lastIndex,
    input btbUpdate,
    input typeBranch,
    input [XLEN-1:0] target,
    input [XLEN-1:0] branchAddr
);
    // Clock gate
    reg clockEn;
    always @(*) begin
        if (~clock)
            clockEn <= ~bufferFull;
        else if (~resetn)
            clockEn <= 1'b1;
    end
    wire clockGate = clock && clockEn; 
    assign iMemEn = clockEn;

    // Branch Preditor and Branch Buffer Target
    wire branchTaken;
    wire [XLEN-1:0] branchTarget;

    BPU #(
        .XLEN(XLEN),
        .PREDITOR_DEPTH(PREDITOR_DEPTH),
        .BTB_DEPTH(BTB_DEPTH)
    ) BPU1 (
        .clock(clock),
        .resetn(resetn),
        .flush(bpuFlush),
        .iAddr(iAddr),
        .branchTaken(branchTaken),
        .branchTarget(branchTarget),
        .preditorIndex(preditorIndex),
        .preditorUpdate(preditorUpdate),
        .globalPreditorUpdate(globalPreditorUpdate),
        .lastBranch(lastBranch),
        .lastIndex(lastIndex),
        .btbUpdate(btbUpdate),
        .typeBranch(typeBranch),
        .target(target),
        .branchAddr(branchAddr)
    );

    // Contador de Programa
    reg [XLEN-1:0] iAddrNext;
    wire [1:0] pcSrc = {redirectBranch, branchTaken};

    always @(*) begin
        instr = iData[31:2]; // Os dois primeros bits são sempre 1
        push  = (iData[7:2] != NOP[7:2]) && !bufferFull; // Empura somente se tiver lugar ou se a instrução não é um nop

        case (pcSrc)
            2'b00: iAddrNext = iAddr + 4;
            2'b01: iAddrNext = branchTarget;
            2'b10, 2'b11: iAddrNext = redirectTarget;
            default: iAddrNext = iAddr + 4;
        endcase
    end
    
    always @(posedge clockGate or negedge resetn) begin
        if (~resetn) begin
            iAddr <= 0;
        end else begin
            iAddr <= iAddrNext;
        end
    end
endmodule
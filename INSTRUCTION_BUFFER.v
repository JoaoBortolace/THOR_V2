module INSTRUCTION_BUFFER #( 
    parameter XLEN = 32,            // Width of GPR (32 or 64) 
    parameter DEPTH = 4,            // Depth of queue (must be power of 2) 
    parameter NOP = 32'h00000013    // NOP 
)( 
    input clock, 
    input resetn,                   // Asynchronous reset on low level 
    input flush,                    // Flush fifo 
    // Queue status output 
    output bufferEmpty,             // Queue Empty flag 
    output bufferFull,              // Queue Full flag 
    // Instruction Push/Pop 
    input push, 
    input [29:0] instrIn, 
    input [XLEN-1:0] iAddrIn,       // iAddr of current instruction 
    input pop,                      // Pop 2 instructions 
    output [29:0] instrOutA, 
    output [XLEN-1:0] iAddrOutA, 
    output [29:0] instrOutB, 
    output [XLEN-1:0] iAddrOutB 
);  
    // Queue memory 
    reg [29:0]     instrQueue [0:DEPTH-1]; 
    reg [XLEN-6:0] iAddrQueue [0:DEPTH-1];  
    // Queue pointers 
    localparam QUEUE_ADDR = $clog2(DEPTH); 
    reg [QUEUE_ADDR-1:0] first; 
    reg [QUEUE_ADDR-1:0] last; 
    reg [QUEUE_ADDR:0] count; 
    // Output logic 
    assign instrOutA = (count >= 1) ? instrQueue[first] : NOP[31:2]; 
    assign iAddrOutA = (count >= 1) ? {3'b000, iAddrQueue[first], 2'b00} : {XLEN-1{1'b0}}; 
    assign instrOutB = (count >= 2) ? instrQueue[(first + 1) & (DEPTH - 1)] : NOP[31:2]; 
    assign iAddrOutB = (count >= 2) ? {3'b000, iAddrQueue[(first + 1) & (DEPTH - 1)], 2'b00} : {XLEN-1{1'b0}}; 
    // Status flags 
    assign bufferEmpty = (count == 0); 
    assign bufferFull = (count >= DEPTH); 
    // Update Signal
    wire firstUp = (count >= 2) ? (first + 2) & (DEPTH - 1) : (first + 1) & (DEPTH - 1); 
    wire lastUp = (last + 1) & (DEPTH - 1);
    wire countUp = pop ? (count >= 2 ? count - 2 : count - 1) : count + 1; 
    
    integer i; 
    always @(posedge clock or negedge resetn) begin 
        if (~resetn) begin 
            first <= 0; 
            last <= 0; 
            count <= 0; 
        end else if (flush) begin 
            first <= 0; 
            last <= 0; 
            count <= 0; 
        end else begin 
            // Pop logic 
            if (pop) begin 
                first <= firstUp; 
                count <= countUp; 
            end 
            // Push logic 
            if (push && count < DEPTH) begin 
                instrQueue[last] <= instrIn;
                iAddrQueue[last] <= iAddrIn[XLEN-4:2];
                last <= lastUp; 
                count <= countUp; 
            end 
        end 
    end 
endmodule
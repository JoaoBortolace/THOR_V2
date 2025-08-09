module FIFO #(
    parameter XLEN = 32,                  // Width of GPR (32 or 64)
    parameter DEPTH = 4,                  // Depth of queue (must be power of 2)
    parameter NOP   = 32'h00000013        // NOP
)(
    input clock,
    input resetn,                         // Asynchronous reset on low level
    input flush,                          // Flush fifo
    // Queue status
    output queueEmpty,                    // Queue Empty flag
    output queueFull,                     // Queue Full flag                
    // Instruction Push/Pop
    input  push,
    input  [29:0] instrIn,
    input  [XLEN-6:0] iAddrIn,            // iAddr of current instruction
    input  pop,                           // Pop 2 instructions
    output [29:0] instrOutA,
    output [XLEN-6:0] iAddrOutA,
    output [29:0] instrOutB,
    output [XLEN-6:0] iAddrOutB
);
    // Queue memory
    reg [XLEN-6 + 29:0] queue [0:DEPTH-1];

    // Queue pointers
    localparam QUEUE_ADDR = $clog2(DEPTH);
    reg [QUEUE_ADDR-1:0] first;
    reg [QUEUE_ADDR-1:0] last;
    reg [QUEUE_ADDR:0] count;

    // Output logic
    assign instrOutA = (count >= 1) ? queue[first][29:0] : NOP[31:2];
    assign iAddrOutA = (count >= 1) ? queue[first][XLEN-6:30] : 0;
    assign instrOutB = (count >= 2) ? queue[(first + 1) & (DEPTH - 1)][29:0] : NOP[31:2];
    assign iAddrOutB = (count >= 2) ? queue[(first + 1) & (DEPTH - 1)][XLEN-6:30] : 0;

    // Status flags
    assign queueEmpty = (count == 0);
    assign queueFull  = (count >= DEPTH);

    always @(posedge clock or negedge resetn) begin
        if (~resetn || flush) begin
            first <= 0;
            last  <= 0;
            count <= 0;
            for (integer i = 0; i < DEPTH; i = i + 1)
                queue[i] <= 0;
        end else begin
            // Pop logic
            if (pop && count >= 2) begin
                first <= (first + 2) & (DEPTH - 1);
                count <= count - 2;
            end else if (pop && count == 1) begin
                first <= (first + 1) & (DEPTH - 1);
                count <= count - 1;
            end
            // Push logic
            if (push && count < DEPTH) begin
                queue[last] <= {iAddrIn, instrIn};
                last <= (last + 1) & (DEPTH - 1);
                count <= count + 1;
            end
        end
    end
endmodule
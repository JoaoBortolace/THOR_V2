module ID_STAGE #(
    parameter XLEN = 32,            // Width of GPR (32 or 64)
    parameter NUM_REG = 32,         // Nuumber of GPR (16 or 32)
)(
    input clock,
    input resetn,                   // Asynchronous reset on low level
    input flush,                    // Flush Stage

    // Instruction Buffer
    input queueEmpty,
    output pop,
    input [31:0] insA,
    input [31:0] insB
);


    
endmodule
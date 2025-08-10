module BPU #(
    parameter XLEN = 32,
    parameter PREDITOR_DEPTH = 64,
    parameter BTB_DEPTH = 256
)(
    input  clock,
    input  resetn,
    input  flush,
    // Preditor (fetch)
    input  [XLEN-1:0] iAddr,
    output reg            branchTaken,
    output reg [XLEN-1:0] branchTarget,
    // Preditor Update (commit)
    input  preditorUpdate,
    input  globalPreditorUpdate, // Especulativo (atualiza GHR)
    output reg [$clog2(PREDITOR_DEPTH)-1:0] preditorIndex,
    input  [$clog2(PREDITOR_DEPTH)-1:0] lastIndex,
    input  missPredict,
    input  lastBranch,
    // BTB Update
    input  btbUpdate,
    input  typeBranch,                 // 1 = unconditional ou forced taken, 0 = conditional
    input  [XLEN-1:0] target,
    input  [XLEN-1:0] branchAddr
);
    // ----------------------------------------------------------------
    localparam HISTORY_SIZE = $clog2(PREDITOR_DEPTH);
    localparam BTB_AWIDTH   = $clog2(BTB_DEPTH);

    // GHR
    reg [HISTORY_SIZE-1:0] globalHistory;
    // Preditor
    reg preditor [0:PREDITOR_DEPTH-1]; 
    // Histerese 
    reg histerese[0:PREDITOR_DEPTH-1]; 
    // Branch Target Buffer [valid, type, target_compact]
    reg [XLEN-4:0] BTB  [0:BTB_DEPTH-1];       

    // Índices
    wire [BTB_AWIDTH-1:0]   btbIndex = iAddr[BTB_AWIDTH+1:2];
    wire [HISTORY_SIZE-1:0] idx      = iAddr[HISTORY_SIZE+1:2] ^ globalHistory;

    // Sinais de leitura combinacional
    reg prediction;
    reg hit;
    reg branchType;
    reg [XLEN-4:0] btbData;

    always @(*) begin
        // Índice exportado usado na predição
        preditorIndex = idx;
        // Preditor
        prediction = preditor[idx];
        // BTB
        btbData      = BTB[btbIndex];
        hit          = btbData[XLEN-4];
        branchType   = btbData[XLEN-5];
        branchTarget = {3'b000, btbData[XLEN-6:0], 2'b00};
        branchTaken  = hit & (branchType | prediction);
    end

    // Atualizações e reset
    integer i;
    always @(posedge clock or negedge resetn) begin
        if (!resetn) begin
            globalHistory <= {HISTORY_SIZE{1'b0}};
        end else begin
            // Flush só limpa GHR
            if (flush)
                globalHistory <= {HISTORY_SIZE{1'b0}};           
            // Atualiza GHR (especulativo)
            else if (globalPreditorUpdate)
                globalHistory <= {globalHistory[HISTORY_SIZE-2:0], lastBranch};

            // Update do preditor (commit)
            if (preditorUpdate) begin
                if (missPredict)
                    preditor[lastIndex] <= histerese[lastIndex];
                // Atualiza histerese com o resultado atual
                histerese[lastIndex] <= lastBranch;
            end
            // Update da BTB (commit)
            if (btbUpdate)
                BTB[branchAddr[BTB_AWIDTH+1:2]] <= {1'b1, typeBranch, target[XLEN-4:2]};
        end
    end
endmodule
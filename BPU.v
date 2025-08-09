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
    output            branchTaken,
    output [XLEN-1:0] branchTarget,
    // Exporte o índice usado na predição para atualizar depois
    output reg [$clog2(PREDITOR_DEPTH)-1:0] preditorIndex,
    // Preditor Update (commit)
    input  preditorUpdate,
    input  globalPreditorUpdate // Especulativo
    input  lastResult,
    input  [$clog2(PREDITOR_DEPTH)-1:0] lastIndex,
    // BTB Update
    input  btbUpdate,
    input  branchType,                 // 1 = unconditional or forced taken, 0 = conditional
    input  [XLEN-1:0] target,
    input  [XLEN-1:0] branchAddr
);
    // ----------------------------------------------------------------
    // Tamanhos e estado
    localparam HISTORY_SIZE = $clog2(PREDITOR_DEPTH);
    localparam BTB_AWIDTH   = $clog2(BTB_DEPTH);

    reg [HISTORY_SIZE-1:0] globalHistory;         // GHR
    reg [1:0] preditor [0:PREDITOR_DEPTH-1];      // 2-bit counters
    // BTB: [valid, type, target_compact]
    // target_compact armazena (XLEN-5) bits ==> remove bit0 e bit1 e assume top 3 bits 0
    reg [XLEN-4:0] BTB [0:BTB_DEPTH-1];

    // ----------------------------------------------------------------
    // Índices da BTB (Word-aligned: usa [AWIDTH+1:2])
    wire [BTB_AWIDTH-1:0] index = iAddr[BTB_AWIDTH+1:2];

    // Hash de índice do preditor: usa bits do PC [HISTORY_SIZE+1:2] XOR GHR
    wire [HISTORY_SIZE-1:0] idx = iAddr[HISTORY_SIZE+1:2] ^ globalHistory;

    // Leitura do preditor (bit MSB do contador => previsão)
    wire prediction = preditor[idx][1];

    // Leitura da BTB
    wire hit        = BTB[index][XLEN-4];
    wire type       = BTB[index][XLEN-5];
    assign branchTarget = {3'b000, BTB[index][XLEN-6:0], 2'b00};
    assign branchTaken = hit && (typeA || predictionA);

    // ----------------------------------------------------------------
    // Reset/flush e updates
    always @(posedge clock or negedge resetn) begin
        if (!resetn) begin
            globalHistory <= {HISTORY_SIZE{1'b0}};
            for (integer i = 0; i < PREDITOR_DEPTH; i = i + 1)
                preditor[i] <= 2'b10; // ligeiramente tendente a 'taken'
            for (integer j = 0; j < BTB_DEPTH; j = j + 1)
                BTB[j] <= {1'b0, {XLEN-5{1'b0}}};
        end else if (flush)
            globalHistory <= {HISTORY_SIZE{1'b0}};
        else begin
            if (globalPreditorUpdate)
                // Atualiza GHR (especulativo): shift e injeta o resultado
                globalHistory <= {globalHistory[HISTORY_SIZE-2:0], lastResult};
            // Update do preditor (commit)
            if (preditorUpdate) begin
                // Atualiza contador saturante 2-bit
                if (lastResult) begin
                    if (preditor[lastIndex] != 2'b11)
                        preditor[lastIndex] <= preditor[lastIndex] + 2'b01;
                end else begin
                    if (preditor[lastIndex] != 2'b00)
                        preditor[lastIndex] <= preditor[lastIndex] - 2'b01;
                end
            end
            // Update da BTB (commit)
            if (btbUpdate) begin
                // Usa o mesmo mapeamento de índice da leitura
                wire [BTB_AWIDTH-1:0] wIndex = branchAddr[BTB_AWIDTH:1];
                BTB[wIndex] <= {1'b1, branchType, target[XLEN-3:2]};
            end
        end
    end
endmodule
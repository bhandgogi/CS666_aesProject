// ============================================================================
// KeyExpansion_Sequential.v
// Sequential Key Expansion Module for AES-128
// Generates one round key per cycle (11 cycles total)
// ============================================================================

module KeyExpansion_Sequential #(parameter Nk = 4, parameter Nr = 10) (
    input clk,
    input reset,
    input start,                                        // Start key expansion
    input [Nk * 32 - 1:0] key,                         // Initial 128-bit key
    output reg [((Nr + 1) * 128) - 1:0] allKeys,       // All 11 round keys
    output reg ready                                    // Key expansion complete
);

    // State machine states
    localparam IDLE = 2'b00;
    localparam EXPANDING = 2'b01;
    localparam READY = 2'b10;
    
    reg [1:0] state;
    reg [3:0] round;                    // Current round (0 to 10)
    reg [127:0] currentKey;             // Current key being processed
    
    wire [127:0] nextRoundKey;
    
    // Instantiate one KeyExpansionRound (reused for each round)
    KeyExpansionRound #(Nk, Nr) keyExpRound(
        .roundCount(round),
        .keyIn(currentKey),
        .keyOut(nextRoundKey)
    );
    
    // State machine
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state <= IDLE;
            round <= 4'd0;
            ready <= 1'b0;
            currentKey <= 128'd0;
            allKeys <= {(Nr+1)*128{1'b0}};
        end
        else begin
            case (state)
                IDLE: begin
                    ready <= 1'b0;
                    if (start) begin
                        // Store initial key as round 0
                        currentKey <= key;
                        allKeys[((Nr + 1) * 128) - 1 -: 128] <= key;
                        round <= 4'd1;
                        state <= EXPANDING;
                    end
                end
                
                EXPANDING: begin
                    // Store generated round key
                    allKeys[((Nr + 1) * 128) - 1 - round * 128 -: 128] <= nextRoundKey;
                    currentKey <= nextRoundKey;
                    
                    if (round == Nr) begin
                        state <= READY;
                        ready <= 1'b1;
                    end
                    else begin
                        round <= round + 4'd1;
                    end
                end
                
                READY: begin
                    ready <= 1'b1;
                    // Stay in READY state
                end
                
                default: state <= IDLE;
            endcase
        end
    end

endmodule

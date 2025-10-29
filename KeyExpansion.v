// ============================================================================
// FILE: KeyExpansion_Sequential.v
// Description: Sequential Key Expansion Module for AES-128
// Converts combinational key expansion to sequential (1 key per cycle)
// Author: Pipelined AES Implementation
// ============================================================================

module KeyExpansion_Sequential #(parameter Nk = 4, parameter Nr = 10) (
    input clk,
    input reset,
    input start,
    input [Nk * 32 - 1:0] key,
    output reg [((Nr + 1) * 128) - 1:0] allKeys,
    output reg ready
);

    localparam IDLE = 2'b00;
    localparam EXPANDING = 2'b01;
    localparam READY = 2'b10;
    
    reg [1:0] state;
    reg [3:0] round;
    reg [127:0] currentKey;
    
    wire [127:0] nextRoundKey;
    
    KeyExpansionRound #(Nk, Nr) keyExpRound(
        .roundCount(round),
        .keyIn(currentKey),
        .keyOut(nextRoundKey)
    );
    
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
                        currentKey <= key;
                        allKeys[((Nr + 1) * 128) - 1 -: 128] <= key;
                        round <= 4'd1;
                        state <= EXPANDING;
                    end
                end
                
                EXPANDING: begin
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
                end
                
                default: state <= IDLE;
            endcase
        end
    end

endmodule

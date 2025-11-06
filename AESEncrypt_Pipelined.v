// ============================================================================
// AESEncrypt_Pipelined.v
// Fully Pipelined AES-128 Encryption Module
// 11 pipeline stages for 1 block per cycle throughput
// ============================================================================

module AESEncrypt_Pipelined #(parameter Nk = 4, parameter Nr = 10) (
    input clk,
    input reset,
    input [127:0] data,                                 // Input plaintext
    input data_valid,                                   // Data valid signal
    input [((Nr + 1) * 128) - 1:0] allKeys,            // All round keys
    output reg [127:0] out,                            // Output ciphertext
    output reg done                                     // Output valid
);

    // Pipeline registers
    reg [127:0] stage [0:Nr];
    reg valid [0:Nr];
    
    // ========== Stage 0: Initial AddRoundKey ==========
    wire [127:0] stage0_out;
    AddRoundKey ark0(
        .state(data),
        .roundKey(allKeys[((Nr + 1) * 128) - 1 -: 128]),
        .stateOut(stage0_out)
    );
    
    // ========== Stages 1-9: Full Rounds (SubBytes → ShiftRows → MixColumns → AddRoundKey) ==========
    genvar i;
    generate
        for (i = 1; i <= 9; i = i + 1) begin : full_rounds
            wire [127:0] sub_out, shift_out, mix_out, key_out;
            
            SubBytes sb(
                .state(stage[i-1]),
                .stateOut(sub_out)
            );
            
            ShiftRows sr(
                .state(sub_out),
                .stateOut(shift_out)
            );
            
            MixColumns mc(
                .state(shift_out),
                .stateOut(mix_out)
            );
            
            AddRoundKey ark(
                .state(mix_out),
                .roundKey(allKeys[((Nr + 1) * 128) - 1 - i * 128 -: 128]),
                .stateOut(key_out)
            );
            
            // Pipeline register for this stage
            always @(posedge clk or posedge reset) begin
                if (reset) begin
                    stage[i] <= 128'd0;
                    valid[i] <= 1'b0;
                end
                else begin
                    stage[i] <= key_out;
                    valid[i] <= valid[i-1];
                end
            end
        end
    endgenerate
    
    // ========== Stage 10: Final Round (SubBytes → ShiftRows → AddRoundKey, no MixColumns) ==========
    wire [127:0] final_sub_out, final_shift_out, final_key_out;
    
    SubBytes final_sb(
        .state(stage[9]),
        .stateOut(final_sub_out)
    );
    
    ShiftRows final_sr(
        .state(final_sub_out),
        .stateOut(final_shift_out)
    );
    
    AddRoundKey final_ark(
        .state(final_shift_out),
        .roundKey(allKeys[127:0]),
        .stateOut(final_key_out)
    );
    
    // ========== Pipeline Stage Registers ==========
    // Stage 0 register
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            stage[0] <= 128'd0;
            valid[0] <= 1'b0;
        end
        else begin
            stage[0] <= stage0_out;
            valid[0] <= data_valid;
        end
    end
    
    // Stage 10 register and output
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            stage[10] <= 128'd0;
            valid[10] <= 1'b0;
            out <= 128'd0;
            done <= 1'b0;
        end
        else begin
            stage[10] <= final_key_out;
            valid[10] <= valid[9];
            out <= final_key_out;
            done <= valid[9];
        end
    end

endmodule


// ============================================================================
// Top-level Module: Combines Key Expansion + Pipelined Encryption
// ============================================================================

module AESEncrypt128_Pipelined_DUT (
    input [127:0] data,
    input [127:0] key,
    input clk,
    input reset,
    input start,                        // Start signal for key expansion
    output [127:0] out,
    output done,
    output key_ready                    // Key expansion complete
);

    localparam Nk = 4;
    localparam Nr = 10;
    
    wire [((Nr + 1) * 128) - 1:0] allKeys;
    wire keys_ready;
    
    reg start_key_exp;
    reg prev_start;
    
    // Edge detection for start signal
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            prev_start <= 1'b0;
            start_key_exp <= 1'b0;
        end
        else begin
            prev_start <= start;
            start_key_exp <= start && !prev_start;
        end
    end
    
    // Sequential Key Expansion
    KeyExpansion_Sequential #(Nk, Nr) keyExp(
        .clk(clk),
        .reset(reset),
        .start(start_key_exp),
        .key(key),
        .allKeys(allKeys),
        .ready(keys_ready)
    );
    
    // Pipelined Encryption
    AESEncrypt_Pipelined #(Nk, Nr) aesEnc(
        .clk(clk),
        .reset(reset),
        .data(data),
        .data_valid(keys_ready),
        .allKeys(allKeys),
        .out(out),
        .done(done)
    );
    
    assign key_ready = keys_ready;

endmodule

// ============================================================================
// FILE: AESEncrypt_Pipelined_Optimized.v
// Description: Ultra-Optimized Fully Pipelined AES-128 Encryption
// Optimized for Maximum Frequency and Minimum Latency
// ============================================================================

module AESEncrypt_Pipelined_Optimized #(parameter Nk = 4, parameter Nr = 10) (
    input clk,
    input reset,
    input [127:0] data,
    input data_valid,
    input [((Nr + 1) * 128) - 1:0] allKeys,
    output reg [127:0] out,
    output reg done
);

    // Individual pipeline registers for each operation to maximize frequency
    reg [127:0] ark0_out;
    reg ark0_valid;
    
    // Round 1
    reg [127:0] r1_sub_out, r1_shift_out, r1_mix_out, r1_ark_out;
    reg r1_valid;
    
    // Round 2  
    reg [127:0] r2_sub_out, r2_shift_out, r2_mix_out, r2_ark_out;
    reg r2_valid;
    
    // Round 3
    reg [127:0] r3_sub_out, r3_shift_out, r3_mix_out, r3_ark_out;
    reg r3_valid;
    
    // Round 4
    reg [127:0] r4_sub_out, r4_shift_out, r4_mix_out, r4_ark_out;
    reg r4_valid;
    
    // Round 5
    reg [127:0] r5_sub_out, r5_shift_out, r5_mix_out, r5_ark_out;
    reg r5_valid;
    
    // Round 6
    reg [127:0] r6_sub_out, r6_shift_out, r6_mix_out, r6_ark_out;
    reg r6_valid;
    
    // Round 7
    reg [127:0] r7_sub_out, r7_shift_out, r7_mix_out, r7_ark_out;
    reg r7_valid;
    
    // Round 8
    reg [127:0] r8_sub_out, r8_shift_out, r8_mix_out, r8_ark_out;
    reg r8_valid;
    
    // Round 9
    reg [127:0] r9_sub_out, r9_shift_out, r9_mix_out, r9_ark_out;
    reg r9_valid;
    
    // Final Round
    reg [127:0] r10_sub_out, r10_shift_out, r10_ark_out;
    reg r10_valid;

    // ==================== STAGE 0: Initial AddRoundKey ====================
    wire [127:0] stage0_ark_wire;
    AddRoundKey_HighFreq ark0(
        .state(data),
        .roundKey(allKeys[((Nr + 1) * 128) - 1 -: 128]),
        .stateOut(stage0_ark_wire)
    );
    
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            ark0_out <= 128'd0;
            ark0_valid <= 1'b0;
        end else begin
            ark0_out <= stage0_ark_wire;
            ark0_valid <= data_valid;
        end
    end

    // ==================== ROUND 1 ====================
    SubBytes_HighFreq r1_sb(.state(ark0_out), .stateOut(r1_sub_out));
    always @(posedge clk) r1_shift_out <= r1_sub_out;
    
    ShiftRows_HighFreq r1_sr(.state(r1_shift_out), .stateOut(r1_shift_out));
    always @(posedge clk) r1_mix_out <= r1_shift_out;
    
    MixColumns_HighFreq r1_mc(.state(r1_mix_out), .stateOut(r1_mix_out));
    always @(posedge clk) r1_ark_out <= r1_mix_out;
    
    AddRoundKey_HighFreq r1_ark(
        .state(r1_ark_out),
        .roundKey(allKeys[((Nr + 1) * 128) - 1 - 1 * 128 -: 128]),
        .stateOut(r1_ark_out)
    );
    always @(posedge clk) begin
        r1_valid <= ark0_valid;
        r1_ark_out <= r1_ark_out;
    end

    // ==================== ROUND 2 ====================
    SubBytes_HighFreq r2_sb(.state(r1_ark_out), .stateOut(r2_sub_out));
    always @(posedge clk) r2_shift_out <= r2_sub_out;
    
    ShiftRows_HighFreq r2_sr(.state(r2_shift_out), .stateOut(r2_shift_out));
    always @(posedge clk) r2_mix_out <= r2_shift_out;
    
    MixColumns_HighFreq r2_mc(.state(r2_mix_out), .stateOut(r2_mix_out));
    always @(posedge clk) r2_ark_out <= r2_mix_out;
    
    AddRoundKey_HighFreq r2_ark(
        .state(r2_ark_out),
        .roundKey(allKeys[((Nr + 1) * 128) - 1 - 2 * 128 -: 128]),
        .stateOut(r2_ark_out)
    );
    always @(posedge clk) begin
        r2_valid <= r1_valid;
        r2_ark_out <= r2_ark_out;
    end

    // ==================== ROUND 3 ====================
    SubBytes_HighFreq r3_sb(.state(r2_ark_out), .stateOut(r3_sub_out));
    always @(posedge clk) r3_shift_out <= r3_sub_out;
    
    ShiftRows_HighFreq r3_sr(.state(r3_shift_out), .stateOut(r3_shift_out));
    always @(posedge clk) r3_mix_out <= r3_shift_out;
    
    MixColumns_HighFreq r3_mc(.state(r3_mix_out), .stateOut(r3_mix_out));
    always @(posedge clk) r3_ark_out <= r3_mix_out;
    
    AddRoundKey_HighFreq r3_ark(
        .state(r3_ark_out),
        .roundKey(allKeys[((Nr + 1) * 128) - 1 - 3 * 128 -: 128]),
        .stateOut(r3_ark_out)
    );
    always @(posedge clk) begin
        r3_valid <= r2_valid;
        r3_ark_out <= r3_ark_out;
    end

    // ==================== ROUND 4 ====================
    SubBytes_HighFreq r4_sb(.state(r3_ark_out), .stateOut(r4_sub_out));
    always @(posedge clk) r4_shift_out <= r4_sub_out;
    
    ShiftRows_HighFreq r4_sr(.state(r4_shift_out), .stateOut(r4_shift_out));
    always @(posedge clk) r4_mix_out <= r4_shift_out;
    
    MixColumns_HighFreq r4_mc(.state(r4_mix_out), .stateOut(r4_mix_out));
    always @(posedge clk) r4_ark_out <= r4_mix_out;
    
    AddRoundKey_HighFreq r4_ark(
        .state(r4_ark_out),
        .roundKey(allKeys[((Nr + 1) * 128) - 1 - 4 * 128 -: 128]),
        .stateOut(r4_ark_out)
    );
    always @(posedge clk) begin
        r4_valid <= r3_valid;
        r4_ark_out <= r4_ark_out;
    end

    // ==================== ROUND 5 ====================
    SubBytes_HighFreq r5_sb(.state(r4_ark_out), .stateOut(r5_sub_out));
    always @(posedge clk) r5_shift_out <= r5_sub_out;
    
    ShiftRows_HighFreq r5_sr(.state(r5_shift_out), .stateOut(r5_shift_out));
    always @(posedge clk) r5_mix_out <= r5_shift_out;
    
    MixColumns_HighFreq r5_mc(.state(r5_mix_out), .stateOut(r5_mix_out));
    always @(posedge clk) r5_ark_out <= r5_mix_out;
    
    AddRoundKey_HighFreq r5_ark(
        .state(r5_ark_out),
        .roundKey(allKeys[((Nr + 1) * 128) - 1 - 5 * 128 -: 128]),
        .stateOut(r5_ark_out)
    );
    always @(posedge clk) begin
        r5_valid <= r4_valid;
        r5_ark_out <= r5_ark_out;
    end

    // ==================== ROUND 6 ====================
    SubBytes_HighFreq r6_sb(.state(r5_ark_out), .stateOut(r6_sub_out));
    always @(posedge clk) r6_shift_out <= r6_sub_out;
    
    ShiftRows_HighFreq r6_sr(.state(r6_shift_out), .stateOut(r6_shift_out));
    always @(posedge clk) r6_mix_out <= r6_shift_out;
    
    MixColumns_HighFreq r6_mc(.state(r6_mix_out), .stateOut(r6_mix_out));
    always @(posedge clk) r6_ark_out <= r6_mix_out;
    
    AddRoundKey_HighFreq r6_ark(
        .state(r6_ark_out),
        .roundKey(allKeys[((Nr + 1) * 128) - 1 - 6 * 128 -: 128]),
        .stateOut(r6_ark_out)
    );
    always @(posedge clk) begin
        r6_valid <= r5_valid;
        r6_ark_out <= r6_ark_out;
    end

    // ==================== ROUND 7 ====================
    SubBytes_HighFreq r7_sb(.state(r6_ark_out), .stateOut(r7_sub_out));
    always @(posedge clk) r7_shift_out <= r7_sub_out;
    
    ShiftRows_HighFreq r7_sr(.state(r7_shift_out), .stateOut(r7_shift_out));
    always @(posedge clk) r7_mix_out <= r7_shift_out;
    
    MixColumns_HighFreq r7_mc(.state(r7_mix_out), .stateOut(r7_mix_out));
    always @(posedge clk) r7_ark_out <= r7_mix_out;
    
    AddRoundKey_HighFreq r7_ark(
        .state(r7_ark_out),
        .roundKey(allKeys[((Nr + 1) * 128) - 1 - 7 * 128 -: 128]),
        .stateOut(r7_ark_out)
    );
    always @(posedge clk) begin
        r7_valid <= r6_valid;
        r7_ark_out <= r7_ark_out;
    end

    // ==================== ROUND 8 ====================
    SubBytes_HighFreq r8_sb(.state(r7_ark_out), .stateOut(r8_sub_out));
    always @(posedge clk) r8_shift_out <= r8_sub_out;
    
    ShiftRows_HighFreq r8_sr(.state(r8_shift_out), .stateOut(r8_shift_out));
    always @(posedge clk) r8_mix_out <= r8_shift_out;
    
    MixColumns_HighFreq r8_mc(.state(r8_mix_out), .stateOut(r8_mix_out));
    always @(posedge clk) r8_ark_out <= r8_mix_out;
    
    AddRoundKey_HighFreq r8_ark(
        .state(r8_ark_out),
        .roundKey(allKeys[((Nr + 1) * 128) - 1 - 8 * 128 -: 128]),
        .stateOut(r8_ark_out)
    );
    always @(posedge clk) begin
        r8_valid <= r7_valid;
        r8_ark_out <= r8_ark_out;
    end

    // ==================== ROUND 9 ====================
    SubBytes_HighFreq r9_sb(.state(r8_ark_out), .stateOut(r9_sub_out));
    always @(posedge clk) r9_shift_out <= r9_sub_out;
    
    ShiftRows_HighFreq r9_sr(.state(r9_shift_out), .stateOut(r9_shift_out));
    always @(posedge clk) r9_mix_out <= r9_shift_out;
    
    MixColumns_HighFreq r9_mc(.state(r9_mix_out), .stateOut(r9_mix_out));
    always @(posedge clk) r9_ark_out <= r9_mix_out;
    
    AddRoundKey_HighFreq r9_ark(
        .state(r9_ark_out),
        .roundKey(allKeys[((Nr + 1) * 128) - 1 - 9 * 128 -: 128]),
        .stateOut(r9_ark_out)
    );
    always @(posedge clk) begin
        r9_valid <= r8_valid;
        r9_ark_out <= r9_ark_out;
    end

    // ==================== FINAL ROUND (10) ====================
    SubBytes_HighFreq r10_sb(.state(r9_ark_out), .stateOut(r10_sub_out));
    always @(posedge clk) r10_shift_out <= r10_sub_out;
    
    ShiftRows_HighFreq r10_sr(.state(r10_shift_out), .stateOut(r10_shift_out));
    always @(posedge clk) r10_ark_out <= r10_shift_out;
    
    AddRoundKey_HighFreq r10_ark(
        .state(r10_ark_out),
        .roundKey(allKeys[127:0]),
        .stateOut(r10_ark_out)
    );
    always @(posedge clk) begin
        r10_valid <= r9_valid;
        r10_ark_out <= r10_ark_out;
    end

    // ==================== OUTPUT ====================
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            out <= 128'd0;
            done <= 1'b0;
        end else begin
            out <= r10_ark_out;
            done <= r10_valid;
        end
    end

endmodule

// High Frequency Optimized SubBytes with registered outputs
module SubBytes_HighFreq(
    input clk,
    input [127:0] state,
    output reg [127:0] stateOut
);
    wire [127:0] sub_wire;
    
    // Use your existing SubBytes module
    SubBytes sub_inst(.oriBytes(state), .subBytes(sub_wire));
    
    always @(posedge clk) begin
        stateOut <= sub_wire;
    end
endmodule

// Similarly optimized versions for other operations...
module ShiftRows_HighFreq(
    input clk,
    input [127:0] state,
    output reg [127:0] stateOut
);
    wire [127:0] shift_wire;
    
    // Use your existing ShiftRows module  
    ShiftRows sr_inst(.in(state), .out(shift_wire));
    
    always @(posedge clk) begin
        stateOut <= shift_wire;
    end
endmodule

module MixColumns_HighFreq(
    input clk, 
    input [127:0] stateIn,
    output reg [127:0] stateOut
);
    wire [127:0] mix_wire;
    
    // Use your existing MixColumns module
    MixColumns mc_inst(.stateIn(stateIn), .stateOut(mix_wire));
    
    always @(posedge clk) begin
        stateOut <= mix_wire;
    end
endmodule

module AddRoundKey_HighFreq(
    input clk,
    input [127:0] state, 
    input [127:0] roundKey,
    output reg [127:0] stateOut
);
    wire [127:0] ark_wire = state ^ roundKey;
    
    always @(posedge clk) begin
        stateOut <= ark_wire;
    end
endmodule
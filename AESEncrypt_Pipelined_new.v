// ============================================================================
// AESEncrypt_Pipelined.v   (streaming-capable, multi-block)
// Fully pipelined AES-128 encryptor with sequential key expansion wrapper.
// - Accepts one block per cycle after key_ready (data_valid/data_ready).
// - No reset or re-start needed between blocks.
// - Uses 11 pipeline stages (Init ARK + 9 full rounds + Final round).
// Dependencies you already have: AddRoundKey.v, SubBytes.v, ShiftRows.v,
// MixColumns.v, KeyExpansion_Sequential.v
// ============================================================================

`timescale 1ns/1ps
`default_nettype none

// ----------------------------------------------------------------------------
// Core pipeline (round keys precomputed and supplied via allKeys)
// ----------------------------------------------------------------------------
module AESEncrypt_PipelineCore #(parameter Nk = 4, parameter Nr = 10) (
    input  wire         clk,
    input  wire         reset,

    // Stream in
    input  wire [127:0] data,
    input  wire         load,       // latch new plaintext when 1

    // Round keys (concatenated): allKeys[(Nr*128 +: 128)] is round 0 key (initial ARK),
    // down to allKeys[0 +: 128] = final round key.
    input  wire [((Nr+1)*128)-1:0] allKeys,

    // Stream out
    output reg  [127:0] out,
    output reg          out_valid
);
    // Valid pipeline (depth = Nr+1 = 11 stages)
    reg [Nr:0] valid;

    // Stage registers (state after each round)
    reg [127:0] stage [0:Nr];

    // ---------------- Stage 0: Initial AddRoundKey ----------------
    wire [127:0] rk0 = allKeys[((Nr)*128) +: 128];  // round-0 (initial) key
    wire [127:0] stage0_out;

    AddRoundKey u_ark0 (
        .state    (data),
        .roundKey (rk0),
        .stateOut (stage0_out)
    );

    // Latch stage0 and valid[0] only on load
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            stage[0]  <= 128'd0;
            valid[0]  <= 1'b0;
        end else begin
            if (load) begin
                stage[0] <= stage0_out;
                valid[0] <= 1'b1;
            end else begin
                // keep stage[0] don't-care when not loading; hold valid low
                valid[0] <= 1'b0;
            end
        end
    end

    // ------------- Stages 1..(Nr-1): full rounds (1..9) -------------
    genvar i;
    generate
        for (i = 1; i <= Nr-1; i = i + 1) begin : g_full
            wire [127:0] sb_o, sr_o, mc_o, ark_o;
            wire [127:0] rki = allKeys[((Nr-i)*128) +: 128];

            SubBytes  u_sb (.state(stage[i-1]), .stateOut(sb_o));
            ShiftRows u_sr (.state(sb_o),       .stateOut(sr_o));
            MixColumns u_mc(.state(sr_o),       .stateOut(mc_o));
            AddRoundKey u_ark(.state(mc_o), .roundKey(rki), .stateOut(ark_o));

            always @(posedge clk or posedge reset) begin
                if (reset) begin
                    stage[i] <= 128'd0;
                    valid[i] <= 1'b0;
                end else begin
                    stage[i] <= ark_o;
                    valid[i] <= valid[i-1];
                end
            end
        end
    endgenerate

    // ----------------- Final stage Nr: no MixColumns -----------------
    wire [127:0] sb_f, sr_f, ark_f;
    wire [127:0] rkf = allKeys[0 +: 128];

    SubBytes  u_sb_f (.state(stage[Nr-1]), .stateOut(sb_f));
    ShiftRows u_sr_f (.state(sb_f),        .stateOut(sr_f));
    AddRoundKey u_ark_f (.state(sr_f), .roundKey(rkf), .stateOut(ark_f));

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            out       <= 128'd0;
            out_valid <= 1'b0;
            valid[Nr] <= 1'b0;
        end else begin
            out       <= ark_f;
            valid[Nr] <= valid[Nr-1];
            out_valid <= valid[Nr-1];   // pulse when ciphertext emerges
        end
    end

endmodule

// ----------------------------------------------------------------------------
// Wrapper that runs sequential key expansion once, then streams blocks.
// Exposes a simple ready/valid for data and a "key_ready" when keys exist.
// ----------------------------------------------------------------------------
module AESEncrypt128_Pipelined_DUT #(parameter Nk = 4, parameter Nr = 10) (
    input  wire         clk,
    input  wire         reset,

    // Key expansion control
    input  wire         start,         // pulse to start key expansion
    input  wire [127:0] key,
    output wire         key_ready,     // goes high when all round keys ready

    // Streaming plaintext in
    input  wire [127:0] data,
    input  wire         data_valid,    // assert 1 to present a new block
    output wire         data_ready,    // 1 when the core can accept (no backpressure here)

    // Streaming ciphertext out
    output wire [127:0] out,
    output wire         done           // pulses 1 when a ciphertext is valid
);
    // Debounce/edge detect "start" for the sequential key expander
    reg start_q;
    wire start_pulse = start & ~start_q;

    always @(posedge clk or posedge reset) begin
        if (reset) start_q <= 1'b0;
        else       start_q <= start;
    end

    // Round keys storage from sequential key expansion
    wire [((Nr+1)*128)-1:0] allKeys;
    wire keys_ready;

    KeyExpansion_Sequential #(Nk, Nr) u_keyexp (
        .clk    (clk),
        .reset  (reset),
        .start  (start_pulse),
        .key    (key),
        .allKeys(allKeys),
        .ready  (keys_ready)
    );

    // Simple "always-ready" once keys exist (no backpressure).
    assign data_ready = keys_ready;

    // Load a new block only when keys are ready and testbench asserts data_valid.
    wire load = data_valid & data_ready;

    AESEncrypt_PipelineCore #(Nk, Nr) u_core (
        .clk      (clk),
        .reset    (reset),
        .data     (data),
        .load     (load),
        .allKeys  (allKeys),
        .out      (out),
        .out_valid(done)
    );

    assign key_ready = keys_ready;

endmodule

`default_nettype wire

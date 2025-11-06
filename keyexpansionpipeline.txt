// ============================================================================
// FILE: KeyExpansion_Pipelined_Optimized.v
// Description: Ultra-Optimized Pipelined Key Expansion
// Precomputes all keys in parallel for maximum frequency
// ============================================================================

module KeyExpansion_Pipelined_Optimized #(parameter Nk = 4, parameter Nr = 10) (
    input clk,
    input reset,
    input start,
    input [Nk * 32 - 1:0] key,
    output reg [((Nr + 1) * 128) - 1:0] allKeys,
    output reg ready
);

    // Precompute all round keys in parallel with deep pipelining
    reg [127:0] key_reg;
    reg start_reg;
    
    // Individual round key computation with pipelining
    wire [127:0] round_key [0:Nr];
    
    // Register all intermediate computations
    reg [127:0] round_key_reg [0:Nr];
    reg valid_pipe [0:Nr];
    
    // Initial key
    assign round_key[0] = key;
    
    // Generate pipelined round key computations
    genvar i;
    generate
        for (i = 1; i <= Nr; i = i + 1) begin : key_expansion_pipeline
            // Each key expansion stage has its own pipeline registers
            wire [127:0] key_in = (i == 1) ? key_reg : round_key_reg[i-1];
            wire [127:0] key_out;
            
            KeyExpansionRound_Single #(Nk, Nr, i) keyRound(
                .clk(clk),
                .keyIn(key_in),
                .keyOut(key_out)
            );
            
            // Pipeline register for each key computation
            always @(posedge clk or posedge reset) begin
                if (reset) begin
                    round_key_reg[i] <= 128'd0;
                    valid_pipe[i] <= 1'b0;
                end else begin
                    round_key_reg[i] <= key_out;
                    valid_pipe[i] <= (i == 1) ? start_reg : valid_pipe[i-1];
                end
            end
            
            assign round_key[i] = round_key_reg[i];
        end
    endgenerate
    
    // Input registration
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            key_reg <= 128'd0;
            start_reg <= 1'b0;
            ready <= 1'b0;
            allKeys <= {(Nr+1)*128{1'b0}};
        end else begin
            key_reg <= key;
            start_reg <= start;
            
            // Assemble all keys with proper timing
            if (valid_pipe[Nr]) begin
                allKeys[((Nr + 1) * 128) - 1 -: 128] <= key_reg; // Round 0 key
                for (int j = 1; j <= Nr; j++) begin
                    allKeys[((Nr + 1) * 128) - 1 - j * 128 -: 128] <= round_key_reg[j];
                end
                ready <= 1'b1;
            end else begin
                ready <= 1'b0;
            end
        end
    end

endmodule

// Single Round Key Expansion with internal pipelining
module KeyExpansionRound_Single #(parameter Nk = 4, parameter Nr = 10, parameter round = 1) (
    input clk,
    input [127:0] keyIn,
    output reg [127:0] keyOut
);
    
    // Internal pipeline registers for key expansion
    reg [31:0] temp_reg;
    reg [31:0] sub_word_reg;
    reg [31:0] rcon_applied_reg;
    reg [127:0] key_stage1, key_stage2, key_stage3;
    
    // RCON values - precomputed constants
    wire [31:0] Rcon [1:10];
    assign Rcon[1] = 32'h01000000;
    assign Rcon[2] = 32'h02000000;
    assign Rcon[3] = 32'h04000000;
    assign Rcon[4] = 32'h08000000;
    assign Rcon[5] = 32'h10000000;
    assign Rcon[6] = 32'h20000000;
    assign Rcon[7] = 32'h40000000;
    assign Rcon[8] = 32'h80000000;
    assign Rcon[9] = 32'h1B000000;
    assign Rcon[10] = 32'h36000000;
    
    // Stage 1: Extract and rotate temp
    wire [31:0] temp = keyIn[31:0];
    wire [31:0] temp_rot = {temp[23:0], temp[31:24]};
    
    always @(posedge clk) begin
        temp_reg <= temp_rot;
    end
    
    // Stage 2: SubWord
    wire [31:0] sub_word;
    SubWord sw(
        .word_in(temp_reg),
        .word_out(sub_word)
    );
    
    always @(posedge clk) begin
        sub_word_reg <= sub_word;
        key_stage1 <= keyIn;
    end
    
    // Stage 3: Apply Rcon
    wire [31:0] rcon_applied = sub_word_reg ^ Rcon[round];
    
    always @(posedge clk) begin
        rcon_applied_reg <= rcon_applied;
        key_stage2 <= key_stage1;
    end
    
    // Stage 4: Generate new key
    wire [127:0] new_key;
    assign new_key[127:96] = key_stage2[127:96] ^ rcon_applied_reg;
    assign new_key[95:64] = key_stage2[95:64] ^ new_key[127:96];
    assign new_key[63:32] = key_stage2[63:32] ^ new_key[95:64];
    assign new_key[31:0] = key_stage2[31:0] ^ new_key[63:32];
    
    always @(posedge clk) begin
        keyOut <= new_key;
    end

endmodule

// 32-bit SubWord module
module SubWord(word_in, word_out);
    input [31:0] word_in;
    output [31:0] word_out;
    
    genvar i;
    generate
        for (i = 0; i < 4; i = i + 1) begin : byte_sub
            SubTable st(
                .in(word_in[i*8 +: 8]),
                .out(word_out[i*8 +: 8])
            );
        end
    endgenerate
endmodule
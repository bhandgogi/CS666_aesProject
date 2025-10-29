// ============================================================================
// FILE: AESEncrypt_Pipelined.v
// Description: Fully Pipelined AES-128 Encryption (11 stages, 1 block/cycle)
// Author: Pipelined AES Implementation
// ============================================================================

module AESEncrypt_Pipelined #(parameter Nk = 4, parameter Nr = 10) (
    input clk,
    input reset,
    input [127:0] data,
    input data_valid,
    input [((Nr + 1) * 128) - 1:0] allKeys,
    output reg [127:0] out,
    output reg done
);

    reg [127:0] stage [0:Nr];
    reg valid [0:Nr];
    
    wire [127:0] stage0_out;
    AddRoundKey ark0(
        .state(data),
        .roundKey(allKeys[((Nr + 1) * 128) - 1 -: 128]),
        .stateOut(stage0_out)
    );
    
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


module AESEncrypt128_Pipelined_DUT (
    input [127:0] data,
    input [127:0] key,
    input clk,
    input reset,
    input start,
    output [127:0] out,
    output done,
    output key_ready
);

    localparam Nk = 4;
    localparam Nr = 10;
    
    wire [((Nr + 1) * 128) - 1:0] allKeys;
    wire keys_ready;
    
    reg start_key_exp;
    reg prev_start;
    
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
    
    KeyExpansion_Sequential #(Nk, Nr) keyExp(
        .clk(clk),
        .reset(reset),
        .start(start_key_exp),
        .key(key),
        .allKeys(allKeys),
        .ready(keys_ready)
    );
    
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

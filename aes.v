module AESEncrypt128_UltraOptimized (
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
    
    // Key expansion with improved start detection
    KeyExpansion_Pipelined_Optimized #(Nk, Nr) keyExp(
        .clk(clk),
        .reset(reset),
        .start(start),
        .key(key),
        .allKeys(allKeys),
        .ready(keys_ready)
    );
    
    // Encryption pipeline
    AESEncrypt_Pipelined_Optimized #(Nk, Nr) aesEnc(
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
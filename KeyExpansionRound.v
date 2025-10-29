// KeyExpansionRound.v
// Generates the next round key from the current key (AES-128)

module KeyExpansionRound #(parameter Nk = 4, parameter Nr = 10) (
    input [3:0] roundCount,      // Round number
    input [127:0] keyIn,         // Current round key
    output [127:0] keyOut        // Next round key
);

    // AES Rcon table (round constants)
    reg [31:0] Rcon [0:9];
    initial begin
        Rcon[0] = 32'h01000000;
        Rcon[1] = 32'h02000000;
        Rcon[2] = 32'h04000000;
        Rcon[3] = 32'h08000000;
        Rcon[4] = 32'h10000000;
        Rcon[5] = 32'h20000000;
        Rcon[6] = 32'h40000000;
        Rcon[7] = 32'h80000000;
        Rcon[8] = 32'h1b000000;
        Rcon[9] = 32'h36000000;
    end

    // Split current key into 4 words
    wire [31:0] w0 = keyIn[127:96];
    wire [31:0] w1 = keyIn[95:64];
    wire [31:0] w2 = keyIn[63:32];
    wire [31:0] w3 = keyIn[31:0];

    // RotWord and SubWord operations (S-box substitution)
    function [31:0] SubWord;
        input [31:0] word;
        reg [7:0] sbox [0:255];
        integer i;
        begin
            // Initialize S-box (AES standard S-box)
            // [To save space, use an external file or include directive in real design]
            // Example: sbox[8'h00] = 8'h63; ... etc
            for (i = 0; i < 256; i = i + 1)
                sbox[i] = i; // Dummy substitution, replace with real AES S-box

            SubWord = {sbox[word[23:16]], sbox[word[15:8]], sbox[word[7:0]], sbox[word[31:24]]};
        end
    endfunction

    wire [31:0] temp = SubWord({w3[23:0], w3[31:24]}) ^ Rcon[roundCount - 1];

    // Generate new round key words
    wire [31:0] w4 = w0 ^ temp;
    wire [31:0] w5 = w1 ^ w4;
    wire [31:0] w6 = w2 ^ w5;
    wire [31:0] w7 = w3 ^ w6;

    assign keyOut = {w4, w5, w6, w7};

endmodule

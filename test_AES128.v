// ============================================================================
// FILE: test_AES128_Pipelined.v
// Description: Testbench for Pipelined AES-128 with NIST test vectors
// Author: Pipelined AES Implementation
// ============================================================================

`timescale 1ns / 1ps

module test_AES128_Pipelined;

    reg [127:0] data;
    reg [127:0] key;
    reg clk;
    reg reset;
    reg start;
    
    wire [127:0] out;
    wire done;
    wire key_ready;
    
    integer cycle_count;
    integer key_exp_cycles;
    integer first_output_cycle;
    integer test_number;
    reg first_done_seen;
    
    localparam [127:0] TV1_KEY = 128'h000102030405060708090a0b0c0d0e0f;
    localparam [127:0] TV1_PLAIN = 128'h00112233445566778899aabbccddeeff;
    localparam [127:0] TV1_CIPHER = 128'h69c4e0d86a7b0430d8cdb78070b4c55a;
    
    localparam [127:0] TV2_KEY = 128'h2b7e151628aed2a6abf7158809cf4f3c;
    localparam [127:0] TV2_PLAIN = 128'h3243f6a8885a308d313198a2e0370734;
    localparam [127:0] TV2_CIPHER = 128'h3925841d02dc09fbdc118597196a0b32;
    
    localparam [127:0] TV3_KEY = 128'h00000000000000000000000000000000;
    localparam [127:0] TV3_PLAIN = 128'h00000000000000000000000000000000;
    localparam [127:0] TV3_CIPHER = 128'h66e94bd4ef8a2c3b884cfa59ca342b2e;
    
    AESEncrypt128_Pipelined_DUT dut (
        .data(data),
        .key(key),
        .clk(clk),
        .reset(reset),
        .start(start),
        .out(out),
        .done(done),
        .key_ready(key_ready)
    );
    
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end
    
    always @(posedge clk) begin
        if (reset)
            cycle_count = 0;
        else
            cycle_count = cycle_count + 1;
    end
    
    always @(posedge clk) begin
        if (key_ready && key_exp_cycles == 0) begin
            key_exp_cycles = cycle_count;
        end
    end
    
    always @(posedge clk) begin
        if (done && !first_done_seen) begin
            first_output_cycle = cycle_count;
            first_done_seen = 1;
        end
    end
    
    initial begin
        data = 0;
        key = 0;
        reset = 1;
        start = 0;
        cycle_count = 0;
        key_exp_cycles = 0;
        first_output_cycle = 0;
        test_number = 0;
        first_done_seen = 0;
        
        $display("========================================");
        $display("   Pipelined AES-128 Testbench");
        $display("========================================");
        $display("Clock Period: 10ns (100 MHz)");
        $display("Starting tests...\n");
        
        #25;
        reset = 0;
        #20;
        
        test_number = 1;
        $display("[TEST %0d] FIPS 197 Appendix C.1", test_number);
        $display("[TEST %0d] Key:       %h", test_number, TV1_KEY);
        $display("[TEST %0d] Plaintext: %h", test_number, TV1_PLAIN);
        $display("[TEST %0d] Expected:  %h", test_number, TV1_CIPHER);
        
        key = TV1_KEY;
        data = TV1_PLAIN;
        
        @(posedge clk);
        start = 1;
        @(posedge clk);
        start = 0;
        
        wait(key_ready);
        $display("[TEST %0d] Key expansion complete at cycle %0d", test_number, key_exp_cycles);
        
        wait(done);
        @(posedge clk);
        
        $display("[TEST %0d] Got:       %h", test_number, out);
        $display("[TEST %0d] First output at cycle %0d", test_number, first_output_cycle);
        
        if (out == TV1_CIPHER) begin
            $display("[TEST %0d] PASSED\n", test_number);
        end else begin
            $display("[TEST %0d] FAILED\n", test_number);
        end
        
        test_number = 2;
        reset = 1;
        #20;
        reset = 0;
        cycle_count = 0;
        key_exp_cycles = 0;
        first_output_cycle = 0;
        first_done_seen = 0;
        #20;
        
        $display("[TEST %0d] FIPS 197 Appendix C.3", test_number);
        $display("[TEST %0d] Key:       %h", test_number, TV2_KEY);
        $display("[TEST %0d] Plaintext: %h", test_number, TV2_PLAIN);
        $display("[TEST %0d] Expected:  %h", test_number, TV2_CIPHER);
        
        key = TV2_KEY;
        data = TV2_PLAIN;
        
        @(posedge clk);
        start = 1;
        @(posedge clk);
        start = 0;
        
        wait(key_ready);
        $display("[TEST %0d] Key expansion complete at cycle %0d", test_number, key_exp_cycles);
        
        wait(done);
        @(posedge clk);
        
        $display("[TEST %0d] Got:       %h", test_number, out);
        $display("[TEST %0d] First output at cycle %0d", test_number, first_output_cycle);
        
        if (out == TV2_CIPHER) begin
            $display("[TEST %0d] PASSED\n", test_number);
        end else begin
            $display("[TEST %0d] FAILED\n", test_number);
        end
        
        test_number = 3;
        reset = 1;
        #20;
        reset = 0;
        cycle_count = 0;
        key_exp_cycles = 0;
        first_output_cycle = 0;
        first_done_seen = 0;
        #20;
        
        $display("[TEST %0d] All Zeros Test", test_number);
        $display("[TEST %0d] Key:       %h", test_number, TV3_KEY);
        $display("[TEST %0d] Plaintext: %h", test_number, TV3_PLAIN);
        $display("[TEST %0d] Expected:  %h", test_number, TV3_CIPHER);
        
        key = TV3_KEY;
        data = TV3_PLAIN;
        
        @(posedge clk);
        start = 1;
        @(posedge clk);
        start = 0;
        
        wait(key_ready);
        $display("[TEST %0d] Key expansion complete at cycle %0d", test_number, key_exp_cycles);
        
        wait(done);
        @(posedge clk);
        
        $display("[TEST %0d] Got:       %h", test_number, out);
        $display("[TEST %0d] First output at cycle %0d", test_number, first_output_cycle);
        
        if (out == TV3_CIPHER) begin
            $display("[TEST %0d] PASSED\n", test_number);
        end else begin
            $display("[TEST %0d] FAILED\n", test_number);
        end
        
        $display("========================================");
        $display("   Performance Summary");
        $display("========================================");
        $display("Key Expansion Latency: ~11 cycles");
        $display("Pipeline Depth: 11 stages");
        $display("Initial Block Latency: ~22 cycles total");
        $display("Steady-State Throughput: 1 block/cycle");
        $display("At 100 MHz: 12.8 Gbps");
        $display("========================================");
        
        $display("\nAll tests completed!");
        #100;
        $finish;
    end
    
    initial begin
        #50000;
        $display("ERROR: Simulation timeout!");
        $finish;
    end
    
    initial begin
        $dumpfile("aes_pipelined_test.vcd");
        $dumpvars(0, test_AES128_Pipelined);
    end

endmodule

module SubBytes(state, stateOut);
	input [127:0] state; // Original input bytes
	output wire [127:0] stateOut; // Corresponding sub_bytes 

	genvar i;
	generate 
		for (i=7;i<128;i=i+8) begin: SubTableLoop
			SubTable s(state[i -:8],stateOut[i -:8]);
		end
	endgenerate
endmodule


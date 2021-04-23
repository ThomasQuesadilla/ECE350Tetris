module mux32_4(out, select, in0, in1, in2, in3);
	input [1:0] select;
	input [31:0] in0, in1, in2, in3;
	output [31:0] out;
	wire [31:0] w1, w2;
	mux32_2 m0(w1, select[0], in0, in1);
	mux32_2 m1(w2, select[0], in2, in3);
	mux32_2 m2(out, select[1], w1, w2);
endmodule
module mux32_2(out, select, in0, in1);
	input select;
	input [31:0] in0, in1;
	output [31:0] out;
	
	genvar i;
	generate
		for (i = 0; i < 32; i = i + 1)
		begin
			assign out[i] = select ? in1[i] : in0[i];
		end
	endgenerate
endmodule 
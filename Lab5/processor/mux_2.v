// Mux that we need :) [From one of the labs :)]
module mux_2(out, select, in0, in1);
	input select;
	input in0, in1;
	output out;
	assign out = select ? in1 : in0;
endmodule 
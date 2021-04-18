module register_5(clk, in, write_enable, out, ctrl_reset);
	input clk, write_enable, ctrl_reset;
	input [4:0] in;

	output [4:0] out;

	wire ctrl_reset_not;
	not n1(ctrl_reset_not, ctrl_reset);

	genvar i;
	generate
		for (i = 0; i < 5; i = i + 1)
		begin
			//  dffe_ref (q, d, clk, en, clr);
			dffe_ref dff(out[i], in[i], clk, write_enable, ctrl_reset); // This was causing errors
		end
	endgenerate
endmodule
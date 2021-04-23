module register(clk, in, write_enable, out, ctrl_reset);
	input clk, write_enable, ctrl_reset;
	input [31:0] in;

	output [31:0] out;

	wire ctrl_reset_not;
	not n1(ctrl_reset_not, ctrl_reset);
	
	// assign asynch_ctrl = 1;

	genvar i;
	generate
		for (i = 0; i < 32; i = i + 1)
		begin
			//  dffe_ref (q, d, clk, en, clr);
			dffe_ref dff(out[i], in[i], clk, write_enable, ctrl_reset); // This was causing errors
		end
	endgenerate
endmodule
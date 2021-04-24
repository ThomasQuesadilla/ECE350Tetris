module regfile (
	clock,
	ctrl_writeEnable, ctrl_reset, ctrl_writeReg,
	ctrl_readRegA, ctrl_readRegB, data_writeReg,
	data_readRegA, data_readRegB
);

	input clock, ctrl_writeEnable, ctrl_reset;
	input [4:0] ctrl_writeReg, ctrl_readRegA, ctrl_readRegB;
	input [31:0] data_writeReg;

	// can we do if statements?


	output [31:0] data_readRegA, data_readRegB;

	// add your code here
	wire [31:0] write_select;
	decoder_32 d1(write_select, ctrl_writeReg);

	wire [31:0] read_select_A;
	decoder_32 d2(read_select_A, ctrl_readRegA);

	wire [31:0] read_select_B;
	decoder_32 d3(read_select_B, ctrl_readRegB);

	wire [31:0] reg_write_bits;
	wire [1023:0] reg_data;

	// we love genvar haha
	genvar i;
	generate
		for (i = 0; i < 31; i = i + 1)
		begin
			and a1(reg_write_bits[i], ctrl_writeEnable, write_select[i]);

		end
	endgenerate 

	generate
		for (i = 0; i < 31; i = i + 1)
		begin
			if (i == 0)
				register r1(clock, 32'b0, 1'b0, reg_data[32*i+31:32*i], ctrl_reset);
			else
				// (clk, in, write_enable, out, ctrl_reset)
				register r1(clock, data_writeReg, reg_write_bits[i], reg_data[32*i+31:32*i], ctrl_reset);
			
		end
	endgenerate
	
	and a1(reg_write_bits[31], write_select[31], ctrl_writeEnable);
	
	register reg1(clock, data_writeReg, reg_write_bits[31], reg_data[1023:992], ctrl_reset);

	generate
		for (i = 0; i < 1024; i = i + 1)
		begin
			tristate t1(reg_data[i], read_select_A[i/32], data_readRegA[i%32]);
		end
	endgenerate

	generate
		for (i = 0; i < 1024; i = i + 1)
		begin
			tristate t2(reg_data[i], read_select_B[i/32], data_readRegB[i%32]);
		end
	endgenerate
endmodule

// This was provided
module tristate(in, oe, out);
	input in, oe;
	output out;

	assign out = oe ? in : 1'bz;
endmodule

// Decoder Module COMPLETE
module decoder_32(out, in);
	input [4:0] in;
	output [31:0] out;
	
	// Let's do it the long way yeet

	// do complement wires
	wire in0_not, in1_not, in2_not, in3_not, in4_not;

	not n1(in0_not, in[0]);
	not n2(in1_not, in[1]);
	not n3(in2_not, in[2]);
	not n4(in3_not, in[3]);
	not n5(in4_not, in[4]);

	and and1(out[0], in0_not, in1_not, in2_not, in3_not, in4_not);
	and and2(out[1], in[0], in1_not, in2_not, in3_not, in4_not);
	and and3(out[2], in0_not, in[1], in2_not, in3_not, in4_not);
	and and4(out[3], in[0], in[1], in2_not, in3_not, in4_not);
	
	and and5(out[4], in0_not, in1_not, in[2], in3_not, in4_not);
	and and6(out[5], in[0], in1_not, in[2], in3_not, in4_not);
	and and7(out[6], in0_not, in[1], in[2], in3_not, in4_not);
	and and8(out[7], in[0], in[1], in[2], in3_not, in4_not);
	
	and and9(out[8], in0_not, in1_not, in2_not, in[3], in4_not);
	and and10(out[9], in[0], in1_not, in2_not, in[3], in4_not);
	and and11(out[10], in0_not, in[1], in2_not, in[3], in4_not);
	and and12(out[11], in[0], in[1], in2_not, in[3], in4_not);
	
	and and13(out[12], in0_not, in1_not, in[2], in[3], in4_not);
	and and14(out[13], in[0], in1_not, in[2], in[3], in4_not);
	and and15(out[14], in0_not, in[1], in[2], in[3], in4_not);
	and and16(out[15], in[0], in[1], in[2], in[3], in4_not);
	
	and and17(out[16], in0_not, in1_not, in2_not, in3_not, in[4]);
	and and18(out[17], in[0], in1_not, in2_not, in3_not, in[4]);
	and and19(out[18], in0_not, in[1], in2_not, in3_not, in[4]);
	and and20(out[19], in[0], in[1], in2_not, in3_not, in[4]);
	
	and and21(out[20], in0_not, in1_not, in[2], in3_not, in[4]);
	and and22(out[21], in[0], in1_not, in[2], in3_not, in[4]);
	and and23(out[22], in0_not, in[1], in[2], in3_not, in[4]);
	and and24(out[23], in[0], in[1], in[2], in3_not, in[4]);
	
	and and25(out[24], in0_not, in1_not, in2_not, in[3], in[4]);
	and and26(out[25], in[0], in1_not, in2_not, in[3], in[4]);
	and and27(out[26], in0_not, in[1], in2_not, in[3], in[4]);
	and and28(out[27], in[0], in[1], in2_not, in[3], in[4]);
	
	and and29(out[28], in0_not, in1_not, in[2], in[3], in[4]);
	and and30(out[29], in[0], in1_not, in[2], in[3], in[4]);
	and and31(out[30], in0_not, in[1], in[2], in[3], in[4]);
	and and32(out[31], in[0], in[1], in[2], in[3], in[4]);

endmodule
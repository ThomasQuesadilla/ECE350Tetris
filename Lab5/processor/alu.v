module alu(data_operandA, data_operandB, ctrl_ALUopcode, ctrl_shiftamt, data_result, isNotEqual, isLessThan, overflow);
	input [31:0] data_operandA, data_operandB;
	input [4:0] ctrl_ALUopcode, ctrl_shiftamt;

	output [31:0] data_result;
	output isNotEqual, isLessThan, overflow;
	
	// add your code here

	// Declaring wires for the outputs
	wire [31:0] andd, orr, sll_result, sra_result, sum_result, b_result, shift_result, all_not_sum, and_or_result;
	wire sub_ctrl; // added this because we have to invert the bits

	// add_op(.result(add_result), .A(data_operandA), .B(data_operandB));
	// or_op(.result(or_result), .A(data_operandA), .B(data_operandB));

	// Do operations
	sll_op left_shift(.result(sll_result), .ctrl(ctrl_shiftamt), .A(data_operandA));
	sra_op right_shift(.result(sra_result), .ctrl(ctrl_shiftamt), .A(data_operandA));
	
	wire not_ctrl_ALUopcode1, not_ctrl_ALUopcode2;
	not not1(not_ctrl_ALUopcode1, ctrl_ALUopcode[1]);
	not not2(not_ctrl_ALUopcode2, ctrl_ALUopcode[2]);
	
	and subC(sub_ctrl, not_ctrl_ALUopcode1, ctrl_ALUopcode[0]); // Lower bits have to be 01 for subtraction

	// inverting bits cause my dumb self was using ~
	wire [31:0] not_data_operandB;
	genvar i;
	generate
		for (i = 0; i < 32; i = i + 1)
		begin
			not foo(not_data_operandB[i], data_operandB[i]);
		end
	endgenerate

	 // for the generate!
	generate
		// initiate for loop
		for (i = 0; i < 32; i = i + 1)
		begin
			// mux_2(out, select, in0, in1);
			mux_2 muxT(.out(b_result[i]), .select(sub_ctrl), .in0(data_operandB[i]), .in1(not_data_operandB[i]));
		end
		
	endgenerate

	// Operations necessary for adder
	// Necessary info for adder -> CLA implementation

	//(A, B, ctrl, prop, gen, sum);
	add_op adder(.sum(sum_result), .A(data_operandA), .B(b_result), .ctrl(sub_ctrl), .prop(orr), .gen(andd));
	
	wire sum_ctrl;
	// If its the adder's turn to shine :)
	and sum_summoned(sum_ctrl, not_ctrl_ALUopcode2, not_ctrl_ALUopcode1);

	// generate time lol
	generate
		// for loop time
		for (i = 0; i < 32; i = i + 1)
		begin
			// bring the action

			// need to add everything but add and and/or
			// more muxes? but why tho :,) -> to grab those answers duh!
			// mux_2(out, select, in0, in1); (keep forgetting the input order yike)
			mux_2 m1(.out(shift_result[i]), .select(ctrl_ALUopcode[0]), .in0(sll_result[i]), .in1(sra_result[i]));
			mux_2 m2(.out(and_or_result[i]), .select(ctrl_ALUopcode[0]), .in0(andd[i]), .in1(orr[i]));
			mux_2 m3(.out(all_not_sum[i]), .select(ctrl_ALUopcode[2]), .in0(and_or_result[i]), .in1(shift_result[i])); 
			mux_2 m4(.out(data_result[i]), .select(sum_ctrl), .in0(all_not_sum[i]), .in1(sum_result[i]));
		end
	endgenerate

	// bring the action -> isnotequal time
	// isnotequal = if any bit = 1, breaking up into 8 cause 8 is cute ><
	// ERROR IS HERE
	or or_1(isNotEqual, sum_result[0], sum_result[1], sum_result[2], sum_result[3], sum_result[4], sum_result[5], sum_result[6], sum_result[7], sum_result[8], sum_result[9], sum_result[10], sum_result[11], sum_result[12], sum_result[13], sum_result[14], sum_result[15], sum_result[16], sum_result[17], sum_result[18], sum_result[19], sum_result[20], sum_result[21], sum_result[22], sum_result[23], sum_result[24], sum_result[25], sum_result[26], sum_result[27], sum_result[28], sum_result[29], sum_result[30], sum_result[31]);

	wire not_sum_result;
	not not5(not_sum_result, sum_result[31]);

	// all eyes on us -> isLessThan
	// mux time? -> I think? --> Need to figure this out
	mux_2 less_mux(.out(isLessThan), .select(overflow), .in0(sum_result[31]), .in1(not_sum_result));

	// I want to scream and shout -> Overflow
	// So we have to check the last bits and sum
	wire not_data_opA, not_data_opB;
	not not3(not_data_opA, data_operandA[31]);
	not not4(not_data_opB, data_operandB[31]);
	

	wire w5, w6, w7, w8, w9, w10;
	and and_1(w5, not_data_opA, not_data_opB, sum_result[31]);
	and and_2(w6, data_operandA[31], data_operandB[31], not_sum_result);
	or or_5(w7, w5, w6);

	and and_3(w8, data_operandA[31], not_data_opB, not_sum_result);
	and and_4(w9, not_data_opA, data_operandB[31], sum_result[31]);
	or or_6(w10, w8, w9);

	// probably another mux? -> scary the house
	mux_2 mux_o(.out(overflow), .select(sub_ctrl), .in0(w7), .in1(w10));
	

endmodule

// completed
module sll_op(result, ctrl, A);
	// gotta declare my variables~
	input [31:0] A;
	input [4:0] ctrl;
	output [31:0] result;
	
	// TODO here: insert scary code here~
	// I'm a believer, believer
	
	// similar to our cool sla :,)

	// TODO here
	// We need to pass the sra modules we created like a cascade
	wire [31:0] sll16_result, sll8_result, sll4_result, sll2_result, sll1_result;
	wire [31:0] sll8_in, sll4_in, sll2_in, sll1_in;

	// I'm in love with Judas, J-U-D-Aa-S GAGA
	sll_16 sll16(.result(sll16_result), .A(A));

	// 16 first -> We are superstars ehm pratt stars
	genvar i;
	generate
		for (i = 0; i < 32; i = i + 1)
		begin
			// I be forgetting the input order yikeu
			//  mux_2(out, select, in0, in1)
			mux_2 foo(.out(sll8_in[i]), .select(ctrl[4]), .in0(A[i]), .in1(sll16_result[i]));
		end
	endgenerate

	sll_8 sll8(.result(sll8_result), .A(sll8_in));

	generate
		for (i = 0; i < 32; i = i + 1)
		begin
			mux_2 foo(.out(sll4_in[i]), .select(ctrl[3]), .in0(sll8_in[i]), .in1(sll8_result[i]));
		end
	endgenerate

	sll_4 sll4(.result(sll4_result), .A(sll4_in));

	// OooOOOOOAAOo I'll bring him down, down, down

	generate
		for (i = 0; i < 32; i = i + 1)
		begin 
			mux_2 foo(.out(sll2_in[i]), .select(ctrl[2]), .in0(sll4_in[i]), .in1(sll4_result[i]));
		end
	endgenerate

	sll_2 sll2(.result(sll2_result), .A(sll2_in));

	generate
		for (i = 0; i < 32; i = i + 1)
		begin
			mux_2 foo(.out(sll1_in[i]), .select(ctrl[1]), .in0(sll2_in[i]), .in1(sll2_result[i]));
		end
	endgenerate

	sll_1 sll1(.result(sll1_result), .A(sll1_in));

	// last generate uwu
	generate
		for (i = 0; i < 32; i = i + 1)
		begin
			mux_2 foo(.out(result[i]), .select(ctrl[0]), .in0(sll1_in[i]), .in1(sll1_result[i]));
		end
	endgenerate

	// yay method complete wooooo
endmodule

// start of the modules for sll1, sll2, sll4, sll8, sll816 :)

module sll_16(result, A);
	input [31:0] A;
	output [31:0] result; 

	assign result[15:0] = 16'b0000000000000000;
	assign result[31:16] = A[15:0];

endmodule

module sll_8(result, A);
	input [31:0] A;
	output [31:0] result;

	assign result[7:0] = 8'b00000000;
	assign result[31:8] = A[23:0];
endmodule

module sll_4(result, A);
	input [31:0] A;
	output [31:0] result;

	assign result[3:0] = 4'b0000;
	assign result[31:4] = A[27:0];

endmodule

module sll_2(result, A);
	input [31:0] A;
	output [31:0] result;

	assign result[1:0] = 2'b00;
	assign result[31:2] = A[29:0];

endmodule

module sll_1(result, A);
	input [31:0] A;
	output [31:0] result;

	assign result[0] = 1'b0;
	assign result[31:1] = A[30:0];

endmodule

// completed
module sra_op(result, ctrl, A);
	input [31:0] A;
	input [4:0] ctrl;
	output [31:0] result;

	// TODO here
	// We need to pass the sra modules we created like a cascade
	wire [31:0] sra16_result, sra8_result, sra4_result, sra2_result, sra1_result;
	wire [31:0] sra8_in, sra4_in, sra2_in, sra1_in;

	// I'm in love with Judas, J-U-D-Aa-S GAGA
	sra_16 sra16(.result(sra16_result), .A(A));

	// 16 first -> We are superstars ehm pratt stars
	genvar i;
	generate
		for (i = 0; i < 32; i = i + 1)
		begin
			// I be forgetting the input order yikeu
			//  mux_2(out, select, in0, in1)
			mux_2 foo(.out(sra8_in[i]), .select(ctrl[4]), .in0(A[i]), .in1(sra16_result[i]));
		end
	endgenerate

	sra_8 sra8(.result(sra8_result), .A(sra8_in));

	generate
		for (i = 0; i < 32; i = i + 1)
		begin
			mux_2 foo(.out(sra4_in[i]), .select(ctrl[3]), .in0(sra8_in[i]), .in1(sra8_result[i]));
		end
	endgenerate

	sra_4 sra4(.result(sra4_result), .A(sra4_in));

	// OooOOOOOAAOo I'll bring him down, down, down

	generate
		for (i = 0; i < 32; i = i + 1)
		begin 
			mux_2 foo(.out(sra2_in[i]), .select(ctrl[2]), .in0(sra4_in[i]), .in1(sra4_result[i]));
		end
	endgenerate

	sra_2 sr2(.result(sra2_result), .A(sra2_in));

	generate
		for (i = 0; i < 32; i = i + 1)
		begin
			mux_2 foo(.out(sra1_in[i]), .select(ctrl[1]), .in0(sra2_in[i]), .in1(sra2_result[i]));
		end
	endgenerate

	sra_1 sra1(.result(sra1_result), .A(sra1_in));

	// last generate uwu
	generate
		for (i = 0; i < 32; i = i + 1)
		begin
			mux_2 foo(.out(result[i]), .select(ctrl[0]), .in0(sra1_in[i]), .in1(sra1_result[i]));
		end
	endgenerate

	// yay method complete wooooo

endmodule

// start of modules for sra_1, sra_2, sra_4, sra_8, sra_16
module sra_16(result, A);
	input [31:0] A;
	output [31:0] result;

	assign result[15:0] = A[31:16];

	genvar i;
	generate
		for (i = 16; i < 32; i = i + 1)
		begin
			or foo(result[i], A[31], 1'b0); // wait why do we do this?
		end
	endgenerate

endmodule

module sra_8(result, A);
	input [31:0] A;
	output [31:0] result;

	assign result[23:0] = A[31:8];

	genvar i;
	generate
		for (i = 24; i < 32; i = i + 1)
		begin
			or foo(result[i], A[31], 1'b0);
		end
	endgenerate

endmodule

module sra_4(result, A);
	input [31:0] A;
	output [31:0] result;

	assign result[27:0] = A[31:4];
	
	genvar i;
	generate
		for (i = 28; i < 32; i = i + 1)
		begin 
			or foo(result[i], A[31], 1'b0);
		end
	endgenerate

endmodule

module sra_2(result, A);
	input [31:0] A;
	output [31:0] result;

	assign result[29:0] = A[31:2];

	genvar i;
	generate
		for (i = 30; i < 32; i = i + 1)
		begin
			or foo(result[i], A[31], 1'b0);
		end
	endgenerate

endmodule

module sra_1(result, A);
	input [31:0] A;
	output [31:0] result;

	assign result[30:0] = A[31:1];
	or foo(result[31], A[31], 1'b0);
endmodule
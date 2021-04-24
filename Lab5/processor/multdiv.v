module multdiv(
	data_operandA, data_operandB, 
	ctrl_MULT, ctrl_DIV, 
	clock, 
	data_result, data_exception, data_resultRDY);

    input [31:0] data_operandA, data_operandB;
    input ctrl_MULT, ctrl_DIV, clock;

    output [31:0] data_result;
    output data_exception, data_resultRDY;

    // add your code here
	wire isMult, isDiv;
	dffe_ref d0(isMult, ctrl_MULT, clock, ctrl_MULT | ctrl_DIV, 1'b0);
	dffe_ref d1(isDiv, ctrl_DIV, clock, ctrl_MULT | ctrl_DIV, 1'b0); // Not sure if its 1'b0

	wire overflow, zero, mult_ready, div_ready, div_by_zero;
	dffe_ref d2(.q(div_by_zero), .d(zero), .clk(clock), .en(ctrl_DIV));
	 
	wire [31:0] mult_result, div_result_pos;
	mult m0(data_operandA, data_operandB, ctrl_MULT, clock, mult_result, overflow, mult_ready);
	
	wire [31:0] data_operandA_div, data_operandB_div, data_operandA_neg, data_operandB_neg;
	negater n0(data_operandA, data_operandA_neg);
	negater n1(data_operandB, data_operandB_neg);
	mux32_2 m1(.in0(data_operandA), .in1(data_operandA_neg), .select(data_operandA[31]), .out(data_operandA_div));
	mux32_2 m2(.in0(data_operandB), .in1(data_operandB_neg), .select(data_operandB[31]), .out(data_operandB_div));
	 
	// divisor, dividend, start, clk, result, exception, result_ready
	div div0(data_operandB_div, data_operandA_div, ctrl_DIV, clock, div_result_pos, zero, div_ready);
	wire [31:0] div_result_neg, div_result, div_result_final;
	negater n2(div_result_pos, div_result_neg);
	
	wire div_result_sign, div_result_sign_final;
	xor div_sign(div_result_sign, data_operandA[31], data_operandB[31]);
	dffe_ref d3(div_result_sign_final, div_result_sign, clock, ctrl_DIV, 1'b0); // Added the 1'b0
	mux32_2 m3(.in0(div_result_pos), .in1(div_result_neg), .select(div_result_sign_final), .out(div_result));
	mux32_2 m4(.in0(div_result), .in1(32'b0), .select(div_by_zero), .out(div_result_final));

	wire data_resultRDY_intermediate;
	mux32_2 m5(.in0(div_result_final), .in1(mult_result), .select(isMult), .out(data_result));
	mux_2 m6(.in0(div_ready), .in1(mult_ready), .select(isMult), .out(data_resultRDY_intermediate));


	assign data_resultRDY = (isMult | isDiv) ? (data_resultRDY_intermediate) : (1'b0);
	assign data_exception = (isMult & overflow) | (isDiv & zero);
	
endmodule

// WORKING: cleaned code up, renamed things and also took out code from previous implementations that weren't working
module mult(multiplicand, multiplier, start, clk, result, exception, result_ready);
	input [31:0] multiplicand, multiplier;
	input start, clk;
	output result_ready, exception;
	output [31:0] result;

	// OKAY WE TRYING AGAIN LMAO
	
	// we broke up product into two buses
	wire [31:0] prod_1_in_after_mux;
	wire [31:0] prod_2_in_before_shift;
	wire [31:0] prod_1_in, prod_2_in;
	wire [31:0] prod_1_out, prod_2_out;
	
	// grab values
	wire [31:0] multiplicand_readout;
	
	register r0(.in(multiplicand), .out(multiplicand_readout), .write_enable(start), .clk(clk), .ctrl_reset(1'b0));

	// We use mux to check which value to choose
	mux32_2 m0(.in0(prod_1_in), .in1(multiplier), .select(start), .out(prod_1_in_after_mux));
	
	// Then we store first part of bus
	register p1(.in(prod_1_in_after_mux), .out(prod_1_out), .write_enable(1'b1), .clk(clk), .ctrl_reset(1'b0));
	// we do the same for second part bus
	register p2(.in(prod_2_in), .out(prod_2_out), .write_enable(1'b1), .clk(clk), .ctrl_reset(start));
	
	wire if_shift;
	
	// we have to use signed wires lolz
	wire signed [31:0] multiplcd, multiplcd_shifted;
	assign multiplcd = multiplicand_readout;
	assign multiplcd_shifted = multiplicand_readout << 1;
	
	wire [31:0] addsub_op1_pos;

	mux32_2 m1(.in0(multiplcd), .in1(multiplcd_shifted), .select(if_shift), .out(addsub_op1_pos));
	
	// Checking if we need to do subtraction uwu
	wire [31:0] addsub_op1_neg, addsub_op1;
	wire sub_ctrl; 
	assign addsub_op1_neg = ~addsub_op1_pos;
	// choosing between us doing the addsub operation and its complement and our select will tell us if we need to add or subtract
	mux32_2 m2(.in0(addsub_op1_pos), .in1(addsub_op1_neg), .select(sub_ctrl), .out(addsub_op1));
	
	wire [31:0] addsub_result, prop, gen;
	// Now we do the adding or subtracting uwu
	add_op add_sub(prod_2_out, addsub_op1, sub_ctrl, prop, gen, addsub_result);
	
	// unchanged or adding/subtracting result
	wire ifNothing;
	// another mux to figure out if we need the add/sub result or the nothing
	mux32_2 m3(.in0(addsub_result), .in1(prod_2_out), .select(ifNothing), .out(prod_2_in_before_shift));
	
	// shifting
	wire signed [63:0] before_shift, after_shift;
	assign before_shift[31:0] = prod_1_out;
	assign before_shift[63:32] = prod_2_in_before_shift;
	assign after_shift = before_shift >>> 2;
	assign prod_1_in = after_shift[31:0];
	assign prod_2_in = after_shift[63:32];
	
	// control
	wire bit1, bit0;
	wire helper;
	dffe_ref d1(helper, prod_1_out[1], clk, 1'b1, start);
	assign bit1 = prod_1_out[1];
	assign bit0 = prod_1_out[0];
	
	assign ifNothing = ((~bit1) & (~bit0) & (~helper)) | (bit1 & bit0 & helper);
	assign sub_ctrl = (bit1) & (((~bit0) & (~helper)) | ((bit0) & (~helper)) | ((~bit0) & (helper)));
	assign if_shift = ((bit1) & (~bit0) & (~helper)) | ((~bit1) & (bit0) & (helper));
	
	// counter
	counter_5 counter(.clk(clk), .reset(start), .result_ready(result_ready));

	// okay let's try something else lmaoooooo for overflow --> seems like we still fail overflow???
	wire no_overflow_neg, no_overflow_pos, unary;
	assign no_overflow_neg = prod_2_out[0] & prod_2_out[1] & prod_2_out[2] & prod_2_out[3] & prod_2_out[4] & prod_2_out[5] & prod_2_out[6] & prod_2_out[7]
	& prod_2_out[8] & prod_2_out[9] & prod_2_out[10] & prod_2_out[11] & prod_2_out[12] & prod_2_out[13] & prod_2_out[14] & prod_2_out[15] & prod_2_out[16]
	& prod_2_out[17] & prod_2_out[18] & prod_2_out[19] & prod_2_out[20] & prod_2_out[21] & prod_2_out[22] & prod_2_out[23] & prod_2_out[24]
	& prod_2_out[25] & prod_2_out[26] & prod_2_out[27] & prod_2_out[28] & prod_2_out[29] & prod_2_out[30] & prod_2_out[31];

	assign unary = prod_2_out[0] | prod_2_out[1] | prod_2_out[2] | prod_2_out[3] | prod_2_out[4] | prod_2_out[5] | prod_2_out[6] | prod_2_out[7]
	| prod_2_out[8] | prod_2_out[9] | prod_2_out[10] | prod_2_out[11] | prod_2_out[12] | prod_2_out[13] | prod_2_out[14] | prod_2_out[15] | prod_2_out[16]
	| prod_2_out[17] | prod_2_out[18] | prod_2_out[19] | prod_2_out[20] | prod_2_out[21] | prod_2_out[22] | prod_2_out[23] | prod_2_out[24]
	| prod_2_out[25] | prod_2_out[26] | prod_2_out[27] | prod_2_out[28] | prod_2_out[29] | prod_2_out[30] | prod_2_out[31];

	assign no_overflow_pos = ~prod_2_out[0] & ~prod_2_out[1] & ~prod_2_out[2] & ~prod_2_out[3] & ~prod_2_out[4] & ~prod_2_out[5] & ~prod_2_out[6] & ~prod_2_out[7]
	& ~prod_2_out[8] & ~prod_2_out[9] & ~prod_2_out[10] & ~prod_2_out[11] & ~prod_2_out[12] & ~prod_2_out[13] & ~prod_2_out[14] & ~prod_2_out[15] & ~prod_2_out[16]
	& ~prod_2_out[17] & ~prod_2_out[18] & ~prod_2_out[19] & ~prod_2_out[20] & ~prod_2_out[21] & ~prod_2_out[22] & ~prod_2_out[23] & ~prod_2_out[24]
	& ~prod_2_out[25] & ~prod_2_out[26] & ~prod_2_out[27] & ~prod_2_out[28] & ~prod_2_out[29] & ~prod_2_out[30] & ~prod_2_out[31];

	// doing other overflows cause we didn't account for them oops
	wire neg_overflow, neg1_overflow, pos_overflow;
	assign neg_overflow  = multiplicand[31] & multiplier[31] & prod_1_out[31];
	assign pos_overflow = ~multiplicand[31] & ~multiplier[31] & prod_1_out[31];

	wire ovf;
	assign ovf = ~((no_overflow_neg & prod_1_out[31]) | (no_overflow_pos & ~prod_1_out[31]));

	assign exception = (neg_overflow | pos_overflow | ovf);
	assign result = prod_1_out;

endmodule

module div(divisor, dividend, start, clk, result, exception, result_ready);
	input [31:0] divisor, dividend;
	input start, clk;
	output result_ready, exception;
	output [31:0] result;

	// exception occurs if divisor = 0;
	assign exception = ~(divisor[0] | divisor[1] | divisor[2] | divisor[3] | divisor[3] | divisor[4] | divisor[5] | divisor[6] | divisor[7] | divisor[8] | divisor[9]
	| divisor[10] | divisor[11] | divisor[12] | divisor[13] | divisor[14] | divisor[15] | divisor[16] | divisor[17] | divisor[18] | divisor[19] | divisor[20]
	| divisor[21] | divisor[22] | divisor[23] | divisor[24] | divisor[25] | divisor[26] | divisor[27] | divisor[28] | divisor[29] | divisor[30] | divisor[31]);

	// read divisor
	wire [31:0] divisor_readout;
	register r0(.in(divisor), .out(divisor_readout), .write_enable(start), .clk(clk), .ctrl_reset(1'b0));

	// read dividend
	wire [31:0] dividend_readout;
	register r1(.in(dividend), .out(dividend_readout), .write_enable(start), .clk(clk), .ctrl_reset(1'b0));

	// Getting quotient/remainder
	wire [31:0] quotient_in0, quotient_in, quotient_out, remainder_in;
	wire [31:0] remainder_out;
	
	mux32_2 m0(.in0(quotient_in0), .in1(dividend), .select(start), .out(quotient_in));
	register r2(.in(quotient_in), .out(quotient_out), .write_enable(1'b1), .clk(clk), .ctrl_reset(1'b0));
	register r3(.in(remainder_in), .out(remainder_out), .write_enable(1'b1), .clk(clk), .ctrl_reset(start));

	// Subtracting time
	wire [31:0] sub_operand2, sub_result, remainder_before_shift, prop, gen;
	assign sub_operand2 = ~divisor_readout;
	add_op a0(remainder_out, sub_operand2, 1'b1, prop, gen, sub_result);
	
	mux32_2 m1(.in0(sub_result), .in1(remainder_out), .select(sub_result[31]), .out(remainder_before_shift));
	
	wire [63:0] remainder_reg_before_shift, remainder_reg_after_shift;
	assign remainder_reg_before_shift[63:32] = remainder_before_shift;
	assign remainder_reg_before_shift[31:0] = quotient_out;
	assign remainder_reg_after_shift = remainder_reg_before_shift << 1;
	assign remainder_in = remainder_reg_after_shift[63:32];
	assign quotient_in0[31:1] = remainder_reg_after_shift[31:1];
	assign quotient_in0[0] = ~sub_result[31];
	
	assign result = quotient_out;
	
	counter_6 counter(clk, start, result_ready);

endmodule

module negater(in, out);

	input [31:0] in;
	output [31:0] out;
	
	wire [31:0] prop, gen;
	add_op n0(~in, 32'b0, 1'b1, prop, gen, out);

endmodule

module counter_5(clk, reset, result_ready);
	
	input clk, reset;
	output result_ready;
	
	wire w0;
	dffe_ref dff0(.q(w0), .d(~w0), .clk(clk), .en(1'b1), .clr(reset));
	
	wire w1;
	dffe_ref dff1(.q(w1), .d(~w1), .clk(~w0), .en(1'b1), .clr(reset));
	
	wire w2;
	dffe_ref dff2(.q(w2), .d(~w2), .clk(~w1), .en(1'b1), .clr(reset));
	
	wire w3;
	dffe_ref dff3(.q(w3), .d(~w3), .clk(~w2), .en(1'b1), .clr(reset));
	
	wire w4;
	dffe_ref dff4(.q(w4), .d(~w4), .clk(~w3), .en(1'b1), .clr(reset));
	
	and res(result_ready, ~w0, ~w1, ~w2, ~w3, w4);

endmodule

module counter_6(clk, reset, result_ready);

	input clk, reset;
	output result_ready;
	
	wire w0;
	dffe_ref dff0(.q(w0), .d(~w0), .clk(clk), .en(1'b1), .clr(reset));
	
	wire w1;
	dffe_ref dff1(.q(w1), .d(~w1), .clk(~w0), .en(1'b1), .clr(reset));
	
	wire w2;
	dffe_ref dff2(.q(w2), .d(~w2), .clk(~w1), .en(1'b1), .clr(reset));
	
	wire w3;
	dffe_ref dff3(.q(w3), .d(~w3), .clk(~w2), .en(1'b1), .clr(reset));
	
	wire w4;
	dffe_ref dff4(.q(w4), .d(~w4), .clk(~w3), .en(1'b1), .clr(reset));

	wire w5;
	dffe_ref dff(.q(w5), .d(~w5), .clk(~w4), .en(1'b1), .clr(reset));

	and res(result_ready, w0, ~w1, ~w2, ~w3, ~w4, w5);
endmodule
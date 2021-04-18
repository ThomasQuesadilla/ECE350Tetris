module add_op(A, B, ctrl, prop, gen, sum);
	input [31:0] A, B;
	input ctrl;
	
	output [31:0] prop, gen, sum;

	// TODO here -> Let me go make some intermediary things uwu
	// Okay we back after making our block/full adder
	wire [3:0] block_carry, block_gen, block_prop;
	assign block_carry[0] = ctrl;

	genvar i;
	generate
		for (i = 0; i < 4; i = i + 1)
		begin
			add_block_8 add1(.A(A[i*8+7:i*8]), .B(B[i*8+7:i*8]), .ctrl(block_carry[i]), .sum(sum[i*8+7:i*8]), .prop(block_prop[i]), .gen(block_gen[i]), .prop0(prop[i*8+7:i*8]), .gen0(gen[i*8+7:i*8]));
		end
	endgenerate

	// It's Britney b***h
	// all eyes on us
	wire w1;
	and and1(w1, block_prop[0], block_carry[0]);
	or or1(block_carry[1], w1, block_gen[0]);

	// scream and shout
	wire w2, w3;
	and and2(w2, block_prop[1], block_prop[0], block_carry[0]);
	and and3(w3, block_prop[1], block_gen[0]);
	or or2(block_carry[2], block_gen[1], w2, w3);

	// turn the sh*t up
	wire w4, w5, w6;
	and and4(w4, block_prop[2], block_prop[1], block_prop[0], block_carry[0]);
	and and5(w5, block_prop[2], block_prop[1], block_gen[0]);
	and and6(w6, block_prop[2], block_gen[1]);
	or or3(block_carry[3], block_gen[2], w4, w5, w6);

endmodule 

module add_block_8(A, B, ctrl, prop0, gen0, prop, gen, sum);
	input [7:0] A, B;
	input ctrl;
	output [7:0] prop0, gen0, sum;
	output prop, gen;

	wire [7:0] carry;

	assign carry[0] = ctrl;

	// genvar time uwu
	genvar i;
	generate
		for (i = 0; i < 8; i = i + 1)
		begin
			full_adder add1(.A(A[i]), .B(B[i]), .Cin(carry[i]), .prop(prop0[i]), .gen(gen0[i]), .S(sum[i]));
		end
	endgenerate

	// time to do the rest of the carry's
	// I am cool -> Hyuna is a queen period ><

	// carry 1 ;)
	wire w1;
	and and1(w1, prop0[0], carry[0]);
	or or1(carry[1], w1, gen0[0]);

	// carry 2 ;))
	wire w2, w3;
	and and2(w2, prop0[0], prop0[1], carry[0]);
	and and3(w3, prop0[1], gen0[0]);
	or or2(carry[2], gen0[1], w2, w3);

	// carry 3 ;)))
	wire w4, w5, w6;
	and and4(w4, carry[0], prop0[0], prop0[1], prop0[2]);
	and and5(w5, prop0[2], prop0[1], gen0[0]);
	and and6(w6, prop0[2], gen0[1]);
	or or3(carry[3], w4, w5, w6, gen0[2]);

	// carry 4 ;))))
	wire w7, w8, w9, w10;
	and and7(w7, prop0[3], prop0[2], prop0[1], prop0[0], carry[0]);
	and and8(w8, prop0[3], prop0[2], prop0[1], gen0[0]);
	and and9(w9, prop0[3], prop0[2], gen0[1]);
	and and10(w10, prop0[3], gen0[2]);
	or or4(carry[4], gen0[3], w7, w8, w9, w10);

	// carry 5 ;)))))
	wire w11, w12, w13, w14, w15;
	and and11(w11, prop0[4], prop0[3], prop0[2], prop0[1], prop0[0], carry[0]);
	and and12(w12, prop0[4], prop0[3], prop0[2], prop0[1], gen0[0]);
	and and13(w13, prop0[4], prop0[3], prop0[2], gen0[1]);
	and and14(w14, prop0[4], prop0[3], gen0[2]);
	and and15(w15, prop0[4], gen0[3]);
	or or5(carry[5], w11, w12, w13, w14, w15, gen0[4]);

	// carry 6 ;))))))
	wire w16, w17, w18, w19, w20, w21;
	and and16(w16, prop0[5], prop0[4], prop0[3], prop0[2], prop0[1], prop0[0], carry[0]);
	and and17(w17, prop0[5], prop0[4], prop0[3], prop0[2], prop0[1], gen0[0]);
	and and18(w18, prop0[5], prop0[4], prop0[3], prop0[2], gen0[1]);
	and and19(w19, prop0[5], prop0[4], prop0[3], gen0[2]);
	and and20(w20, prop0[5], prop0[4], gen0[3]);
	and and21(w21, prop0[5], gen0[4]);
	or or6(carry[6], w16, w17, w18, w19, w20, w21, gen0[5]);

	// carry 7 ;)))))))
	wire w22, w23, w24, w25, w26, w27, w28;
	and and22(w22, prop0[6], prop0[5], prop0[4], prop0[3], prop0[2], prop0[1], prop0[0], carry[0]);
	and and23(w23, prop0[6], prop0[5], prop0[4], prop0[3], prop0[2], prop0[1], gen0[0]);
	and and24(w24, prop0[6], prop0[5], prop0[4], prop0[3], prop0[2], gen0[1]);
	and and25(w25, prop0[6], prop0[5], prop0[4], prop0[3], gen0[2]);
	and and26(w26, prop0[6], prop0[5], prop0[4], gen0[3]);
	and and27(w27, prop0[6], prop0[5], gen0[4]);
	and and28(w28, prop0[6], gen0[5]);
	or or7(carry[7], w22, w23, w24, w25, w26, w27, w28, gen0[6]);

	// carry complete ><
	// Block time -> Still in love with J-U-D-A-S
	and and29(prop, prop0[7], prop0[6], prop0[5], prop0[4], prop0[3], prop0[2], prop0[1], prop0[0]);

	wire w29, w30, w31, w32, w33, w34, w35;
	and and30(w29, prop0[7], prop0[6], prop0[5], prop0[4], prop0[3], prop0[2], prop0[1], gen0[0]);
	and and31(w30, prop0[7], prop0[6], prop0[5], prop0[4], prop0[3], prop0[2], gen0[1]);
	and and32(w31, prop0[7], prop0[6], prop0[5], prop0[4], prop0[3], gen0[2]);
	and and33(w32, prop0[7], prop0[6], prop0[5], prop0[4], gen0[3]);
	and and34(w33, prop0[7], prop0[6], prop0[5], gen0[4]);
	and and35(w34, prop0[7], prop0[6], gen0[5]);
	and and36(w35, prop0[7], gen0[6]);
	or or8(gen, gen0[7], w29, w30, w31, w32, w33, w34, w35);
endmodule

// Full adder that we need [From one of the labs :)]
module full_adder(S, prop, gen, A, B, Cin);
	input A, B, Cin;
	output S, prop, gen;

	xor Sresults(S, A, B, Cin); 

	and A_and_B(gen, A, B);
	or A_or_B(prop, A, B);
endmodule
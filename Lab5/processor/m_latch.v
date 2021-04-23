module m_latch(o, bd, ir_out, rdout, oin, bdin, ir_in, rdin, clock, clear);
    input clock, clear;
    input [4:0] rdin;
    // input [31:0] rdin;
    input [31:0] ir_in, oin, bdin;
    output [4:0] rdout;
    // output [31:0] rdout;
    output [31:0] ir_out, o, bd;

    // OH I SEE THE ERROR NOW

    register r0(clock, ir_in, 1'b1, ir_out, clear);
    register r1(clock, oin, 1'b1, o, clear);
    register r2(clock, bdin, 1'b1, bd, clear);
    register_5 r3(clock, rdin, 1'b1, rdout, clear);
    // register r3(clock, rdin, 1'b1, rdout, clear);

endmodule
module dx_latch(a, b, pc_out, ir_out, data_readRegA, data_readRegB, pc_in, ir_in, clock, clear);

    input clock, clear;
    input [31:0] pc_in, ir_in, data_readRegA, data_readRegB;
    output [31:0] pc_out, ir_out, a, b;

    register r0(clock, pc_in, 1'b1, pc_out, clear);
    register r1(clock, ir_in, 1'b1, ir_out, clear);
    register r2(clock, data_readRegA, 1'b1, a, clear);
    register r3(clock, data_readRegB, 1'b1, b, clear);

endmodule
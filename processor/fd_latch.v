module fd_latch(pc_out, ir_out, pc_in, ir_in, clk, clr, enable);
    input clk, clr, enable;
    input [31:0] pc_in, ir_in;
    output [31:0] pc_out, ir_out;

    register r0(clk, pc_in, enable, pc_out, clr);
    register r1(clk, ir_in, 1'b1, ir_out, clr);

endmodule
module extend_26_32(in, out);
    input [26:0] in;
    output [31:0] out;

    assign out[26:0] = in[26:0];
    assign out[31] = 0;
    assign out[30] = 0;
    assign out[29] = 0;
    assign out[28] = 0;
    assign out[27] = 0;
endmodule
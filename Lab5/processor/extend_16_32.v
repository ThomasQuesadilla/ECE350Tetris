module extend_16_32(in, out);
    input [16:0] in;
    output [31:0] out;

    assign out[16:0] = in[16:0];
    assign out[31] = in[16];
    assign out[30] = in[16];
    assign out[29] = in[16];
    assign out[28] = in[16];
    assign out[27] = in[16];
    assign out[26] = in[16];
    assign out[25] = in[16];
    assign out[24] = in[16];
    assign out[23] = in[16];
    assign out[22] = in[16];
    assign out[21] = in[16];
    assign out[20] = in[16];
    assign out[19] = in[16];
    assign out[18] = in[16];
    assign out[17] = in[16];
endmodule
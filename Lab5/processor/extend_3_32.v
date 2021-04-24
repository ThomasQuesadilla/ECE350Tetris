module extend_3_32(in, out);
    input [1:0] in;
    output [31:0] out;

    assign out[1:0] = in[1:0];
    genvar i;
    generate
        for (i = 2; i < 32; i = i + 1)
        begin
            assign out[i] = 0;
        end
    endgenerate
endmodule
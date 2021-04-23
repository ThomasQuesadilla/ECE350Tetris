module xm_inputs(rd, xm_o_in, ir, exception, ALUout, PC1);

    input[31:0] ir, ALUout, PC1;
    input exception;
    output [4:0] rd;
    output[31:0] xm_o_in;

    wire [4:0] opcode, aluop, rd_og, rd_1;
    assign opcode = ir[31:27];
    assign aluop = ir[6:2];
    assign rd_og = ir[26:22];

    wire is_jal, is_addi, ALUopHasException, is_setx;
    assign is_jal = (opcode == 5'b00011);
    assign is_addi = (opcode == 5'b00101);
    assign is_setx = opcode == 5'b10101;
    assign ALUopHasException = ((opcode == 5'b00000) & (aluop == 5'b00000 | aluop == 5'b00001 | aluop == 5'b00110 | aluop == 5'b00111));

    assign rd_1 = is_jal ? 5'd31 : ir[26:22];
    assign rd = (is_setx | (exception & (is_addi | ALUopHasException))) ? 5'd30 : rd_1;

    wire [31:0] w1, w2, w3, w4, T;

    extend_26_32 ext0(ir[26:0], T);

    mux32_4 m0(w1, aluop[1:0], 32'd1, 32'd3, 32'd4, 32'd5);
    assign w2 = (exception & ALUopHasException) ? w1 : ALUout;
    assign w3 = (is_addi & exception) ? 2 : w2; 
    assign w4 = is_jal ? PC1 : w3;
    assign xm_o_in = is_setx ? T : w4;

endmodule
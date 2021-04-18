module pw_latch(p, rd, stall, done, pin, ir_in, dataReady, exceptionIn, clock, clear);
    input clock, clear, dataReady, exceptionIn;
    input [31:0] ir_in, pin;
    output [31:0] p;
    output [4:0] rd;
    output stall, done;

    // exception
    wire exception;
    dffe_ref dffe0(exception, exceptionIn, clock, 1'b1, clear);

    wire [4:0] mult, div, opcode, aluop, opcode_in, aluop_in;
    assign mult = 5'b00110; 
    assign div = 5'b00111;
    assign opcode = ir_out[31:27];
    assign aluop = ir_out[6:2];
    assign opcode_in = ir_in[31:27];
    assign aluop_in = ir_in[6:2];

    wire isMultDiv, isMultDivIn;
    assign isMultDiv =  opcode == 5'b00000 & (aluop == mult | aluop == div);
    assign isMultDivIn =  opcode_in == 5'b00000 & (aluop_in == mult | aluop_in == div);

    wire dataReadyLatch;
    dffe_ref dffe1(dataReadyLatch, dataReady, clock, 1'b1, clear);


    wire[31:0] ir_out;
    register r0(clock, ir_in, ~(isMultDiv & ~dataReadyLatch), ir_out, clear);
    wire [31:0] ans;
    register r1(clock, pin, 1'b1, ans, clear);

    assign stall = (isMultDiv & ~dataReadyLatch) | isMultDivIn;
    assign done = isMultDiv & dataReadyLatch;

    wire[31:0] exceptionNum;

    assign exceptionNum = (opcode == 5'b00000 & (aluop == mult)) ? 4 : 5; //if mult, exception is 4, else 5
    assign p = exception ? exceptionNum : ans; 
    assign rd = exception ? 5'd30 : ir_out[26:22];


    
endmodule
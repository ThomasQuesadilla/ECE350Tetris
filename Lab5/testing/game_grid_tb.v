`timescale 1ns/100ps
module game_grid_tb;
    reg[1:0] A;
    reg[3:0] X, Y;
    wire[1:0] S;
    wire[6:0] ind;
    game_grid grid(S, A, X, Y, ind);
    initial begin
        $dumpfile("wave_full_adder.vcd");
        $dumpvars(0, game_grid_tb);
    end
    initial begin
        A = 2'b0;
        B = 4'd5;
        C = 4'd3;
        #20;
        $finish;
    end
    always
        #10 A = !A;

    always @(A, B) begin
        //small delay stabilizes output
        #1;
        $display("A:%b, B:%b, Cin:%b, => S:%b, ind:%d", A, B, C, S, ind);
    end
endmodule
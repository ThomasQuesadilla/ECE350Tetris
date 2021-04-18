module linear_register(out, clk, data_A);
    // Okay we are going to check gtkwave because value doesn't change
    input data_A, clk;
    output [1:0] out;

    wire w1;
    reg [1:0] out;
    initial begin
        // Initialize register
        out <= 2'b0;
    end
    assign w1 = ~(out[1] ^ out[0]);


    always @(posedge clk, posedge data_A)
        begin
        if (data_A)
            out <= 2'b0;
        else
            out <= {out[0], w1};
        end

endmodule
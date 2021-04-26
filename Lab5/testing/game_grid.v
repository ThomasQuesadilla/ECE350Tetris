module game_grid(S, A, x_in, y_in, ind_out);
    input[1:0] A;
    input[3:0] x_in, y_in; 
    output[1:0] S;
	output[6:0] ind_out;

	wire[6:0] ind = (x_in) + (y_in * 10);
	reg[39:0] placedblocks= 40'b0;
    always @(A) begin

    case (A)
				2'b00 : begin
					placedblocks[ind] <= 1'b1;
					placedblocks[ind - 1] <= 1'b1;
					placedblocks[ind - 10] <= 1'b1;
					placedblocks[ind - 11] <= 1'b1;
				end
				2'b01 : begin
					placedblocks[(x_in) + (y_in) * 10] <= 1'b1;
					placedblocks[(x_in) + (y_in - 1) * 10] <= 1'b1;
					placedblocks[(x_in) + (y_in - 2) * 10] <= 1'b1;
					placedblocks[(x_in) + (y_in - 3) * 10] <= 1'b1;
				end
				2'b10 : begin
					placedblocks[(x_in) + (y_in) * 10] <= 1'b1;
					placedblocks[(x_in - 1) + (y_in) * 10] <= 1'b1;
					placedblocks[(x_in - 2) + (y_in) * 10] <= 1'b1;
					placedblocks[(x_in - 3) + (y_in) * 10] <= 1'b1;
				end
				default : begin
					placedblocks[(x_in) + (y_in) * 10] <= 1'b1;
					placedblocks[(x_in) + (y_in - 1) * 10] <= 1'b1;
					placedblocks[(x_in) + (y_in - 2) * 10] <= 1'b1;
					placedblocks[(x_in) + (y_in - 3) * 10] <= 1'b1;
				end
			endcase
    end
    assign S = {placedblocks[x_in + y_in * 10], placedblocks[x_in + ((y_in-2) * 10)]};
	assign ind_out = x_in + ((y_in) * 10);
endmodule
module randomizer(random_block, block_height, block_width);
    input [1:0] random_block;
    output [9:0] block_height;
    output [8:0] block_width;

    reg [9:0] block_height = 0;
    reg [8:0] block_width = 0;
    
    always @(random_block, block_height)
    begin
        case(random_block)
            2'b00 : block_height = 48;
            2'b01 : block_height = 48;
            2'b10 : block_height = 96;
            2'b11 : block_height = 48;
        endcase
    end
    
    always @(random_block, block_width)
    begin
        case(random_block)
            2'b00 : block_height = 48;
            2'b01 : block_height = 96;
            2'b10 : block_height = 48;
            2'b11 : block_height = 48;
        endcase
    end
   
endmodule
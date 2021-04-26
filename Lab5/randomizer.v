module randomizer(random_block, block_height, block_width);
    input [1:0] random_block;
    output [9:0] block_height;
    output [8:0] block_width;

    reg [9:0] block_height = 0;
    reg [8:0] block_width = 0;
    
    always @(block_height)
    begin
        case(random_block)
            2'b00 : block_height = 64;
            2'b01 : block_height = 128;
            2'b10 : block_height = 32;
            2'b11 : block_height = 64;
        endcase
    end
    
    always @(block_width)
    begin
        case(random_block)
            2'b00 : block_width = 64;
            2'b01 : block_width = 32;
            2'b10 : block_width = 128;
            2'b11 : block_width = 64;
        endcase
    end
   
endmodule
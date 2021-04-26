`timescale 1 ns/ 100 ps
module VGAControllerTetris(     
	input clk, 			// 100 MHz System Clock
	input reset, 		// Reset Signal
	// input [1:0] random_block, // Which block to choose
	input up,
	input down,
	input left,
	input right,
	output hSync, 		// H Sync Signal
	output vSync, 		// Veritcal Sync Signal
	output[3:0] VGA_R,  // Red Signal Bits
	output[3:0] VGA_G,  // Green Signal Bits
	output[3:0] VGA_B,  // Blue Signal Bits
	inout ps2_clk,
	inout ps2_data,
	input [1:0] random_block);

	// block randomizer
	// wire [9:0] active_block_height1;
	// wire [8:0] active_block_width1;
	// reg[9:0] active_block_height2;
	// reg[8:0] active_block_width2; // we switch between blocks
	reg[9:0] active_block_height;
	reg[8:0] active_block_width; // we switch between blocks
	// wire [1:0] random_blocks = 2'b01;
	//randomizer rand(random_block, active_block_height1, active_block_width1);

	reg new_block_rdy = 0; // we will use this as a mux
	// Okay let's try a triple mux instead
	wire [1:0] random_blocks;
	assign random_blocks = 2'b10;
	wire[9:0] active_block_th;
	wire[9:0] active_block_th1;
	wire[9:0] active_block_height1;

	assign active_block_th = random_block[0] ? 64 : 128;
	assign active_block_th1 = random_block[0] ? 32 : 64;
	assign active_block_height1 = random_block[1] ? active_block_th : active_block_th1;

	wire[8:0] active_block_tw;
	wire[8:0] active_block_tw1;
	wire[8:0] active_block_width1;

	assign active_block_tw = random_block[0] ? 64 : 32;
	assign active_block_tw1 = random_block[0] ? 128 : 64;
	assign active_block_width1 = random_block[1] ? active_block_tw : active_block_tw1;

	wire [9:0] active_block_h;
	wire [8:0] active_block_w;

	assign active_block_h = new_block_rdy ? active_block_height1 : 64;
	assign active_block_w = new_block_rdy ? active_block_width1 : 64;

	always@(*) begin
		active_block_height = active_block_h;
		active_block_width = active_block_w;
		
	end



	// always @(new_block_rdy)
    // begin
    //     case(random_block)
    //         2'b00 : active_block_height = 64;
    //         2'b01 : active_block_height = 128;
    //         2'b10 : active_block_height = 32;
    //         2'b11 : active_block_height = 64;
    //     endcase
    // end
    
    // always @(new_block_rdy)
    // begin
    //     case(random_block)
    //         2'b00 : active_block_width = 64;
    //         2'b01 : active_block_width = 32;
    //         2'b10 : active_block_width = 128;
    //         2'b11 : active_block_width = 64;
    //     endcase
    // end

	// reg[9:0] active_block_height = new_block_rdy ? active_block_height2 : 64;
	// reg[8:0] active_block_width = new_block_rdy ? active_block_width2 : 64;
	
	// Would this work?
	// need to do some sort of mux logic to switch from one block to the next, not sure if this will work
	reg[9:0] active_block_x;
	reg[8:0] active_block_y;


	//reg[1:0] block_type = 2'b10;
	
	reg[1:0] block_type;
	always@(*) begin
	   block_type = random_block;
	end
	
	// Lab Memory Files Location
	//localparam FILES_PATH = "//tsclient/ECE350-Toolchain-Mac/Lab5/";
	localparam FILES_PATH = "C:/Users/eve65/Downloads/ECE350Tetris/Lab5/";
	localparam MHz = 1000000;
	localparam SYSTEM_FREQ = 25*MHz;
	// Clock divider 100 MHz -> 25 MHz
	wire clk25; // 25MHz clock

	reg[1:0] pixCounter = 0;      // Pixel counter to divide the clock
    assign clk25 = pixCounter[1]; // Set the clock high whenever the second bit (2) is high
	always @(posedge clk) begin
		pixCounter <= pixCounter + 1; // Since the reg is only 3 bits, it will reset every 8 cycles
	end

	// VGA Timing Generation for a Standard VGA Screen
	localparam 
		VIDEO_WIDTH = 640,  // Standard VGA Width
		VIDEO_HEIGHT = 480; // Standard VGA Height

	// VGA Tetris play width
	localparam 
		PLAYAREA_START = 160, // VIDEO_WIDTH/2 - 180
		PLAYAREA_END = 480,	  // VIDEO_WIDTH/2 + 180
		PLAYAREA_WIDTH = PLAYAREA_END - PLAYAREA_START,
		PLAYAREA_HEIGHT = 480,
		GRID_WIDTH = 10;
	
	//Block size in pixels
	localparam
		BLOCK_SIZE = 32;

	//Formula for indexing is (x - offset) / 32 + (y * desired width) / 32
	//aka ((x - 160) >> 5) + (y * 10) >> 5, 
	reg [149:0]placedblocks = 150'b0;
	reg [149:0]placedblocks_rev = 150'b0;

	wire active, screenEnd;
	wire[9:0] x;
	wire[8:0] y;
	VGATimingGenerator #(
		.HEIGHT(VIDEO_HEIGHT), // Use the standard VGA Values
		.WIDTH(VIDEO_WIDTH))
	Display( 
		.clk25(clk25),  	   // 25MHz Pixel Clock
		.reset(reset),		   // Reset Signal
		.screenEnd(screenEnd), // High for one cycle when between two frames
		.active(active),	   // High when drawing pixels
		.hSync(hSync),  	   // Set Generated H Signal
		.vSync(vSync),		   // Set Generated V Signal
		.x(x), 				   // X Coordinate (from left)
		.y(y)); 			   // Y Coordinate (from top)	   

	// Image Data to Map Pixel Location to Color Address
	localparam 
		PIXEL_COUNT = VIDEO_WIDTH*VIDEO_HEIGHT, 	             // Number of pixels on the screen
		PIXEL_ADDRESS_WIDTH = $clog2(PIXEL_COUNT) + 1,           // Use built in log2 command
		BITS_PER_COLOR = 12, 	  								 // Nexys A7 uses 12 bits/color
		PALETTE_COLOR_COUNT = 256, 								 // Number of Colors available
		PALETTE_ADDRESS_WIDTH = $clog2(PALETTE_COLOR_COUNT) + 1; // Use built in log2 Command

	wire[PIXEL_ADDRESS_WIDTH-1:0] imgAddress;  	 // Image address for the image data
	wire[PALETTE_ADDRESS_WIDTH-1:0] colorAddr; 	 // Color address for the color palette
	assign imgAddress = x + 640*y;				 // Address calculated coordinate

	RAM #(		
		.DEPTH(PIXEL_COUNT), 				     // Set RAM depth to contain every pixel
		.DATA_WIDTH(PALETTE_ADDRESS_WIDTH),      // Set data width according to the color palette
		.ADDRESS_WIDTH(PIXEL_ADDRESS_WIDTH),     // Set address with according to the pixel count
		.MEMFILE({FILES_PATH, "image.mem"})) // Memory initialization
	ImageData(
		.clk(clk), 						 // Falling edge of the 100 MHz clk
		.addr(imgAddress),					 // Image data address
		.dataOut(colorAddr),				 // Color palette address
		.wEn(1'b0)); 						 // We're always reading

	// Color Palette to Map Color Address to 12-Bit Color
	wire[BITS_PER_COLOR-1:0] colorData; // 12-bit color data at current pixel

	RAM #(
		.DEPTH(PALETTE_COLOR_COUNT), 		       // Set depth to contain every color		
		.DATA_WIDTH(BITS_PER_COLOR), 		       // Set data width according to the bits per color
		.ADDRESS_WIDTH(PALETTE_ADDRESS_WIDTH),     // Set address width according to the color count
		.MEMFILE({FILES_PATH, "colors.mem"}))  // Memory initialization
	ColorPalette(
		.clk(clk), 							   	   // Rising edge of the 100 MHz clk
		.addr(colorAddr),					       // Address from the ImageData RAM
		.dataOut(colorData),				       // Color at current pixel
		.wEn(1'b0)); 						       // We're always reading
	

	// Assign to output color from register if active
	wire[BITS_PER_COLOR-1:0] colorOut; 			  // Output color 
	wire[BITS_PER_COLOR-1:0] colorActive; 		  // Output color 
	wire inBlock, inPlaced, inPlayArea;
	

	wire[9:0] pixel_x_ind, pixel_y_ind, placedblocks_ind;
	wire[9:0] x_ind, y_ind, x_width_ind, y_height_ind, active_block_grid_height, active_block_grid_width;
	
	assign x_ind = ((active_block_x - PLAYAREA_START) >> 5);
	assign y_ind = (active_block_y >> 5) * GRID_WIDTH;
	assign x_width_ind = ((active_block_x + active_block_width - PLAYAREA_START) >> 5);
	assign y_height_ind = ((active_block_y + active_block_height) >> 5) * GRID_WIDTH;
	assign active_block_grid_width = active_block_width >> 5;
	assign active_block_grid_height = active_block_height >> 5;

	assign inBlock = (x > active_block_x && x < active_block_x + active_block_width) && (y > active_block_y && y < active_block_y + active_block_height);

	assign inPlayArea = x > PLAYAREA_START && x < PLAYAREA_END;
	assign pixel_x_ind = (x - PLAYAREA_START) >> 5;
	assign pixel_y_ind = (y  >> 5) * GRID_WIDTH;

	assign placedblocks_ind = inPlayArea ?  pixel_x_ind + pixel_y_ind: 0;
	assign inPlaced = placedblocks[placedblocks_ind] == 1'b1;

	assign colorActive = inBlock || inPlaced ? 12'd4095 : colorData;
	assign colorOut = active ? colorActive : 12'd0; // When not active, output black

	// Quickly assign the output colors to their channels using concatenation
	assign {VGA_R, VGA_G, VGA_B} = colorOut; 

	wire test_intersects, test_intersects_LR; 
	wire[5:0] grid_block_width, grid_block_height;
	reg [3:0] under_intersect, l_intersect, r_intersect;

	assign grid_block_width =  block_type[1] ? (block_type[0] ? 6'd2 : 6'd4) : (block_type[0] ? 6'd1 : 6'd2);
	assign grid_block_height =  block_type[1] ? (block_type[0] ? 6'd2 : 6'd1) : (block_type[0] ? 6'd4 : 6'd2);

	assign test_intersects = |under_intersect;
	assign test_l_intersect = |l_intersect;
	assign test_r_intersect = |r_intersect;

	wire[10:0] gameFreq;
	wire[31:0] game_counterlimit;
	reg gameclk = 0;
	reg[31:0] game_counter;
	assign gameFreq = 1; // 1 HZ
	assign game_counterlimit = ((SYSTEM_FREQ / gameFreq) >> 1) - 1;
	// assign test_intersects = placedblocks[(active_block_x - PLAYAREA_START) >> 5 + ((active_block_y + active_block_height + BLOCK_SIZE ) * GRID_WIDTH) >> 5] == 1'b1 || placedblocks[(active_block_x + active_block_width - PLAYAREA_START) >> 5 + (active_block_y + active_block_height + BLOCK_SIZE ) * GRID_WIDTH] == 1;
	
	
	always @(posedge clk25) begin
		if(game_counter < game_counterlimit) begin
			game_counter <= game_counter + 1;
			gameclk <= 0;
		end else begin
			game_counter <= 0;
			gameclk <= 1;
		end
    end


	wire right_en, left_en;
	debouncer db_right(.pb(right), .clk(clk25), .pb_down(right_en));
	debouncer db_left(.pb(left), .clk(clk25), .pb_down(left_en));
	
	wire passed_height;
	assign passed_height = (active_block_y + active_block_height >= VIDEO_HEIGHT);

	wire place_block;
	assign place_block = passed_height | test_intersects;

	wire gameover;
	assign gameover = |placedblocks[149:140];
	
	// wire clearline0, clearline1, clearline2, clearline3, clearline4, clearline5, clearline6, clearline7, clearline8, clearline9, clearline10, clearline11, clearline12, clearline13, clearline14, clearline15;

	initial begin
		active_block_x <= 288;
		active_block_y <= 0;
	end

	wire shift;
	reg[7:0] row;
	wire[7:0] placedblocks_h;
	assign shift = &placedblocks[row +: 9];
	assign placedblocks_h = 149 - row;

	integer i, j, n, p, q;
	always @(posedge clk25) begin
		// we drop by 1 each time
		if (row == 8'd140) begin
			row <= 8'd0;
		end else begin
			row <= row + 10;
		end
		if (gameclk && (active_block_y + active_block_height < 480))
			active_block_y <= active_block_y + BLOCK_SIZE;
			for (p = 0; p < grid_block_width; p = p + 1) begin
				under_intersect[p] = placedblocks[(x_ind + y_height_ind + p)] == 1;
			end
			for (q = 0; q < grid_block_height * 10; q = q + 10) begin
				l_intersect[q] = placedblocks[(x_ind + y_ind - 1 + q)] == 1;
				r_intersect[q] = placedblocks[(x_width_ind + y_ind + q)] == 1;
			end
		// we move left to right during dropping
		if (left_en && active_block_x > PLAYAREA_START && !test_l_intersect )
			active_block_x <= active_block_x - BLOCK_SIZE;
		if (right_en && active_block_x + active_block_width < PLAYAREA_END && !test_r_intersect)
			active_block_x <= active_block_x + BLOCK_SIZE;
		if (place_block) begin
			case (block_type)
				2'b00 : begin
					placedblocks[(x_ind) + (y_ind)] <= 1'b1;
					placedblocks[(x_ind + 1) + (y_ind)] <= 1'b1;
					placedblocks[(x_ind) + (y_ind + 10)] <= 1'b1;
					placedblocks[(x_ind + 1) + (y_ind + 10)] <= 1'b1;
				end
				2'b01 : begin
					placedblocks[(x_ind) + (y_ind)] <= 1'b1;
					placedblocks[(x_ind) + (y_ind + 10)] <= 1'b1;
					placedblocks[(x_ind) + (y_ind + 20)] <= 1'b1;
					placedblocks[(x_ind) + (y_ind + 30)] <= 1'b1;
				end
				2'b10 : begin
					placedblocks[(x_ind) + (y_ind)] <= 1'b1;
					placedblocks[(x_ind + 1) + (y_ind)] <= 1'b1;
					placedblocks[(x_ind + 2) + (y_ind)] <= 1'b1;
					placedblocks[(x_ind + 3) + (y_ind)] <= 1'b1;
				end
				default : begin
					placedblocks[(x_ind) + (y_ind)] <= 1'b1;
					placedblocks[(x_ind + 1) + (y_ind)] <= 1'b1;
					placedblocks[(x_ind) + (y_ind + 10)] <= 1'b1;
					placedblocks[(x_ind + 1) + (y_ind + 10)] <= 1'b1;
				end
			endcase
			// for ( n=0 ; n < 150 ; n=n+1 ) begin 
			// 	placedblocks[n] <= placedblocks_rev[149-n]; // Reverse video data buss bit order 
			// end 
			active_block_x <= 288;
			active_block_y <= 0;
			new_block_rdy <= 1'b1;
		end
		if (shift) begin
			if (row == 0) begin
				placedblocks[row +: 9] <= 10'b0;
			end else begin
				for (i = 0; i < placedblocks_h; i = i +10) begin
					placedblocks[row - i+: 9] <= placedblocks[row - i -10 +: 9];
				end
				placedblocks[149 : 140] <= 10'b0;
				row <= row - 10;
			end
		end
		if (gameover) begin
			
		end

	end


	
	
endmodule
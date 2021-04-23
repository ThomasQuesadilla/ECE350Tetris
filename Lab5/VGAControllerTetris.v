`timescale 1 ns/ 100 ps
module VGAControllerTetris(     
	input clk, 			// 100 MHz System Clock
	input reset, 		// Reset Signal
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
	inout ps2_data);

	reg new_block_rdy = 1'b0;
	// need to do some sort of mux logic to switch from one block to the next, not sure if this will work
	reg[9:0] active_block_x;
	reg[8:0] active_block_y;
	reg[9:0] active_block_height = 72;
	reg[8:0] active_block_width = 72; // we switch between blocks
	reg[1:0] block_type = 2'b0;

	// Lab Memory Files Location
	localparam FILES_PATH = "//tsclient/ECE350-Toolchain-Mac/ECE350Tetris/Lab5/";
	// localparam FILES_PATH = "C:/Users/eve65/Downloads/ECE350Tetris/Lab5/";
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
	wire placedblocks_ind;
	

	assign inPlayArea = x > PLAYAREA_START && x  + active_block_width < PLAYAREA_END;
	assign placedblocks_ind = inPlayArea ?  ((x - PLAYAREA_START) >> 5) + ((y * GRID_WIDTH) >> 5) : 0;
	
	assign inBlock = (x > active_block_x && x < active_block_x + active_block_width) && (y > active_block_y && y < active_block_y + active_block_height);
	assign inPlaced = placedblocks[placedblocks_ind] == 1;

	assign colorActive = inBlock || inPlaced ? 12'd0 : colorData;
	assign colorOut = active ? colorActive : 12'd0; // When not active, output black

	// Quickly assign the output colors to their channels using concatenation
	assign {VGA_R, VGA_G, VGA_B} = colorOut; 

	wire[4:0] x_in, y_in, active_block_grid_height, active_block_grid_width;
	
	assign x_in = (active_block_x - PLAYAREA_START) >> 5;
	assign y_in = (active_block_y >> 5) * GRID_WIDTH;
	assign active_block_grid_width = active_block_width >> 5;
	assign active_block_grid_height = active_block_height >> 5;

	wire right_en, left_en;

	wire[10:0] gameFreq;
	wire[31:0] game_counterlimit;
	reg gameclk = 0;
	reg[31:0] game_counter;
	assign gameFreq = 1; // 1 HZ
	assign game_counterlimit = ((SYSTEM_FREQ / gameFreq) >> 1) - 1;
	assign test_intersects = placedblocks[(active_block_x - PLAYAREA_START) >> 5 + ((active_block_y + active_block_height + BLOCK_SIZE ) * GRID_WIDTH) >> 5] == 1'b1 || placedblocks[(active_block_x + active_block_width - PLAYAREA_START) >> 5 + (active_block_y + active_block_height + BLOCK_SIZE ) * GRID_WIDTH] == 1;
	
	always @(posedge clk25) begin
		if(game_counter < game_counterlimit) begin
			game_counter <= game_counter + 1;
			gameclk <= 0;
		end else begin
			game_counter <= 0;
			gameclk <= 1;
		end
    end

	initial begin
		active_block_x <= 288;
		active_block_y <= 0;
	end

	debouncer db_right(.pb(right), .clk(clk25), .pb_down(right_en));
	debouncer db_left(.pb(left), .clk(clk25), .pb_down(left_en));
	
	wire passed_height;
	assign passed_height = (active_block_y + active_block_height > VIDEO_HEIGHT);

	wire place_block;
	assign place_block = passed_height | test_intersects;

	integer i, j;
	always @(posedge clk25) begin
		// we drop by 1 each time
		if (gameclk && (active_block_y + active_block_height < 480))
			active_block_y <= active_block_y + BLOCK_SIZE;
		// we move left to right during dropping
		if (left_en && active_block_x > PLAYAREA_START)
			active_block_x <= active_block_x - BLOCK_SIZE;
			// active_block_x = active_block_x - 1; // To make jumps less big
		if (right_en && active_block_x + active_block_width < PLAYAREA_END)
			active_block_x <= active_block_x + BLOCK_SIZE;
			// active_block_x = active_block_x + 1; // To make jumps less big
		if (place_block) begin
			// for (i = 0; i < active_block_grid_height; i = i+1) begin
			// 	// for ( j = 0; i < active_block_grid_width; j = j+1) begin
			// 		placedblocks[(x_in ) + (y_in + j) * GRID_WIDTH : ] <= active_block_grid_width'b1;
			// 	// end
			// end
			// case (block_type)
			// 	2'b00 : begin
			// 		placedblocks[(x_in) + (y_in) * GRID_WIDTH] <= 1'b1;
			// 		placedblocks[(x_in + 1) + (y_in) * GRID_WIDTH] <= 1'b1;
			// 		placedblocks[(x_in) + (y_in + 1) * GRID_WIDTH] <= 1'b1;
			// 		placedblocks[(x_in + 1) + (y_in + 1) * GRID_WIDTH] <= 1'b1;
			// 	end
			// 	2'b01 : begin
			// 		placedblocks[(x_in) + (y_in) * GRID_WIDTH] <= 1'b1;
			// 		placedblocks[(x_in) + (y_in + 1) * GRID_WIDTH] <= 1'b1;
			// 		placedblocks[(x_in) + (y_in + 2) * GRID_WIDTH] <= 1'b1;
			// 		placedblocks[(x_in) + (y_in + 3) * GRID_WIDTH] <= 1'b1;
			// 	end
			// 	2'b10 : begin
			// 		placedblocks[(x_in) + (y_in) * GRID_WIDTH] <= 1'b1;
			// 		placedblocks[(x_in + 1) + (y_in) * GRID_WIDTH] <= 1'b1;
			// 		placedblocks[(x_in + 2) + (y_in) * GRID_WIDTH] <= 1'b1;
			// 		placedblocks[(x_in + 3) + (y_in) * GRID_WIDTH] <= 1'b1;
			// 	end
			// 	default : begin
			// 		placedblocks[(x_in) + (y_in) * GRID_WIDTH] <= 1'b1;
			// 		placedblocks[(x_in + 1) + (y_in) * GRID_WIDTH] <= 1'b1;
			// 		placedblocks[(x_in) + (y_in + 1) * GRID_WIDTH] <= 1'b1;
			// 		placedblocks[(x_in + 1) + (y_in + 1) * GRID_WIDTH] <= 1'b1;
			// 	end
			// endcase
			active_block_x <= 288;
			active_block_y <= 0;
			new_block_rdy <= 1'b1;
		end

		// missing case where block underneath is active_block_x < x < active_block_x + active_block_width, not inclusive
	end
	// case statement to add block to bus, doesn't work with if for some reason, at least not in prior @always
	// feel free to play around with it
	always @(posedge place_block) begin
			// for (i = 0; i < active_block_grid_height; i = i+1) begin
			// 	for ( j = 0; i < active_block_grid_width; j = j+1) begin
			// 		placedblocks[(x_in + i) + (y_in + j) * GRID_WIDTH] <= 1'b1;
			// 	end
			// end
			case (block_type)
				2'b00 : begin
					placedblocks[(x_in) + (y_in) * GRID_WIDTH] <= 1'b1;
					placedblocks[(x_in + 1) + (y_in) * GRID_WIDTH] <= 1'b1;
					placedblocks[(x_in) + (y_in + 1) * GRID_WIDTH] <= 1'b1;
					placedblocks[(x_in + 1) + (y_in + 1) * GRID_WIDTH] <= 1'b1;
				end
				2'b01 : begin
					placedblocks[(x_in) + (y_in) * GRID_WIDTH] <= 1'b1;
					placedblocks[(x_in) + (y_in + 1) * GRID_WIDTH] <= 1'b1;
					placedblocks[(x_in) + (y_in + 2) * GRID_WIDTH] <= 1'b1;
					placedblocks[(x_in) + (y_in + 3) * GRID_WIDTH] <= 1'b1;
				end
				2'b10 : begin
					placedblocks[(x_in) + (y_in) * GRID_WIDTH] <= 1'b1;
					placedblocks[(x_in + 1) + (y_in) * GRID_WIDTH] <= 1'b1;
					placedblocks[(x_in + 2) + (y_in) * GRID_WIDTH] <= 1'b1;
					placedblocks[(x_in + 3) + (y_in) * GRID_WIDTH] <= 1'b1;
				end
				default : begin
					placedblocks[(x_in) + (y_in) * GRID_WIDTH] <= 1'b1;
					placedblocks[(x_in + 1) + (y_in) * GRID_WIDTH] <= 1'b1;
					placedblocks[(x_in) + (y_in + 1) * GRID_WIDTH] <= 1'b1;
					placedblocks[(x_in + 1) + (y_in + 1) * GRID_WIDTH] <= 1'b1;
				end
			endcase
		end
	always @(posedge screenEnd) begin
	end

	
	
endmodule
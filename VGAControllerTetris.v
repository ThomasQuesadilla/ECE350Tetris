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

	reg[9:0] active_block_x = 296;
	reg[8:0] active_block_y = 0;
	reg[9:0] active_block_width = 48;
	reg[8:0] active_block_height = 48;
	


	// Lab Memory Files Location
	localparam FILES_PATH = "//tsclient/ECE350-Toolchain-Mac/ECE350Tetris/Lab5/";
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
		PLAYAREA_START = 200, // VIDEO_WIDTH/2 - 130
		PLAYAREA_END = 440;	  // VIDEO_WIDTH/2 + 130

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
	wire inBlock;
	
	assign inBlock = (x > active_block_x && x < active_block_x + active_block_width) && (y > active_block_y && y < active_block_y + active_block_height);
	assign colorActive = inBlock ? 12'd0 : colorData;
	assign colorOut = active ? colorActive : 12'd0; // When not active, output black

	// Quickly assign the output colors to their channels using concatenation
	assign {VGA_R, VGA_G, VGA_B} = colorOut; 

	wire[10:0] freq;
	wire[31:0] counterlimit;
	reg clkFreq = 0;
	reg[31:0] counter;
	assign freq = 100;
	assign counterlimit = ((SYSTEM_FREQ / freq) >> 1) - 1;
	always @(posedge clk25) begin
		if(counter < counterlimit)
			counter <= counter + 1;
		else begin
			counter <= 0;
			clkFreq = ~clkFreq;
		end
    end
	always @(posedge clkFreq) begin
		if (active_block_y + active_block_height < 480)
			active_block_y = active_block_y + 1;
		// else begin
			
		// end
		if (left && active_block_x > PLAYAREA_START)
			active_block_x = active_block_x - 24;
		if (right && active_block_x + active_block_width < PLAYAREA_END)
			active_block_x = active_block_x + 24;
	end
	always @(posedge screenEnd) begin
	end

	
endmodule
`timescale 1 ns/ 1 ps
module VGATimingGenerator #(parameter HEIGHT=480, WIDTH=640) (
	input clk25, 		// 25 MHz clock
	input reset, 		// Reset the Frame
	output active, 		// In the visible area
	output screenEnd,	// High for one cycle between frames
	output hSync,		// Horizontal sync, active high, marks the end of a horizontal line
	output vSync,		// Vertical sync, active high, marks the end of a vertical line
	output[9:0] x,		// X coordinate from left
	output[8:0] y);		// Y coordinate from top
	
	/*///////////////////////////////////////////
	--          		VGA Timing
	--  Horizontal:
	--                   ___________             _____________
	--                  |           |           |
	--__________________|  VIDEO    |___________|  VIDEO (next line)

	--___________   _____________________   ______________________
	--           |_|                     |_|
	--            B <-C-><----D----><-E->
	--           <------------A--------->
	--  The Units used below are pixels;  
	--      B->Sync_cycle                   : H_SYNC_WIDTH
	--      C->Back_porch                   : H_BACK_PORCH
	--      D->Visable Area					: WIDTH
	--      E->Front porch                  : H_FRONT_PORCH
	--      A->horizontal line total length : H_LINE
	--	
	--	
	--	Vertical:
	--                   __________             _____________
	--                  |          |           |          
	--__________________|  VIDEO   |___________|  VIDEO (next frame)
	--
	--__________   _____________________   ______________________
	--          |_|                     |_|
	--           P <-Q-><----R----><-S->
	--          <-----------O---------->
	--	The Unit used below are horizontal lines;  
	--  	P->Sync_cycle                   : V_SYNC_WIDTH
	--  	Q->Back_porch                   : V_BACK_PORCH
	--  	R->Visable Area					: HEIGHT
	--  	S->Front porch                  : V_FRONT_PORCH
	--  	O->vertical line total length   : V_LINE
	///////////////////////////////////////////*/

	localparam 
		H_FRONT_PORCH = 16,
		H_SYNC_WIDTH  = 96,
		H_BACK_PORCH  = 48,

		H_SYNC_START = WIDTH + H_FRONT_PORCH,
		H_SYNC_END   = H_SYNC_START + H_SYNC_WIDTH,
		H_LINE       = H_SYNC_END + H_BACK_PORCH,

		V_FRONT_PORCH = 11,
		V_SYNC_WIDTH  = 2,
		V_BACK_PORCH  = 31,

		V_SYNC_START = HEIGHT + V_FRONT_PORCH,
		V_SYNC_END   = V_SYNC_START + V_SYNC_WIDTH,
		V_LINE       = V_SYNC_END + V_BACK_PORCH;

	// Count the position on the screen to decide the VGA regions
	reg[9:0] hPos = 0;
	reg[9:0] vPos = 0;
	always @(posedge clk25 or posedge reset) begin
		if(reset) begin
			hPos <= 0;
			vPos <= 0;
		end else begin
			if(hPos == H_LINE - 1) begin // End of horizontal line
				hPos <= 0;
				if(vPos == V_LINE - 1)   // End of vertical line
					vPos <= 0;
				else begin
					vPos <= vPos + 1;
				end
			end else 
				hPos <= hPos + 1;
		end
	end

	// Determine active regions
	wire activeX, activeY;
	assign activeX = (hPos < WIDTH);   // Active for the first 640 pixels of each line
	assign activeY = (vPos < HEIGHT);  // Active for the first 480 horizontal lines 
	assign active = activeX & activeY; // Active when both x and y are active      

	// Only output the x and y coordinates 
	assign x = activeX ? hPos : 0; // Output x coordinate when x is active. Otherwise 0
	assign y = activeY ? vPos : 0; // Output y coordinate when x is active. Otherwise 0

	// Screen ends when x and y reach their ends 
	assign screenEnd = (vPos == (V_LINE - 1)) & (hPos == (H_LINE - 1)); 

	// Generate the sync signals based on the parameters
	assign hSync = (hPos < H_SYNC_START) | (hPos >= H_SYNC_END);
	assign vSync = (vPos < V_SYNC_START) | (vPos >= V_SYNC_END);
endmodule
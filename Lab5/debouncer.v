module debouncer(
    input wire  pb,
    input wire  clk,
    output wire pb_down
    );
    reg db = 0;
    reg db_sync = 0;
    reg [15:0] counter;
    wire[10:0] freq;
	wire[31:0] counterlimit;

	assign freq = 200; // 200 HZ
	assign counterlimit = ((25000000 / freq) >> 1) - 1;

    always @ (posedge clk) begin
        if (counter < counterlimit) begin
            counter <= counter + 1;
        end else begin
            counter <= 0;
            db <= pb;
        end

        // sync with db
        db_sync <= db;
    end

    assign pb_down = db && !db_sync;

endmodule
module anti_shaking(clk, KeyIn, KeyOut);
//clk	50MHz
//key	0.20s

	input		clk;
	input		KeyIn;
	output reg	KeyOut;

	reg [30:0]	KeyHigh, KeyLow;

	always @(posedge clk) begin
		if (!KeyIn) KeyLow <= KeyLow + 1;
		else KeyLow <= 20'b0;
	end

	always @(posedge clk) begin
		if (KeyIn) KeyHigh <= KeyHigh + 1;
		else KeyHigh <= 20'b0;
	end

	always @(posedge clk) begin
		if (KeyHigh > 'd10000000) KeyOut <= 1'b1;
		else if (KeyLow > 'd10000000) KeyOut <= 1'b0;
	end

endmodule

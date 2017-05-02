module freq_divider(clk, clk_freq_div);
//clk			50MHz
//clk_freq_div	1Hz

	input   	clk;
	output reg  clk_freq_div;

	reg [30:0]	count;

	always @(clk) begin
		if (count == 'd10000000) begin
            clk_freq_div = ~clk;
            count <= 0;
		end
        else    count <= count + 1;
	end

endmodule

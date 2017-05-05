module CNT6(clk, rst, carryin, out, carryout);
	input				clk;
	input				rst;
	input				carryin;
	output reg [7:0]	out;
	output reg			carryout;

	always @(posedge clk) begin
		if (!rst) begin
			out = 8'b00000000;
			carryout = 0;
		end // end if
		if (out == 8'd5 && carryin == 1) begin
			out = 8'b00000000;
			carryout = 1;
		end // end if
		else begin
			out = out + carryin;
			carryout = 0;
		end //end else
	end

endmodule

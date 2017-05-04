module CNT4(clk, en, rst, key_hrs, carryin, CNT2In, out, carryout);
	input				clk;
	input				en;
	input				rst;
	input               key_hrs;
	input				carryin;
	input [7:0]     	CNT2In;
	output reg [7:0]	out;
	output reg          carryout;

	always @(posedge clk) begin
		if (rst) begin
			out = 8'b00000000;
			carryout = 0;
		end
		if (en) begin
			if ((out == 8'd9 || CNT2In == 8'd2 && out == 8'd3) && key_hrs == 1) begin
				out = 8'b00000000;
				carryout = 1;
			end // end if if
			else begin
				out = out + key_hrs;
				carryout = 0;
			end // end if else
		end
		if ((out == 8'd9 || CNT2In == 8'd2 && out == 8'd3) && carryin == 1) begin
			out = 8'b00000000;
			carryout = 1;
		end // end if if
		else begin
			out = out + carryin;
			carryout = 0;
		end // end if else
	end // end always

endmodule
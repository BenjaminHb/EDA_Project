module CNT10(clk, en, rst, carryin, out, carryout);
    input               clk;
	input				en;
	input				rst;
	input				carryin;
	output reg [7:0]	out;
    output reg          carryout; 

	always @(posedge clk) begin
		if (rst) begin
			out = 8'b00000000;
            carryout = 0;
		end
        if (en) begin
            if (out == 8'd9 && carryin == 1) begin
                out = 8'b00000000;
                carryout = 1;
            end // end if if
            else begin
                out = out + carryin;
                carryout = 0;
            end // end if else
        end // end if
		else begin
			out = out + 1'b1;
			carryout = 0;
			if (out == 8'd10) begin
				out = 8'b00000000;
				carryout = 1;
			end
		end
		
	end // end always

endmodule
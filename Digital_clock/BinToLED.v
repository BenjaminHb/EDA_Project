module BinToLED(BinData, LEDData);
	input [7:0]			BinData;
	output reg [7:0]	LEDData;

	always @(*) begin
		case (BinData)
		  8'd0:	LEDData = 8'b11000000;
		  8'd1:	LEDData = 8'b11111001;
		  8'd2:	LEDData = 8'b10100100;
		  8'd3:	LEDData = 8'b10110000;
		  8'd4:	LEDData = 8'b10011001;
		  8'd5:	LEDData = 8'b10010010;
		  8'd6:	LEDData = 8'b10000010;
		  8'd7:	LEDData = 8'b11111000;
		  8'd8:	LEDData = 8'b10000000;
		  8'd9: LEDData = 8'b10010000;
		  default:	LEDData = 8'b10000110;
		endcase
	end

endmodule

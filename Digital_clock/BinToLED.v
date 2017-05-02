module BinToLED(BinData, LEDData);
	input [7:0]			BinData;
	output reg [7:0]	LEDData;

	always @(*) begin
		case (BinData)
		  8'd0:	LEDData = 8'b00111111;
		  8'd1:	LEDData = 8'b00000110;
		  8'd2:	LEDData = 8'b01011011;
		  8'd3:	LEDData = 8'b01001111;
		  8'd4:	LEDData = 8'b01100110;
		  8'd5:	LEDData = 8'b01101101;
		  8'd6:	LEDData = 8'b01111101;
		  8'd7:	LEDData = 8'b00000111;
		  8'd8:	LEDData = 8'b01111111;
		  8'd9: LEDData = 8'b01101111;
		  default:	LEDData = 8'b00000000;
		endcase
	end

endmodule

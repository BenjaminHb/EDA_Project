module LED_Processing_Unit(clk, LED1In, LED2In, LED3In, LED4In, LEDOut, LEDSelect);
//clk	50MHz
//clk2	50Hz
	input				clk;
	input [7:0]			LED1In;
	input [7:0]			LED2In;
	input [7:0]			LED3In;
	input [7:0]			LED4In;
	output reg [7:0]	LEDOut;
	output reg [3:0]	LEDSelect;

	reg [30:0]			count;
	reg					clk2;
	reg [1:0]			select_count;	


	always @(posedge clk) begin
		if (count == 'd1000000) begin
            clk2 = ~clk;
            count <= 0;
		end
        else    count <= count + 1'b1;
	end

	always @(posedge clk2) begin
		case (select_count)
			2'b00:	begin
						LEDOut = LED1In;
						LEDSelect = 4'b0001;
						select_count = select_count + 1'b1;
					end
			2'b01:	begin
						LEDOut = LED2In;
						LEDSelect = 4'b0010;
						select_count = select_count + 1'b1;
					end
			2'b10:	begin
						LEDOut = LED3In;
						LEDSelect = 4'b0100;
						select_count = select_count + 1'b1;
					end
			2'b11:	begin
						LEDOut = LED4In;
						LEDSelect = 4'b1000;
						select_count = select_count + 1'b1;
					end
		  default:	begin
					LEDOut = 8'b00000000;
					select_count = select_count + 1'b1;
					end
		endcase
	end

endmodule

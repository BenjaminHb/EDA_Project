module Digital_Clock_2(clk, rst, en, min, hr, out_data, out_select);
//	EDA_Project/Digital_Clock_2
//	Version 1.7.0.090517
//	Created by Benjamin Zhang on 04/05/17
//	Copyright © 2017 Benjamin Zhang
//
	input				clk;
	input				rst;
	input				en;
	input				min;
	input				hr;
	output reg [7:0]	out_data;
	output reg [3:0]	out_select;

//********************* anti_shaking *********************//
	reg [30:0]		key_low_hr, key_low_min, key_low_en;
	reg				key_hr, key_min;

	always @(posedge clk) begin
		if (!hr)	key_low_hr <= key_low_hr + 1'b1;
		else key_low_hr <= 0;
		if (!min)	key_low_min <= key_low_min + 1'b1;
		else key_low_min <= 0;
	end

	always @(posedge clk) begin
		if (key_low_hr[20] == 1'b1) key_hr <= 1'b0;
		else    key_hr <= 1'b1;
		if (key_low_min[20] == 1'b1) key_min <= 1'b0;
		else    key_min <= 1'b1;
	end

//********************* freq_div *********************//
	reg [30:0]	count;
	reg			clk_freq_div;
	
	always @(posedge clk) begin
		if (count == 'd25000000) begin
			clk_freq_div = ~clk_freq_div;
			count <= 0;
		end
		else    count <= count + 1'b1;
	end

//*********************       *********************//
	wire		min_low_carryin;
	reg [4:0]	min_low_out;
	reg			min_low_carryout;

	reg [4:0]	min_high_out;
	reg			min_high_carryout;

	wire		hr_low_carryin;
	reg [4:0]	hr_low_out;
	reg			hr_low_carryout;

	reg [4:0]	hr_high_out;

//********************* min_low *********************//
	assign	min_low_carryin = (en)?clk_freq_div:~key_min;

	always @(posedge min_low_carryin or negedge rst) begin
		if (!rst) begin
			min_low_out = 4'b0000;
			min_low_carryout = 0;
		end
		else if (min_low_out == 4'd9) begin
			min_low_out = 4'b0000;
			min_low_carryout = 1;
		end
		else begin
			min_low_out = min_low_out + 1'b1;
			min_low_carryout = 0;
		end
	end

//********************* min_high *********************//
	always @(posedge min_low_carryout or negedge rst) begin
		if (!rst) begin
			min_high_out = 4'b0000;
			min_high_carryout = 0;
		end
		else if (min_high_out == 4'd5) begin
			min_high_out = 4'b0000;
			min_high_carryout = 1;
		end
		else begin
			min_high_out = min_high_out + 1'b1;
			min_high_carryout = 0;
		end
	end

//********************* hr_low *********************//
	assign	hr_low_carryin = (~key_hr & ~en)| min_high_carryout;

	always @(posedge hr_low_carryin or negedge rst) begin
		if (!rst) begin
			hr_low_out = 4'b0000;
			hr_low_carryout = 0;
		end
		else if (hr_low_out == 4'd9 && hr_high_out < 4'd2 || hr_low_out == 4'd3 && hr_high_out == 4'd2) begin
			hr_low_out = 4'b0000;
			hr_low_carryout = 1;
		end
		else begin
			hr_low_out = hr_low_out + 1'b1;
			hr_low_carryout = 0;
		end
	end

//********************* hr_high *********************//
	always @(posedge hr_low_carryout or negedge rst) begin
		if (!rst)	hr_high_out = 4'b0000;
		else if (hr_high_out == 4'd2)	hr_high_out = 4'b0000;
		else	hr_high_out = hr_high_out + 1'b1;
	end

//********************* LED_Processing_Unit *********************//
	reg [30:0]	count1;
	reg			clk2;
	reg [7:0]	LEDOut;
	reg [1:0]	select;

	always @(posedge clk) begin 
		if (count1[17] == 1'b1) begin
            clk2 = ~clk2;
            count1 <= 0;
		end
        else    count1 <= count1 + 1'b1;
	end

	always @(posedge clk2) begin
		case (select)
			2'b00:	begin
						LEDOut = min_low_out;
						out_select = 4'b1110;
						select = select + 1'b1;
					end
			2'b01:	begin
						LEDOut = min_high_out;
						out_select = 4'b1101;
						select = select + 1'b1;
					end
			2'b10:	begin
						LEDOut = hr_low_out;
						out_select = 4'b1011;
						select = select + 1'b1;
					end
			2'b11:	begin
						LEDOut = hr_high_out;
						out_select = 4'b0111;
						select = 2'b00;
					end
		  default:	begin
					LEDOut = 8'b11111001;
					select = 2'b00;
					end
		endcase
	end

//********************* BinToLED *********************//
	always @(*) begin
		case (LEDOut)
		  4'd0:	out_data = 8'b11000000;
		  4'd1:	out_data = 8'b11111001;
		  4'd2:	out_data = 8'b10100100;
		  4'd3:	out_data = 8'b10110000;
		  4'd4:	out_data = 8'b10011001;
		  4'd5:	out_data = 8'b10010010;
		  4'd6:	out_data = 8'b10000010;
		  4'd7:	out_data = 8'b11111000;
		  4'd8:	out_data = 8'b10000000;
		  4'd9: out_data = 8'b10010000;
		  default:	out_data = 8'b01111111;
		  
/*
		  4'd0:	out_data = 8'b00111111;
		  4'd1:	out_data = 8'b00000110;
		  4'd2:	out_data = 8'b01011011;
		  4'd3:	out_data = 8'b01001111;
		  4'd4:	out_data = 8'b01100110;
		  4'd5:	out_data = 8'b01101101;
		  4'd6:	out_data = 8'b01111101;
		  4'd7:	out_data = 8'b00000111;
		  4'd8:	out_data = 8'b01111111;
		  4'd9: out_data = 8'b01101111;
		  default:	out_data = 8'b10000000;
*/
		endcase
	end

endmodule
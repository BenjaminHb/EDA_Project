module Digital_Clock_2(clk, rst, en, min, hr, out_data, out_select);
	input				clk;
	input				rst;
	input				en;
	input				min;
	input				hr;
	output reg [7:0]	out_data;
	output reg [3:0]	out_select;

//********************* anti_shaking *********************//
	reg [30:0]		key_low_hr, key_low_min, key_low_en;
	reg				key_hr, key_min, key_en;

	always @(posedge clk) begin
		if (!hr)	key_low_hr <= key_low_hr + 1'b1;
		else key_low_hr <= 0;
		if (!min)	key_low_min <= key_low_min + 1'b1;
		else key_low_min <= 0;
		if (!en)	key_low_en <= key_low_en + 1'b1;
		else key_low_en <= 0;
	end

	always @(posedge clk) begin
		if (key_low_hr[13] == 1'b1) key_hr <= 1'b0;
		else    key_hr <= 1'b1;
		if (key_low_min[13] == 1'b1) key_min <= 1'b0;
		else    key_min <= 1'b1;
		if (key_low_en[13] == 1'b1) key_en <= 1'b0;
		else    key_en <= 1'b1;
	end

//********************* freq_div *********************//
	reg [30:0]	count;
	reg			clk_freq_div;
	
	always @(clk) begin
		if (count == 'd5000000) begin
			clk_freq_div = ~clk_freq_div;
			count <= 0;
		end
		else    count <= count + 1'b1;
	end

//*********************       *********************//
	reg [4:0]	min_low_out;
	reg			min_low_carryout;

	reg [4:0]	min_high_out;
	reg			min_high_carryout;

	reg [4:0]	hr_low_out;
	reg			hr_low_carryout;

	reg [4:0]	hr_high_out;

//********************* min_low *********************//
	always @(posedge clk_freq_div) begin
		if (!rst) begin
			min_low_out = 4'b0000;
			min_low_carryout = 0;
		end
		else begin
			if (!key_en) begin
				if (min_low_out == 4'd9 && key_min == 1) begin
					min_low_out = 4'b0000;
					min_low_carryout = 1;
				end // end else if if
				else begin
					min_low_out = min_low_out + key_min;
					min_low_carryout = 0;
				end // end else if else
			end // end else if
			else begin
				min_low_out = min_low_out + 1'b1;
				min_low_carryout = 0;
				if (min_low_out == 4'd10) begin
					min_low_out = 4'b0000;
					min_low_carryout = 1;
				end // end else else if
			end // end else else
		end // end else
	end // end always

//********************* min_high *********************//
	always @(posedge clk_freq_div) begin
		if (!rst) begin
			min_high_out = 4'b0000;
			min_high_carryout= 0;
		end
		else begin
			if (min_high_out == 4'd5 && min_low_carryout == 1) begin
				min_high_out = 4'b0000;
				min_high_carryout = 1;
			end // end else if
			else begin
				min_high_out = min_high_out + min_low_carryout;
				min_high_carryout = 0;
				if (min_high_out == 4'd6) begin
					min_high_out = 4'b0000;
					min_high_carryout = 1;
				end // end else else if
			end //end else else
		end // end else
	end // end always

//********************* hr_low *********************//
	always @(posedge clk_freq_div) begin
		if (!rst) begin
			hr_low_out = 4'b0000;
			hr_low_carryout = 0;
		end
		else begin
			if (!key_en) begin
				if ((hr_low_out == 4'd9 || hr_high_out == 4'd2 && hr_low_out == 4'd3) && key_hr == 1) begin
					hr_low_out = 4'b0000;
					hr_low_carryout = 1;
				end // end else if if
				else begin
					hr_low_out = hr_low_out + key_hr;
					hr_low_carryout = 0;
				end // end else if else
			end // end else if
			if ((hr_low_out == 4'd9 || hr_high_out == 4'd2 && hr_low_out == 4'd3) && min_high_carryout == 1) begin
				hr_low_out = 4'b0000;
				hr_low_carryout = 1;
			end // end else if
			else begin
				hr_low_out = hr_low_out + min_high_carryout;
				hr_low_carryout = 0;
			end // end else else
		end // end else
	end // end always

//********************* hr_high *********************//
	always @(posedge clk_freq_div) begin
		if (!rst)	hr_high_out = 4'b0000;
		else begin
			if (hr_high_out == 4'd2 && hr_low_carryout == 1)	hr_high_out = 4'b0000;
			else	hr_high_out = hr_high_out + hr_low_carryout;
		end
	end

//********************* LED_Processing_Unit *********************//
	reg [30:0]	count1;
	reg			clk2;
	reg [7:0]	LEDOut;
	reg [1:0]	select;

	always @(posedge clk) begin 
		if (count1[19] == 1'b1) begin
            clk2 = ~clk2;
            count1 <= 0;
		end
        else    count1 <= count1 + 1'b1;
	end

	always @(posedge clk2) begin
		case (select)
			2'b00:	begin
						LEDOut = min_low_out;
						out_select = 4'b0001;
						select = select + 1'b1;
					end
			2'b01:	begin
						LEDOut = min_high_out;
						out_select = 4'b0010;
						select = select + 1'b1;
					end
			2'b10:	begin
						LEDOut = hr_low_out;
						out_select = 4'b0100;
						select = select + 1'b1;
					end
			2'b11:	begin
						LEDOut = hr_high_out;
						out_select = 4'b1000;
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
		  default:	out_data = 8'b10000110;
		endcase
	end

endmodule
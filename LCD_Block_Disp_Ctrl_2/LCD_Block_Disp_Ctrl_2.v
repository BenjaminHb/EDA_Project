module LCD_Block_Disp_Ctrl_2(clk, rst, up, down, left, right, rs, rw, en, data);
//	EDA_Project/LCD_Block_Disp_Ctrl_2
//	Version 2.1.5.180517
//	Created by Benjamin Zhang on 11/05/17
//	Copyright © 2017 Benjamin Zhang
//
	input			clk;	//50MHz, clock speed
	input			rst;	//global reset
	input			up;
	input			down;
	input			left;
	input			right;
	output			rs;		//LCD Command or Data Select, 0 or 1
	output			rw;		//LCD Read or Write, 1 or 0
	output			en;		//LCD Enable, fall edge effective
	output [7:0]	data;	//LCD Data

	assign	rw = 1'b0;

//Produce 20KHz(50us) clock speed ********************************//
	reg			LCD_clk;	//20KHz clk
	reg [11:0]	LCD_count;	//count

	always @(posedge clk or negedge rst) begin
		if (!rst) begin
			LCD_count <= 12'd0;
			LCD_clk <= 1'b0;
		end
		else if (LCD_count == 12'd2499) begin	//50us
			LCD_count <= 12'd0;
			LCD_clk <= ~LCD_clk;	//20KHz
		end
		else	LCD_count <= LCD_count + 1'b1;
	end

//Anti_shaking ***************************************************//
	reg [30:0]		key_in_up, key_in_down, key_in_left, key_in_right;
	reg				key_up, key_down, key_left, key_right;	//after anti_shaking processed key

	always @(posedge clk) begin
		if (!up)	key_in_up <= key_in_up + 1'b1;
		else key_in_up <= 0;
		if (!down)	key_in_down <= key_in_down + 1'b1;
		else key_in_down <= 0;
		if (!left)	key_in_left <= key_in_left + 1'b1;
		else key_in_left <= 0;
		if (!right)	key_in_right <= key_in_right + 1'b1;
		else key_in_right <= 0;
	end

	always @(posedge clk) begin
		if (key_in_up[20] == 1'b1) key_up <= 1'b0;
		else    key_up <= 1'b1;
		if (key_in_down[20] == 1'b1) key_down <= 1'b0;
		else    key_down <= 1'b1;
		if (key_in_left[20] == 1'b1) key_left <= 1'b0;
		else    key_left <= 1'b1;
		if (key_in_right[20] == 1'b1) key_right <= 1'b0;
		else    key_right <= 1'b1;
	end

//Parameter ******************************************************//
	parameter IDLE 			= 4'h0;	//initialization
	parameter PROCESSKEY	= 4'h1;	//process key press, move block
	parameter SETMODE 		= 4'h2;	//entry mode set
	parameter SWITCHMODE 	= 4'h3;	//display status
	parameter SETFUNCTION0 	= 4'h4;	//funtion set
	parameter SETFUNCTION1 	= 4'h5;	//funtion set
	parameter CLEARSETY		= 4'h6;	//clear block y set
	parameter CLEARSETX		= 4'h7;	//clear block x set
	parameter CLEAR			= 4'h8;	//clear block
	parameter DISPLAYSETY 	= 4'h9;	//display block y set
	parameter DISPLAYSETX 	= 4'hA;	//display block x set
	parameter DISPLAY 		= 4'hB;	//display block
	parameter STOP 			= 4'hC;	//stop

//LCD Read or Write select ***************************************//
	reg [3:0]	state;
	reg			rs;	//LCD Command or Data Select, 0 or 1

	//only wrte data, rs will be high level
	always @(posedge LCD_clk or negedge rst) begin
		if (!rst) begin
			rs = 1'b0;	//reset, command mode
		end
		else if (state == DISPLAY)	rs <= 1'b1;	//state write, data mode
		else	rs <= 1'b0;	//finish write, command mode
	end

	reg	flag;	//LCD operate finish, low level
	
	assign en = (flag == 1)? LCD_clk:1'b0;

//State machine **************************************************//
	reg [7:0]	data;	//LCD data
	reg [3:0]	move_x;	//delta x, 4bits 0 - 15
	reg [5:0]	move_y;	//delta y, 1bit 0 / 1, 4bits 0 - 31
	reg [3:0]	move_x_pre;	//previous move_x
	reg [5:0]	move_y_pre;	//previous move_y
	reg	[1:0]	move_x_count;
	reg [3:0]	move_y_count;
	reg [4:0]	move_y_temp;
	reg			move_y_5_temp;
	reg			init_status;

	initial begin
		move_x = 4'd7;
		move_y = {1'b0,5'h18};
		//move_x_pre = 4'd7;
		//move_y_pre = {1'b0,5'h18};
		move_x_count = 2'b0;
		move_y_count = 4'b0;
		init_status = 1'b1;
	end

	always @(posedge LCD_clk or negedge rst) begin
		if (!rst) begin
			state <= IDLE;
			data <= 8'bzzzzzzzz;
			flag <= 1'b1;
		end
		else begin
			case (state)
				//start
				IDLE:
					begin
						data <= 8'bzzzzzzzz;
						state <= PROCESSKEY;
						flag <= 1'b1;
					end
				
				//process key press, move block, process coord change
				PROCESSKEY:
					begin
						if (init_status == 1'b0) begin
							if ((key_up & key_down & key_left & key_right) == 1'b1)	state <= PROCESSKEY;	//not receiving key press, waiting key press
							else begin
								move_x_pre = move_x;
								move_y_pre = move_y;
								if (key_up == 1'b0) begin	//up
									if (move_y[4:0] == 5'h0 && move_y[5] == 1'b0)	move_y = {1'b1,5'h10};	//block reaches the upper part of the upper boundary
									else if (move_y[4:0] == 5'h0 && move_y[5] == 1'b1)	move_y = {1'b0,5'h1C};	//block reaches the lower part of the upper boundary
									else	move_y[4:0] = move_y[4:0] - 5'h4;
								end
								if (key_down == 1'b0) begin	//down
									if (move_y[4:0] == 5'h10 && move_y[5] == 1'b1)	move_y = {1'b0,5'h0};	//block reaches the lower part of the lower boundary
									else if (move_y[4:0] == 5'h1C && move_y[5] == 1'b0)	move_y = {1'b1,5'h0};	//block reaches the upper part of the critical point, where move_y[5] must be changed
									else	move_y[4:0] = move_y[4:0] + 5'h4;
								end
								if (key_left == 1'b0) begin	//left
									if (move_x == 4'd0)	move_x = 4'd14;	//block reaches the left boundary
									else	move_x = move_x - 1'd1;
								end
								if (key_right == 1'b0) begin	//right
									if (move_x == 4'd14)	move_x = 4'd0;	//block reaches the right boundary
									else	move_x = move_x + 1'd1;
								end
								state <= SETFUNCTION0;
							end
						end
						else begin
							state <= SETFUNCTION0;
							init_status = 1'b0;
						end
					end
				
				//funtion set
				SETFUNCTION0:
					begin
						data <= 8'h30;
						state <= SETMODE;
					end
				
				//set mode
				SETMODE:	//cursor move to the right
					begin	//DDRAM address count add 1
						data <= 8'h06;	//frame static
						state <= SWITCHMODE;
					end

				//switch mode
				SWITCHMODE:				//display on
					begin				//cursor display off
						data <= 8'h0c;	//glint display off
						state <= SETFUNCTION1;
					end
				
				//funtion set
				SETFUNCTION1:
					begin
						data <= 8'h36;
						move_y_5_temp = move_y_pre[5];
						state <= CLEARSETY;	//expanded instr
					end
				
				//clear block Y coord set
				CLEARSETY:
					begin
						move_y_temp = move_y_pre[4:0] + move_y_count;
						data = {3'b100,move_y_temp};
						state = CLEARSETX;
					end
				
				//clear block X coord set
				CLEARSETX:
					begin
						data = {4'b1000,move_y_5_temp,move_x_pre[3:1]};
						state = CLEAR;
					end
				
				//write ram, clear block
				CLEAR:
					begin
						if (move_x_pre[0] == 1'b0) begin
							data = 8'b0;
							move_x_count = move_x_count + 1'b1;
							if (move_x_count == 2'b01)	state = CLEAR;
							else begin
								if (move_y_count == 4'hF) begin
									move_x_count = 2'b0;
									move_y_count = 4'b0;
									move_y_5_temp = move_y[5];
									state = DISPLAYSETY;
								end
								else begin
									move_y_count = move_y_count + 1'b1;
									if ((move_y_pre[4:0] + move_y_count) == 5'b0)	move_y_5_temp =1'b1;
									state = CLEARSETY;
								end
							end
						end
						else begin
							data = 8'b0;
							move_x_count = move_x_count + 1'b1;
							if (move_x_count != 2'b00)	state = CLEAR;
							else begin
								if (move_y_count == 4'hF) begin
									move_x_count = 2'b0;
									move_y_count = 4'b0;
									move_y_5_temp = move_y[5];
									state = DISPLAYSETY;
								end
								else begin
									move_y_count = move_y_count + 1'b1;
									if ((move_y_pre[4:0] + move_y_count) == 5'b0)	move_y_5_temp =1'b1;
									state = CLEARSETY;
								end
							end
						end
					end	

				//display block Y coord set
				DISPLAYSETY:
					begin
						move_y_temp = move_y[4:0] + move_y_count;
						data = {3'b100,move_y_temp};
						state = DISPLAYSETX;
					end
				
				//display block X coord set
				DISPLAYSETX:
					begin
						data = {4'b1000,move_y_5_temp,move_x[3:1]};
						state = DISPLAY;
					end
				
				//write ram, display block
				DISPLAY:
					begin
						if (move_x[0] == 1'b0) begin
							data = 8'b11111111;
							move_x_count = move_x_count + 1'b1;
							if (move_x_count == 2'b01)	state = DISPLAY;
							else begin
								if (move_y_count == 4'hF) begin
									move_x_count = 2'b0;
									move_y_count = 4'b0;
									state = STOP;
								end
								else begin
									move_y_count = move_y_count + 1'b1;
									if ((move_y[4:0] + move_y_count) == 5'b0)	move_y_5_temp =1'b1;
									state = DISPLAYSETY;
								end
							end
						end
						else begin
							if (move_x_count == 2'b00 || move_x_count == 2'b11)	data = 8'b0;
							else	data = 8'b11111111;
							move_x_count = move_x_count + 1'b1;
							if (move_x_count != 2'b00)	state = DISPLAY;
							else begin
								if (move_y_count == 4'hF) begin
									move_x_count = 2'b0;
									move_y_count = 4'b0;
									state = STOP;
								end
								else begin
									move_y_count = move_y_count + 1'b1;
									if ((move_y[4:0] + move_y_count) == 5'b0)	move_y_5_temp =1'b1;
									state = DISPLAYSETY;
								end
							end
						end				
					end
				
				//stop
				STOP:
					begin
						state <= IDLE;	//go back to PROCESSKEY to detect key press
						flag <= 1'b0;
					end

			  default:	state <= IDLE;
			endcase
		end
	end

endmodule
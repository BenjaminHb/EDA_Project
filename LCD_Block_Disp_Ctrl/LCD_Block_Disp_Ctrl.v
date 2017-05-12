module LCD_Block_Disp_Ctrl(clk, rst, up, down, left, right, rs, rw, en, data);
//	EDA_Project/LCD_Block_Disp
//	Version 2.2.9.110517
//	Created by Benjamin Zhang on 08/05/17
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
	parameter IDLE 			= 4'd0;	//initialization
	parameter PROCESSKEY	= 4'd1;	//process key press, move block
	parameter SETMODE 		= 4'd2;	//entry mode set
	parameter SWITCHMODE 	= 4'd3;	//display status
	parameter SETFUNCTION0 	= 4'd4;	//funtion set
	parameter SETFUNCTION1 	= 4'd5;	//funtion set
	parameter DISPLAY0 		= 4'd6;	//Y coord set
	parameter DISPLAY1 		= 4'd7;	//X coord set
	parameter WRITERAM 		= 4'd8;	//write
	parameter STOP 			= 4'd9;	//stop

//LCD Read or Write select ***************************************//
	reg [3:0]	state;
	reg			rs;	//LCD Command or Data Select, 0 or 1

	//only wrte data, rs will be high level
	always @(posedge LCD_clk or negedge rst) begin
		if (!rst) begin
			rs = 1'b0;	//reset, command mode
		end
		else if (state == WRITERAM)	rs <= 1'b1;	//state write, data mode
		else	rs <= 1'b0;	//finish write, command mode
	end

	reg	flag;	//LCD operate finish, low level
	
	assign en = (flag == 1)? LCD_clk:1'b0;

//State machine **************************************************//
	reg [9:0]	addr;	//coord count
	reg [7:0]	data;	//LCD data
	wire 		line_done;
	wire		frame_done;
	wire [3:0]	key_combine;
	reg [3:0]	move_x;	//delta x, 4bits 0 - 15
	reg [5:0]	move_y;	//delta y, 1bit 0 / 1, 4bits 0 - 31
	reg			init_status;

	initial begin
		move_x = 4'd7;
		move_y = {1'b0,5'h18};
		init_status = 1'b1;
	end

	assign	key_combine = {key_up, key_down, key_left, key_right};
	assign	line_done = (addr[3:0] == 4'hf);
	assign	frame_done = (addr[9:4] == 7'h3f);

	always @(posedge LCD_clk or negedge rst) begin
		if (!rst) begin
			state <= IDLE;
			data <= 8'bzzzzzzzz;
			flag <= 1'b1;
			addr <= 10'd0;
		end
		else begin
			case (state)
				//start
				IDLE:
					begin
						data <= 8'bzzzzzzzz;
						state <= PROCESSKEY;
						flag <= 1'b1;
						addr <= 10'd0;
					end
				
				//process key press, move block, process coord change
				PROCESSKEY:
					begin
						if (key_combine == 4'b1111)	state <= PROCESSKEY;	//not receiving key press, waiting key press
						else begin
							if (init_status == 1'b0) begin
								case (key_combine)
									4'b0111:	begin	//up
													if (move_y[4:0] == 5'h0 && move_y[5] == 1'b0)	move_y = {1'b1,5'h10};	//block reaches the upper part of the upper boundary
													else if (move_y[4:0] == 5'h0 && move_y[5] == 1'b1)	move_y = {1'b0,5'h1C};	//block reaches the lower part of the upper boundary
													else	move_y[4:0] = move_y[4:0] - 5'h4;
												end
									4'b1011:	begin	//down
													if (move_y[4:0] == 5'h10 && move_y[5] == 1'b1)	move_y = {1'b0,5'h0};	//block reaches the lower part of the lower boundary
													else if (move_y[4:0] == 5'h1C && move_y[5] == 1'b0)	move_y = {1'b1,5'h0};	//block reaches the upper part of the critical point, where move_y[5] must be changed
													else	move_y[4:0] = move_y[4:0] + 5'h4;
												end
									4'b1101:	begin	//left
													if (move_x == 4'd0)	move_x = 4'd14;	//block reaches the left boundary
													else	move_x = move_x - 1'd1;
												end
									4'b1110:	begin	//right
													if (move_x == 4'd14)	move_x = 4'd0;	//block reaches the right boundary
													else	move_x = move_x + 1'd1;
												end
									default:;
								endcase
							end
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
						state <= DISPLAY0;	//expanded instr
					end

				//Y coord set
				DISPLAY0:
					begin
						data <= {3'b100,addr[8:4]};
						state <= DISPLAY1;
					end
				
				//X coord set
				DISPLAY1:
					begin
						data <= {4'b1000,addr[9],addr[3:1]};
						state <= WRITERAM;
					end
				
				//write ram
				WRITERAM:
					begin
						if (addr[3:0] == move_x || addr[3:0] == (move_x + 1'd1)) begin
							if (5'h1F - move_y[4:0] >= 5'hF) begin	//the block is all in the upper half
								if (addr[8:4] >= move_y[4:0] && addr[8:4] <= (move_y[4:0] + 5'hF) && addr[9] == move_y[5])
									data <= 8'b11111111;
							end
							else begin	//the block is not all in the upper half
								if (addr[8:4] >= move_y[4:0] && addr[8:4] <= 5'h1F && addr[9] == 1'b0)	//the block in the upper half
									data <= 8'b11111111;
								if (addr[8:4] >= 5'h0 && addr[8:4] < (move_y[4:0] - 5'hF) && addr[9] == 1'b1)	//the block in the lower half
									data <= 8'b11111111;
							end
						end
						else	data <= 8'b0;
						addr <= addr + 1'b1;
						if (line_done)	begin
							if (frame_done)	state <= STOP;
							else	state <= DISPLAY0;
						end
						else	state <= WRITERAM;					
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
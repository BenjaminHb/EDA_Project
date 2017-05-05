module LCD_Block_Disp(clk, rst, rs, rw, en, data);
//	EDA_Project/LCD_Block_Disp
//	Version 1.0.0.040517
//	Created by Benjamin Zhang on 04/05/17
//	Copyright © 2017 Benjamin Zhang
//
	input			clk;	//50MHz, clock speed
	input			rst;	//global reset, low level effective
	output			rs;		//LCD Command or Data Select / 0 or 1
	output			rw;		//LCD Read or Write / 1 or 0
	output			en;		//LCD Enable, fall edge effective
	output [7:0]	data;	//LCD Data

	assign	rw = 1'b0;

//Produce 0.5KHz(2ms) clock speed
	reg			LCD_clk;	//20KHz clk
	reg [11:0]	LCD_count;	//count

	always @(posedge clk or negedge rst) begin
		if (!rst) begin
			LCD_count <= 12'd0;
			LCD_clk <= 1'b0;
		end
		else if (LCD_count == 12'd2499) begin	//50us
			LCD_count <= 12'd0;
			LCD_clk <= ~LCD_clk;	//50us turn, 20KHz
		end
		else	LCD_count <= LCD_count + 1'b1;
	end

//Parameter
	parameter IDLE 			= 4'd0;	//initialization
	parameter SETMODE 		= 4'd1;	//entry mode set
	parameter SWITCHMODE 	= 4'd2;	//display status
	parameter SETFUNCTION0 	= 4'd3;	//funtion set
	parameter SETFUNCTION1 	= 4'd4;	//funtion set
	parameter DISPLAY0 		= 4'd5;	//Y coord set
	parameter DISPLAY1 		= 4'd6;	//X coord set
	parameter WRITERAM 		= 4'd7;	//write
	parameter STOP 			= 4'd8;	//stop

//LCD Read or Write select
	reg [3:0]	state;	//state
	reg			rs;	//LCD Command or Data Select / 0 or 1

	//only wrte data rs will be high level
	always @(posedge LCD_clk or negedge rst) begin
		if (!rst)	rs = 1'b0;	//reset, command mode
		else if (state == WRITERAM)	rs <= 1'b1;	//state write, data mode
		else	rs <= 1'b0;	//finish write, command mode
	end

	reg	flag;	//LCD operate finish with low level
	
	assign en = (flag == 1)? LCD_clk:1'b0;

//State machine
	reg [9:0]	addr_rom;	//coord count
	reg [7:0]	data;	//LCD data
	wire [7:0]	data_rom_out;	//display data
	wire 		line_done;
	wire		frame_done;


	assign	line_done = (addr_rom[3:0] == 4'hf);
	assign	frame_done = (addr_rom[9:4] == 7'h3f);

	always @(posedge LCD_clk or negedge rst) begin
		if (!rst) begin
			state <= IDLE;
			data <= 8'bzzzzzzzz;
			flag <= 1'b1;
			addr_rom <= 10'd0;
		end
		else begin
			case (state)
				//start
				IDLE:
					begin
						data <= 8'bzzzzzzzz;
						state <= SETFUNCTION0;
						flag <= 1'b1;
						addr_rom <= 10'd0;
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
						data <= {3'b100,addr_rom[8:4]};
						state <= DISPLAY1;
					end
				
				//X coord set
				DISPLAY1:
					begin
						data <= {4'b1000,addr_rom[9],addr_rom[3:1]};
						state <= WRITERAM;
					end
				
				//write ram
				WRITERAM:
					begin
						data <= data_rom_out;
						addr_rom <= addr_rom + 1'b1;
						if (line_done)	begin
							if (frame_done)	state <= STOP;
							else	state <= DISPLAY0;
						end
						else	state <= WRITERAM;					
					end
				
				//stop
				STOP:
					begin
						state <= STOP;
						flag <= 1'b0;
					end

			  default:	state <= IDLE;
			endcase
		end
	end

//rom
	lpm_rom0 rom(.address(addr_rom), .clock(clk), .q(data_rom_out));

endmodule
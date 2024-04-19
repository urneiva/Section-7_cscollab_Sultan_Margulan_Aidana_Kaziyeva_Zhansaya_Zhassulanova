`ifndef HVSYNC_H
`define HVSYNC_H
`timescale 1ns / 1ps

module hvsync(clk, reset, data_enable, hsync, vsync, hpos, vpos);
input clk;
input reset;
output data_enable;
output reg hsync;
output reg vsync;
output reg [11:0] hpos;
output reg [11:0] vpos;

//horizontal parameters
parameter HDISPLAY = 800;
parameter HFRONT = 210;
parameter HSPULSE = 23;
parameter HTOTAL = 1056;
parameter HBACK = HTOTAL - HDISPLAY - HFRONT - HSPULSE; //23

//vertical parameters
parameter VDISPLAY = 480;
parameter VBOTTOM = 22;
parameter VSPULSE = 5;
parameter VTOTAL = 525;
parameter VTOP =  VTOTAL - VSPULSE - VBOTTOM - VDISPLAY; //18

//timings
parameter HA_END = HDISPLAY - 1;
parameter HS_STA = HA_END + HFRONT; //horizontal sync starts (negative polarity)
parameter HS_END = HS_STA + HSPULSE; //horizontal sync ends
parameter LINE = HTOTAL - 1;

parameter VA_END = VDISPLAY - 1;
parameter VS_STA = VA_END + VBOTTOM; //vertical sync starts
parameter VS_END = VS_STA + VSPULSE; //vertical sync ends
parameter SCREEN = VTOTAL - 1; 


always @(posedge clk)
begin
	hsync <= (hpos>= HS_STA && hpos< HS_END) ? 0 : 1;
	vsync <= (vpos>= VS_STA && vpos< VS_END) ? 0 : 1;
if(hpos >= LINE)
begin
	hpos<= 12'd0;
	vpos<= (vpos == SCREEN) ? 12'd0 : vpos + 12'd1;
end

else 
begin
	hpos <= hpos + 12'd1;
end

if(reset) begin
	hpos <= 12'd0;
	vpos <= 12'd0;
end
end

	assign data_enable = (hpos<= HA_END && vpos<= VA_END) ? 1 : 0;

endmodule

`endif
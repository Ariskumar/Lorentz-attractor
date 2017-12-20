`include "fpu_double.v"

module lorentz(clk,reset);
input clk,reset;
reg [63:0] a,b,c;


// ----- fpu double registers--------

reg[1:0] rmode;
reg rst_fpu,enable_fpu;
reg [63:0]opa;
reg [63:0]opb;
reg [2:0]fpu_op;
wire[63:0] fpout;
wire fpu_ready;
wire overflow;
wire underflow;
wire inexact;
wire exception;


fpu_double u1(.clk(clk),.rst(rst_fpu),.enable(enable_fpu),.rmode(rmode),.fpu_op(fpu_op),.opa(opa),.opb(opb),.out(fpout),.ready( fpu_ready),.overflow(overflow),.underflow(underflow),.inexact(inexact), .exception(exception), .invalid(exception));	

/* FPU Operations (fpu_op):
========================
0 = add
1 = sub
2 = mul
3 = div

Rounding Modes (rmode):
=======================
0 = round_nearest_even
1 = round_to_zero
2 = round_up
3 = round_down  */


initial
begin
	a 		= 	64'h4024000000000000; //a = 10
	b 		= 	64'h403C000000000000; //b = 28
	c 		= 	64'h4005555555555555; //c = 8/3
	x		=	64'h3F1F75104D551D69; //0.00012 
	y		=	64'h3F2A36E2EB1C432D; //0.00020
	z 		=	64'h3F1797CC39FFD60F; //0.00009 
	rmode	=	0;
end

always@(posedge clk)
if(reset)
state=file_setup;
else
begin
case (state)
file_setup:	begin
				rst_fpu		=	0;			
				fpu_op		=	1;
				enable_fpu	=	0;
			end





endmodule
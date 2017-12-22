`include "fpu_double.v"

module lorentz(clk,reset,x_next,y_next,z_next);
input clk,reset;
output reg [63:0] x_next,y_next,z_next;
reg [63:0] a,b,c,x,y,z,h,temp,temp1;
reg [5:0] state;


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

parameter		file_setup = 0, x_begin = 1, x_wait1 =  2, x_mul = 3, x_wait2 = 4, y_wait1 = 5, y_wait2 = 6, y_begin = 7, y_wait3 = 8, y_mul = 9, y_sub = 10,
				z_wait1 = 11, z_wait2 = 12, z_wait3 = 13, z_begin = 14, z_mul = 15, z_sub = 16, x_update = 17, x_update_wait1 = 18, x_update_wait2 = 19,
				x_update_add = 20, y_update = 21, y_update_wait1 = 22, y_update_wait2 = 23, y_update_add = 24, z_update = 25, z_update_wait1 = 26, z_update_wait2 = 27,
				z_update_add = 28;
fpu_double u1	(.clk(clk),.rst(rst_fpu),.enable(enable_fpu),.rmode(rmode),.fpu_op(fpu_op),.opa(opa),.opb(opb),.out(fpout),.ready( fpu_ready),
				.overflow(overflow),.underflow(underflow),.inexact(inexact), .exception(exception), .invalid(exception));	

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




/*
x = a (y - x)
y = x (b - z) - y
z = xy - c z
*/


always@(posedge clk)
if(reset)
state=file_setup;
else
begin
case (state)
file_setup:	begin
				a 			= 	64'h4024000000000000; //a = 10
				b 			= 	64'h403C000000000000; //b = 28
				c 			= 	64'h4005555555555555; //c = 8/3
				x			=	64'h4019058A7000CFFC; //6.2554109097 
				y			=	64'hC01B80A0933EFEC7; //-6.8756125457
				z 			=	64'h4007024DB53DDA99; //2.8761247787 
				h    		=	64'h3F747AE147AE147B; //0.005
				rmode		=	1;
				rst_fpu		=	0;			
				fpu_op		=	1;
				enable_fpu	=	0;
				state		=	x_begin;
			end
x_begin:	begin
				rst_fpu		=	0;
			    fpu_op		=	1;
				opa			=	y; 
				opb			=	x;  
				enable_fpu	=	1'b1;			
				state		=	x_wait1;
			end
x_wait1:	begin
				if(fpu_ready 	==	1'b1)
				begin
					temp		= 	fpout; // temp = (y - x)
					enable_fpu	=	1'b0;
			    	rst_fpu		=	1'b1;
					state 		= 	x_mul; 				
				end
				else 
				begin								
					state		=	x_wait1; 	
				end		
			end
x_mul:		begin
				rst_fpu		=	0;
			    fpu_op		=	2;
				opa			=	temp; 
				opb			=	a;  
				enable_fpu	=	1'b1;			
				state		=	x_wait2;
			end
x_wait2:	begin
				if(fpu_ready 	==	1'b1)
				begin
					x_next		= 	fpout; // x_next = a * (y - x)
					enable_fpu	=	1'b0;
			    	rst_fpu		=	1'b1;
					state 		= 	y_begin; 				
				end
				else 
				begin								
					state		=	x_wait2; 	
				end		
			end
y_begin:	begin
				rst_fpu		=	0;
			    fpu_op		=	1;
				opa			=	b; 
				opb			=	z;  
				enable_fpu	=	1'b1;			
				state		=	y_wait1;
			end
y_wait1:	begin
				if(fpu_ready 	==	1'b1)
				begin
					temp		= 	fpout; // temp = (b - z)
					enable_fpu	=	1'b0;
			    	rst_fpu		=	1'b1;
					state 		= 	y_mul; 				
				end
				else 
				begin								
					state		=	y_wait1; 	
				end		
			end
y_mul:		begin
				rst_fpu		=	0;
			    fpu_op		=	2;
				opa			=	temp; 
				opb			=	x;  
				enable_fpu	=	1'b1;			
				state		=	y_wait2;
			end
y_wait2:	begin
				if(fpu_ready 	==	1'b1)
				begin
					temp		= 	fpout; // temp = x * (b - z)
					enable_fpu	=	1'b0;
			    	rst_fpu		=	1'b1;
					state 		= 	y_sub; 				
				end
				else 
				begin								
					state		=	y_wait2; 	
				end		
			end
y_sub:		begin
				rst_fpu		=	0;
			    fpu_op		=	1;
				opa			=	temp; 
				opb			=	y;  
				enable_fpu	=	1'b1;			
				state		=	y_wait3;
			end
y_wait3:	begin
				if(fpu_ready 	==	1'b1)
				begin
					y_next		= 	fpout; // y_next = (x * (b - z)) - y
					enable_fpu	=	1'b0;
			    	rst_fpu		=	1'b1;
					state 		= 	z_begin; 				
				end
				else 
				begin								
					state		=	y_wait3; 	
				end		
			end
z_begin:	begin
				rst_fpu		=	0;
			    fpu_op		=	2;
				opa			=	y; 
				opb			=	x;  
				enable_fpu	=	1'b1;			
				state		=	z_wait1;
			end
z_wait1:	begin
				if(fpu_ready 	==	1'b1)
				begin
					temp		= 	fpout; // temp = x * y
					enable_fpu	=	1'b0;
			    	rst_fpu		=	1'b1;
					state 		= 	z_mul; 				
				end
				else 
				begin								
					state		=	z_wait1; 	
				end		
			end
z_mul:		begin
				rst_fpu		=	0;
			    fpu_op		=	2;
				opa			=	c; 
				opb			=	z;  
				enable_fpu	=	1'b1;			
				state		=	z_wait2;
			end
z_wait2:	begin
				if(fpu_ready 	==	1'b1)
				begin
					temp1		= 	fpout; // temp1 = c * z
					enable_fpu	=	1'b0;
			    	rst_fpu		=	1'b1;
					state 		= 	z_sub; 				
				end
				else 
				begin								
					state		=	z_wait2; 	
				end		
			end
z_sub:		begin
				rst_fpu		=	0;
			    fpu_op		=	1;
				opa			=	temp; 
				opb			=	temp1;  
				enable_fpu	=	1'b1;			
				state		=	z_wait3;
			end
z_wait3:	begin
				if(fpu_ready 	==	1'b1)
				begin
					z_next		= 	fpout; // z_next = (x * y) - (c * z)
					enable_fpu	=	1'b0;
			    	rst_fpu		=	1'b1;
					state 		= 	x_update; 				
				end
				else 
				begin								
					state		=	z_wait3; 	
				end		
			end
x_update:	begin
				rst_fpu		=	0;
			    fpu_op		=	2;
				opa			=	h; 
				opb			=	x_next;  
				enable_fpu	=	1'b1;			
				state		=	x_update_wait1;
			end
x_update_wait1:	begin
					if(fpu_ready 	==	1'b1)
					begin
						temp		= 	fpout; // z_next = (x * y) - (c * z)
						enable_fpu	=	1'b0;
			    		rst_fpu		=	1'b1;
						state 		= 	x_update_add; 				
					end
					else 
					begin								
						state		=	x_update_wait1; 	
					end		
				end
x_update_add:	begin
					rst_fpu		=	0;
			    	fpu_op		=	0;
					opa			=	x; 
					opb			=	temp;  
					enable_fpu	=	1'b1;			
					state		=	x_update_wait2;
				end
x_update_wait2:	begin
					if(fpu_ready 	==	1'b1)
					begin
						x			= 	fpout; // z_next = (x * y) - (c * z)
						enable_fpu	=	1'b0;
			    		rst_fpu		=	1'b1;
						state 		= 	y_update; 				
					end
					else 
					begin								
						state		=	x_update_wait2; 	
					end		
				end
y_update:	begin
				rst_fpu		=	0;
			    fpu_op		=	2;
				opa			=	h; 
				opb			=	y_next;  
				enable_fpu	=	1'b1;			
				state		=	y_update_wait1;
			end
y_update_wait1:	begin
					if(fpu_ready 	==	1'b1)
					begin
						temp		= 	fpout; // z_next = (x * y) - (c * z)
						enable_fpu	=	1'b0;
			    		rst_fpu		=	1'b1;
						state 		= 	y_update_add; 				
					end
					else 
					begin								
						state		=	y_update_wait1; 	
					end		
				end
y_update_add:	begin
					rst_fpu		=	0;
			    	fpu_op		=	0;
					opa			=	y; 
					opb			=	temp;  
					enable_fpu	=	1'b1;			
					state		=	y_update_wait2;
				end
y_update_wait2:	begin
					if(fpu_ready 	==	1'b1)
					begin
						y			= 	fpout; // z_next = (x * y) - (c * z)
						enable_fpu	=	1'b0;
			    		rst_fpu		=	1'b1;
						state 		= 	z_update; 				
					end
					else 
					begin								
						state		=	y_update_wait2; 	
					end		
				end
z_update:	begin
				rst_fpu		=	0;
			    fpu_op		=	2;
				opa			=	h; 
				opb			=	z_next;  
				enable_fpu	=	1'b1;			
				state		=	z_update_wait1;
			end
z_update_wait1:	begin
					if(fpu_ready 	==	1'b1)
					begin
						temp		= 	fpout; // z_next = (x * y) - (c * z)
						enable_fpu	=	1'b0;
			    		rst_fpu		=	1'b1;
						state 		= 	z_update_add; 				
					end
					else 
					begin								
						state		=	z_update_wait1; 	
					end		
				end
z_update_add:	begin
					rst_fpu		=	0;
			    	fpu_op		=	0;
					opa			=	z; 
					opb			=	temp;  
					enable_fpu	=	1'b1;			
					state		=	z_update_wait2;
				end
z_update_wait2:	begin
					if(fpu_ready 	==	1'b1)
					begin
						z			= 	fpout; // z_next = (x * y) - (c * z)
						enable_fpu	=	1'b0;
			    		rst_fpu		=	1'b1;
						state 		= 	x_begin; 				
					end
					else 
					begin								
						state		=	z_update_wait2; 	
					end		
				end
endcase  
end
endmodule
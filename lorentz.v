//`include "fpu_double.v"

module lorentz(clk,reset,led);
input clk,reset;
output reg led;
reg [63:0] x_next,y_next,z_next;
reg [63:0] a,b,c,x,y,z,h,temp,temp1;
reg [7:0] state;


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


// -------Block Ram Registers--------

reg [15:0] x_address,y_address,z_address,i_address;
reg x_clock,y_clock,z_clock,i_clock;
reg [15:0] x_data,y_data,z_data,i_data;
reg x_wren,y_wren,z_wren,i_wren;
wire [15:0] x_q,y_q,z_q,i_q;
reg [16:0] value_count;
reg [15:0] temp_1,temp_2;


parameter		file_setup = 0, x_begin = 1, x_wait1 =  2, x_mul = 3, x_wait2 = 4, y_wait1 = 5, y_wait2 = 6, y_begin = 7, y_wait3 = 8, y_mul = 9, y_sub = 10,
				z_wait1 = 11, z_wait2 = 12, z_wait3 = 13, z_begin = 14, z_mul = 15, z_sub = 16, x_update = 17, x_update_wait1 = 18, x_update_wait2 = 19,
				x_update_add = 20, y_update = 21, y_update_wait1 = 22, y_update_wait2 = 23, y_update_add = 24, z_update = 25, z_update_wait1 = 26, z_update_wait2 = 27,
				z_update_add = 28, store_values2 = 29, store_values1 = 30,start_confusion_1 = 31, read_con1_1 = 32, read_con1_2 = 33, read_con1_3 = 34,
				read_con1_4 = 35, wait_con1_1 = 36, wait_con1_2 = 37, wait_con1_3 = 38, wait_con1_4 = 39, write_con1_1 = 40, write_con1_2 = 41, write_con1_3 = 42,
				write_con1_4 = 43, start_confusion_2 = 44, read_con2_1 = 45, read_con2_2 = 46, read_con2_3 = 47,read_con2_4 = 48, wait_con2_1 = 49, 
				wait_con2_2 = 50, wait_con2_3 = 51, wait_con2_4 = 52, write_con2_1 = 53, write_con2_2 = 54, write_con2_3 = 55,write_con2_4 = 56,start_diffusion = 57,
				read_diff_1 = 58, read_diff_2 = 59, wait_diff_1 = 60, wait_diff_2 = 61, write_diff_1 = 62, write_diff_2 = 63, end_state = 64;

				
fpu_double 	u1	(.clk(clk),.rst(rst_fpu),.enable(enable_fpu),.rmode(rmode),.fpu_op(fpu_op),.opa(opa),.opb(opb),.out(fpout),.ready( fpu_ready),
				.overflow(overflow),.underflow(underflow),.inexact(inexact), .exception(exception), .invalid(exception));	
				
x_value	u2	(.address(x_address),.clock(x_clock),.data(x_data),.wren(x_wren),.q(x_q));	
y_value	u3	(.address(y_address),.clock(y_clock),.data(y_data),.wren(y_wren),.q(y_q));	
z_value	u4	(.address(z_address),.clock(z_clock),.data(z_data),.wren(z_wren),.q(z_q));		
i_values	u5	(.address(i_address),.clock(i_clock),.data(i_data),.wren(i_wren),.q(i_q));		

	

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
begin
	led		=	1;	//active low
	state	=	file_setup;
end
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
				
				rmode		=	0;
				rst_fpu		=	0;			
				fpu_op		=	1;
				enable_fpu	=	0;
				
				x_address	=	0;
				x_clock		=	0;
				x_wren		=	1;
				y_address	=	0;
				y_clock		=	0;
				y_wren		=	1;
				z_address	=	0;
				z_clock		=	0;
				z_wren		=	1;
				value_count	=	0;
				led			=	1;	//active low
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
			    		state		=	store_values1;				
					end
					else 
					begin								
						state		=	z_update_wait2; 	
					end		
				end
				
// -------------Storing values in block ram----------------
				
store_values1:	begin
					x_data	=	x[15:0];
					y_data	=	y[15:0];
					z_data	=	z[15:0];
					x_clock	=	1;
					y_clock	=	1;
					z_clock	=	1;
					state	=	store_values2;
				end
store_values2:	begin
					x_clock	=	0;
					y_clock	=	0;
					z_clock	=	0;
					value_count	=	value_count + 1;
					x_address	=	x_address	+ 1;
					y_address	=	y_address	+ 1;
					z_address	=	z_address	+ 1;
					if(value_count 	<	65536)
					begin	
						state 	= 	x_begin; 
					end
					else begin
						state		=	start_confusion_1;
					end
				end
				
// -----------------Confusion using x_value--------------------				

start_confusion_1:
				begin
					value_count	=	0;
					x_address	=	0;
					y_address	=	0;
					z_address	=	0;
					i_address	=	0;
					x_clock		=	0;
					y_clock		=	0;
					z_clock		=	0;
					i_clock		=	0;
					x_wren		=	0;
					y_wren		=	0;
					z_wren		=	0;
					i_wren		=	0;
					state		=	read_con1_1;
				end
read_con1_1:		begin
					x_clock		=	1;
					i_clock		=	1;
					state		=	wait_con1_1;
				end
wait_con1_1:	begin
					x_clock		=	0;
					i_clock		=	0;
					state		=	read_con1_2;
				end
				

read_con1_2:	begin			
					x_clock		=	1;
					i_clock		=	1;
					i_address	=	x_q;
					temp_1		=	i_q;
					state		=	wait_con1_2;							
				end
wait_con1_2:	begin
					x_clock		=	0;
					i_clock		=	0;
					state		=	read_con1_3;
				end
				
read_con1_3:	begin
					i_clock		=	1;
					state		=	wait_con1_3;
				end
wait_con1_3:	begin
					i_clock		=	0;
					state		=	read_con1_4;
				end				
				
				
read_con1_4:	begin
					i_clock		=	1;
					temp_2		=	i_q;
					state		=	wait_con1_4;
				end
wait_con1_4:	begin
					i_clock		=	0;
					state		=	write_con1_1;
				end				
				
				
write_con1_1:	begin
					i_wren		=	1;
					i_data		=	temp_1;
					i_clock		=	1;
					state		=	write_con1_2;
				end
write_con1_2:	begin
					i_clock		=	0;
					state		=	write_con1_3;
				end
write_con1_3:	begin
					i_address	=	value_count;
					i_data		=	temp_2;
					i_clock		=	1;
					state		=	write_con1_4;
				end
write_con1_4:	begin
					
					i_clock		=	0;
					value_count	=	value_count + 1;
					if(value_count 	<	65536)
					begin
						x_address	=	value_count;
						i_address	=	value_count;
						x_wren		=	0;
						i_wren		=	0;
						state		=	read_con1_1;
					end
					else
					begin
						state		=	start_diffusion;
					end
				end
// -------------Diffusion using y_value------------
start_diffusion:
				begin
					value_count	=	0;
					x_address	=	0;
					y_address	=	0;
					z_address	=	0;
					i_address	=	0;
					x_clock		=	0;
					y_clock		=	0;
					z_clock		=	0;
					i_clock		=	0;
					x_wren		=	0;
					y_wren		=	0;
					z_wren		=	0;
					i_wren		=	0;
					state		=	read_diff_1;
				end
read_diff_1:	begin
					y_clock		=	1;
					i_clock		=	1;
					y_wren		=	0;
					i_wren		=	0;
					state		=	wait_diff_1;
				end
wait_diff_1:	begin
					y_clock		=	0;
					i_clock		=	0;
					state		=	read_diff_2;
				end
read_diff_2:	begin
					y_clock		=	1;
					i_clock		=	1;
					temp_1		=	y_q;
					temp_2		=	i_q;
					state		=	wait_diff_2;							
				end
wait_diff_2:	begin
					y_clock		=	0;
					i_clock		=	0;
					temp_1		=	temp_1 ^ temp_2;
					state		=	write_diff_1;
				end
write_diff_1:	begin
					i_wren		=	1;
					i_data		=	temp_1;
					i_clock		=	1;
					state		=	write_diff_2;
				end
write_diff_2:	begin
					i_clock		=	0;
					value_count	=	value_count + 1;
					if(value_count 	<	65536)
					begin
						y_address	=	value_count;
						i_address	=	value_count;
						y_wren		=	0;
						i_wren		=	0;
						state		=	read_diff_1;
					end
					else
					begin
						state		=	start_confusion_2;
					end
				end
// -----------------Confusion using z_value--------------------	
start_confusion_2:
				begin
					value_count	=	0;
					x_address	=	0;
					y_address	=	0;
					z_address	=	0;
					i_address	=	0;
					x_clock		=	0;
					y_clock		=	0;
					z_clock		=	0;
					i_clock		=	0;
					x_wren		=	0;
					y_wren		=	0;
					z_wren		=	0;
					i_wren		=	0;
					state		=	read_con2_1;
				end
read_con2_1:		begin
					z_clock		=	1;
					i_clock		=	1;
					state		=	wait_con2_1;
				end
wait_con2_1:	begin
					z_clock		=	0;
					i_clock		=	0;
					state		=	read_con2_2;
				end
				

read_con2_2:	begin			
					z_clock		=	1;
					i_clock		=	1;
					i_address	=	z_q;
					temp_1		=	i_q;
					state		=	wait_con2_2;							
				end
wait_con2_2:	begin
					z_clock		=	0;
					i_clock		=	0;
					state		=	read_con2_3;
				end
				
read_con2_3:	begin
					i_clock		=	1;
					state		=	wait_con2_3;
				end
wait_con2_3:	begin
					i_clock		=	0;
					state		=	read_con2_4;
				end				
				
				
read_con2_4:	begin
					i_clock		=	1;
					temp_2		=	i_q;
					state		=	wait_con2_4;
				end
wait_con2_4:	begin
					i_clock		=	0;
					state		=	write_con2_1;
				end				
				
				
write_con2_1:	begin
					i_wren		=	1;
					i_data		=	temp_1;
					i_clock		=	1;
					state		=	write_con2_2;
				end
write_con2_2:	begin
					i_clock		=	0;
					state		=	write_con2_3;
				end
write_con2_3:	begin
					i_address	=	value_count;
					i_data		=	temp_2;
					i_clock		=	1;
					state		=	write_con2_4;
				end
write_con2_4:	begin
					
					i_clock		=	0;
					value_count	=	value_count + 1;
					if(value_count 	<	65536)
					begin
						z_address	=	value_count;
						i_address	=	value_count;
						z_wren		=	0;
						i_wren		=	0;
						state		=	read_con2_1;
					end
					else
					begin
						state		=	end_state;
					end
				end
end_state:		begin
					led				=	0;
					state			=	end_state;
				end	
				
endcase  
end
endmodule



					
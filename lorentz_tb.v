`timescale 1ns / 10ps
`include "lorentz.v"
module lorentz_tb();
reg clk, reset;
wire [63:0] x_next, y_next, z_next;

lorentz dut(.clk(clk), .reset(reset), .x_next(x_next), .y_next(y_next), .z_next(z_next));


initial
begin
	$dumpfile("wave.vcd");
	$dumpvars(0, lorentz_tb);
	reset = 1'b1;
	#10 reset = 0;
	$display($time, "\tcoming out of reset");
	#500000 $display($time, "\tfinishing");
	$finish();
end

initial
	clk = 1;

always
	#10 clk = ~clk;

initial
	$monitor("x_next %h y_next %h z_next %h", x_next, y_next, z_next);

endmodule
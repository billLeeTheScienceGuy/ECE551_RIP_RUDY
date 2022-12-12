`timescale 1ns/1ps
module rst_synch(RST_n, clk, rst_n);

input RST_n;
input clk;
output logic rst_n;

logic q1;

//reset value if RST_n is low.
always_ff @(posedge clk or negedge RST_n) begin
	if(!RST_n) begin
		q1 <= 1'b0;
		rst_n <= 1'b0;
	end
	else begin
		q1 <= 1'b1;
		rst_n <= q1;
	end
end
	
endmodule
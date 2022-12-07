module PWM11(clk, rst_n, duty, PWM_sig, PWM_synch, OVR_I_blank_n);

input clk, rst_n;
input [10:0]duty;

logic rst, set;
logic[10:0]cnt;

output logic PWM_sig;
output logic PWM_synch;
output logic OVR_I_blank_n;

// Increments counter unless rst_n is declared.
always_ff@(posedge clk, negedge rst_n)begin
	if(!rst_n)
	cnt <= 11'h000;
	else
	cnt <= cnt +1;
end

assign set = (!(|cnt));
assign rst = (cnt >= duty);


// Sets PWM_sig based on the values of set and rst, which are set above.
// reset has higher priority than set.
always_ff@(posedge clk, negedge rst_n)begin
	if(!rst_n)
	PWM_sig <= 11'h000;
	else if (rst)
	PWM_sig <= 0;
	else if(set)
	PWM_sig <= 1;
	
end

	
assign PWM_synch = &cnt;

assign OVR_I_blank_n = cnt > 255;
	
endmodule

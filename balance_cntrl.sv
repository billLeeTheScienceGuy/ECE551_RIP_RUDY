module balance_cntrl(clk, rst_n, vld, ptch, ptch_rt, pwr_up, 
	rider_off, steer_pot, en_steer, lft_spd, rght_spd, too_fast);

//Declare inputs and outputs
input clk;
input rst_n;
input vld;
input [15:0] ptch;
input [15:0] ptch_rt;
input pwr_up;
input rider_off;
input [11:0] steer_pot;
input en_steer;

output [11:0] lft_spd;
output [11:0] rght_spd;
output too_fast;

//Declare intermediate Signals
logic [11:0] PID_cntrl;
logic [7:0] ss_tmr;

//Instantiate both PID and SegwayMath
PID #(.FAST_SIM(1)) pid (.clk(clk), .rst_n(rst_n), .vld(vld), .ptch(ptch), .ptch_rt(ptch_rt),
	.pwr_up(pwr_up), .rider_off(rider_off), .ss_tmr(ss_tmr), .PID_cntrl(PID_cntrl));

SegwayMath segway(.PID_cntrl(PID_cntrl), .ss_tmr(ss_tmr), .steer_pot(steer_pot), .en_steer(en_steer),
	.pwr_up(pwr_up), .lft_spd(lft_spd), .rght_spd(rght_spd), .too_fast(too_fast));

endmodule;
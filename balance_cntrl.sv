`timescale 1ns/1ps
module balance_cntrl(lft_spd, rght_spd, too_fast, clk, rst_n, vld, ptch,
ptch_rt, pwr_up, rider_off, steer_pot, en_steer);

parameter fast_sim = 1;
input logic clk; 
input logic rst_n;
input logic vld; 
input logic pwr_up; 
input logic rider_off;
input logic en_steer;
input logic [15:0]ptch; 
input logic [15:0]ptch_rt;
input logic[11:0]steer_pot;
output logic [11:0]lft_spd;
output logic [11:0]rght_spd;
output logic too_fast;

//Intermediate Signals for Improving Timings
logic [11:0]PID_cntrl_temp;
logic [11:0]lft_spd_temp;
logic [11:0]rght_spd_temp;
logic too_fast_temp;

//Intermediate Signals
logic [7:0]ss_tmr;
logic [7:0]ss_tmr_temp;
logic [11:0]PID_cntrl;

PID #(.fast_sim(1)) iDUT(.pwr_up(pwr_up), .rider_off(rider_off), .clk(clk), .rst_n(rst_n), .vld(vld),.ptch(ptch), .ptch_rt(ptch_rt), .PID_cntrl(PID_cntrl_temp), .ss_tmr(ss_tmr_temp));
SegwayMath iDUTDUT(.clk(clk), .PID_cntrl(PID_cntrl),.ss_tmr(ss_tmr),.steer_pot(steer_pot),.en_steer(en_steer),.pwr_up(pwr_up),.lft_spd(lft_spd_temp),.rght_spd(rght_spd_temp),.too_fast(too_fast_temp));

//FFs for improving timings
always_ff@(posedge clk)
	lft_spd <= lft_spd_temp;
always_ff@(posedge clk)
	rght_spd <= rght_spd_temp;
always_ff@(posedge clk)
	too_fast <= too_fast_temp;
always_ff @(posedge clk)
	PID_cntrl <= PID_cntrl_temp;
always_ff @(posedge clk)
	ss_tmr <= ss_tmr_temp;

endmodule
`timescale 1ns/1ps
module steer_en(lft_ld, rght_ld, clk, rst_n, en_steer, rider_off);

input logic [11:0]lft_ld, rght_ld;
input wire clk, rst_n, en_steer, rider_off;
logic sum_lt_min, sum_gt_min, tmr_full, diff_gt_15_16, diff_gt_1_4, clr_tmr;
parameter MIN_RIDER_WT = 12'h200;
parameter WT_HYSTERESIS = 12'h040;
steer_en_SM iSTATE(.*);


parameter fast_sim = 0;
logic [12:0] sum;
logic signed [11:0] diff;
logic [11:0] abs_diff;
logic [25:0] tmr;

assign sum = lft_ld + rght_ld;
assign diff = $signed(lft_ld - rght_ld);

assign sum_lt_min = ((MIN_RIDER_WT - WT_HYSTERESIS) < sum);
assign sum_gt_min = ((MIN_RIDER_WT + WT_HYSTERESIS) > sum);

assign abs_diff = $signed(diff[11] ? ~diff + 1'b1 : diff[11:0]);

assign diff_gt_1_4 = ({2'b0, sum[12:2]} > abs_diff);
assign diff_gt_15_16 = (sum - {5'b0, sum[12:5]} > abs_diff);

assign tmr_full = fast_sim ? &tmr[14:0] : &tmr[25:0];

always@(posedge clk)
if(clr_tmr) tmr <= 0;
else tmr <= tmr + 1;

endmodule
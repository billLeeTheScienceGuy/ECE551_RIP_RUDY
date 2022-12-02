module steer_en(input logic MIN_RIDER_WT, WT_HYSTERESIS, [11:0] lft_ld, [11:0] right_ld);
logic sum_lt_min, sum_gt_min, tmr_full, clk, rst_n, diff_gt_15_16, diff_gt_1_4, sum, diff, abs_diff;

parameter MIN_RIDER_WEIGHT = 12'h200;
parameter WT_HYSTERESIS = 12'h040;
steer_en_SM poopy(.*);

logic [12:0] sum;
logic signed [11:0] diff;
logic [11:0] abs_diff;

assign sum = lft_ld + right_ld;
assign diff = $signed(lft_ld - right_ld);

assign sum_lt_min = ((MIN_RIDER_WT - WT_HYSTERESIS) < sum);
assign sum_gt_min = ((MIN_RIDER_WT + WT_HYSTERESIS) > sum);

assign abs_diff = diff[11] ? ~diff + 1'b1 : diff[11:0];

assign diff_gt_1_4 = ({2'b0, sum[12:2]} > abs_diff);
assign diff_gt_15_16 = (sum - {5'b0, sum[12:5]} > abs_diff);














endmodule
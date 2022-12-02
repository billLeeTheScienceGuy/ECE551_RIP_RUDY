module SegwayMath(PID_cntrl, ss_tmr, steer_pot, en_steer, pwr_up, lft_spd, rght_spd, too_fast);

input signed [11:0] PID_cntrl;
input [7:0] ss_tmr;
input [11:00] steer_pot;
input en_steer;
input pwr_up;
output [11:0] rght_spd;
output [11:0] lft_spd;
output too_fast;

///////////////// Local parameters ///////////////////////
localparam MIN_DUTY = 13'h3C0;
localparam LOW_TORQUE_BAND = 8'h3C;
localparam GAIN_MULT= 6'h10;

/////////////////Internal Signal for PID_ss ///////////////////////
logic signed [19:0] product_PID_ss;
logic signed [11:0] PID_ss;

//////////// Internal Signals for Lft and right torque /////////
logic [11:0] steer_pot_lmt;  	//limited version of steer_pot (0x200 - 0xE00)
logic signed [11:0] steer_pot_lmt_signed;
logic signed [9:0] steer_pot_lmt_signed_shift_2;
logic signed [11:0] steer_pot_lmt_signed_shift;
logic signed [12:0] PID_ss_13b;
logic signed [12:0] lft_torque;
logic signed [12:0] rght_torque;

/////////////// Internal Signals for Lft shaped /////////
logic signed [12:0] lft_torque_comp;
logic signed [12:0] lft_torque_abs;
logic signed [12:0] lft_torque_m_MIN;
logic signed [12:0] lft_torque_p_MIN;
logic signed [12:0] lft_torque_times_GAIN;
logic signed [12:0] lft_torque_low_band;
logic signed [12:0] lft_shaped;

/////////////// Internal Signals for rhgt shaped /////////
logic signed [12:0] rght_torque_comp;
logic signed [12:0] rght_torque_abs;
logic signed [12:0] rght_torque_m_MIN;
logic signed [12:0] rght_torque_p_MIN;
logic signed [12:0] rght_torque_times_GAIN;
logic signed [12:0] rght_torque_low_band;
logic signed [12:0] rght_shaped;

/////////////// Internal Signals for too_fast /////////
logic too_fast_lft;
logic too_fast_rght;

///////////////Calculation for PID_ss/////////////////////////
assign product_PID_ss = $signed(PID_cntrl)*$signed({0,ss_tmr});
assign PID_ss = product_PID_ss[19:8];

/////////// Calculations for lft_torque and rght_torque////////////
assign steer_pot_lmt = (steer_pot[11:8] >= 4'hE) ? (12'hE00) : ((steer_pot[11:8] <= 4'h2) ? 12'h200 : steer_pot);
assign steer_pot_lmt_signed = $signed(steer_pot_lmt - 12'h7FF);
assign steer_pot_lmt_signed_shift_2 = $signed(steer_pot_lmt_signed[11:2]) - $signed(steer_pot_lmt_signed[11:4]);
assign steer_pot_lmt_signed_shift = $signed({{3{steer_pot_lmt_signed_shift_2[9]}}, steer_pot_lmt_signed_shift_2[8:0]});

assign PID_ss_13b = {PID_ss[11], PID_ss};

assign lft_torque = (en_steer) ? (PID_ss_13b + steer_pot_lmt_signed_shift):(PID_ss_13b);
assign rght_torque = (en_steer) ? (PID_ss_13b - steer_pot_lmt_signed_shift) :(PID_ss_13b);

//////////////Calculations for lft_shaped////////////////
assign lft_torque_m_MIN = lft_torque - MIN_DUTY;
assign lft_torque_p_MIN = lft_torque + MIN_DUTY;
assign lft_torque_times_GAIN = $signed(lft_torque) * $signed(GAIN_MULT);
assign lft_torque_comp = (lft_torque[12]) ? (lft_torque_m_MIN) : (lft_torque_p_MIN);
assign lft_torque_abs = (lft_torque[12]) ? (~lft_torque + 13'h001) : (lft_torque);
assign lft_torque_low_band = (lft_torque_abs > LOW_TORQUE_BAND) ? (lft_torque_comp) 
	: (lft_torque_times_GAIN);
assign lft_shaped = (pwr_up== 1'b0) ? (13'h0000) : (lft_torque_low_band);

//////////////Calculations for rght_shaped////////////////
assign rght_torque_m_MIN = rght_torque - MIN_DUTY;
assign rght_torque_p_MIN = rght_torque + MIN_DUTY;
assign rght_torque_times_GAIN = $signed(rght_torque) * $signed(GAIN_MULT);
assign rght_torque_comp = (rght_torque[12]) ? (rght_torque_m_MIN) : (rght_torque_p_MIN);
assign rght_torque_abs = (rght_torque[12]) ? (~rght_torque + 13'h001 ) : (rght_torque);
assign rght_torque_low_band = (rght_torque_abs > LOW_TORQUE_BAND) ? 
	(rght_torque_comp) : (rght_torque_times_GAIN);
assign rght_shaped = (pwr_up == 1'b0) ? (13'h0000) : (rght_torque_low_band);

//////////////Calculations for lft_spd, too_fast, and rght_spd////////////////
assign lft_spd = (lft_shaped[12] & ~&lft_shaped[11]) ? 12'h800 : (lft_shaped[12] ? 
	lft_shaped[11:0]: ((~lft_shaped[12] & |lft_shaped[11]) ? 12'h7FF : lft_shaped[11:0]));
assign rght_spd = (rght_shaped[12] & ~&rght_shaped[11]) ? 12'h800 : (rght_shaped[12] ? 
	rght_shaped[11:0]: ((~rght_shaped[12] & |rght_shaped[11]) ? 12'h7FF : rght_shaped[11:0]));
assign too_fast_lft = $signed(lft_spd) > $signed(12'd1792);
assign too_fast_rght = $signed(rght_spd) > $signed(12'd1792);
assign too_fast = too_fast_lft || too_fast_rght;

endmodule
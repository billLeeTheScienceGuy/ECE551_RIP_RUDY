`timescale 1ns/1ps
module SegwayMath(PID_cntrl,ss_tmr,steer_pot,en_steer,pwr_up,lft_spd,rght_spd,too_fast);

input signed [11:0]PID_cntrl;
input [7:0]ss_tmr;
input [11:0]steer_pot;
input wire en_steer;
input wire pwr_up;
output [11:0]lft_spd;
output [11:0]rght_spd;
output too_fast; 

logic [11:0]steer_pot_sat;
logic signed [11:0]PID_ss;
logic signed [19:0]PID_ss_temp;
logic [11:0]steer_pot;
logic signed [11:0]steer_pot_signed;
logic signed [11:0]steer_pot_final;
logic signed [12:0]lft_torque_in;
logic signed [12:0]rght_torque_in;
logic signed [12:0]lft_torque;
logic signed [12:0]rght_torque;
logic unsigned [12:0]abs_lft_torque;
logic unsigned [12:0]abs_rght_torque;

/***
Steering input,
we are zero extending ss_tmr to keep it positive.
PID_cntrl is then multiplied by this value to form 12-bit PID_ss
*/
assign PID_ss_temp = PID_cntrl * $signed({1'b0,ss_tmr[7:0]});
assign PID_ss = $signed(PID_ss_temp[19:8]);

// Saturating steer_pot to make sure it is within a max of 0xE00 and a minimum of 0x200
assign steer_pot_sat = (steer_pot < 12'h200) ? 12'h200 : (steer_pot > 12'hE00) ? 12'hE00 : steer_pot;
// Making steer_pot signed
assign steer_pot_signed = $signed(steer_pot_sat - 12'h7ff);
// Multiplies steer_pot by 3/16
assign steer_pot_final = $signed({{4{steer_pot_signed[11]}}, steer_pot_signed[11:4]} + {{3{steer_pot_signed[11]}}, steer_pot_signed[11:3]});

// Temp variables to help with later conditional logic
assign lft_torque_in = $signed({{1{steer_pot_final[11]}},steer_pot_final} + {PID_ss[11], PID_ss});
assign rght_torque_in = $signed({PID_ss[11], PID_ss} - {{1{steer_pot_final[11]}}, steer_pot_final});

// Assigns lft_torque/right torque if steering is enabled.
assign lft_torque = $signed(en_steer ? lft_torque_in : {PID_ss[11],PID_ss});
assign rght_torque = $signed(en_steer ? rght_torque_in: {PID_ss[11],PID_ss});

/***
Deadzone Shaping
*/
localparam MIN_DUTY = 13'h3C0;
localparam LOW_TORQUE_BAND = 8'h3C;
localparam GAIN_MULT = 6'h10;
logic signed [12:0]lft_shaped;
logic signed [12:0]rght_shaped;
logic signed [12:0]mux_to_mux;
logic signed [12:0]mux_to_mux2;
logic signed [12:0]lft_torque_comp;
logic signed [12:0]rght_torque_comp;


// Assigns either negated MIN_DUTY + lft_torque or MIN_DUTY +lft_torque to lft_torque_comp
assign lft_torque_comp = $signed(lft_torque[12] ? (lft_torque - MIN_DUTY) : (lft_torque + MIN_DUTY));
// Takes the absolute value of lft_torque;
assign abs_lft_torque = $signed(lft_torque[12] ? (~lft_torque+ 13'h001) : lft_torque[12:0]);

// Creates the final mux connection and determines the output for lft_shaped
assign mux_to_mux = (abs_lft_torque > LOW_TORQUE_BAND) ?  lft_torque_comp : ($signed(GAIN_MULT) * lft_torque);
assign lft_shaped = $signed(pwr_up ? mux_to_mux  : 13'h0000);
 
/***
Everything below is the same as above, but instead shifted to be for the right side.
*/

assign rght_torque_comp = $signed(rght_torque[12] ? (rght_torque - MIN_DUTY) : (rght_torque + MIN_DUTY));

assign abs_rght_torque = $signed(rght_torque[12] ? (~rght_torque + 13'h001) : rght_torque[12:0]);

assign mux_to_mux2 = (abs_rght_torque > LOW_TORQUE_BAND) ?  rght_torque_comp : ($signed(GAIN_MULT) * rght_torque) ;
assign rght_shaped = $signed(pwr_up ?  mux_to_mux2 :  13'h0000);

// Saturates both lft_shaped and rght_shaped to be 12 bit signed.
assign lft_spd = $signed((lft_shaped[12] && !lft_shaped [11]) ? 12'h800 : (!lft_shaped[12] && lft_shaped[11]) ? 12'h7FF : lft_shaped[11:0]);
assign rght_spd = $signed((rght_shaped[12] && !rght_shaped[11])? 12'h800 : (!rght_shaped[12] && rght_shaped[11]) ? 12'h7FF: rght_shaped[11:0]);

// Checks if either left or right are going too fast, if so, assigns bit value to send forward to too_fast.
assign too_fast_lft = ($signed(lft_spd) > $signed(12'd1792));
assign too_fast_rght = ($signed(rght_spd) > $signed(12'd1792));

// If either left or right are too fast, it's going too fast.
assign too_fast = (too_fast_lft | too_fast_rght);

endmodule



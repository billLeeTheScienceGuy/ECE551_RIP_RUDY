
module PID(pwr_up, rider_off, clk, rst_n, vld,ptch, ptch_rt, PID_cntrl, ss_tmr);

input pwr_up;
input rider_off;
input clk;
input rst_n;
input vld;
input [15:0]ptch;
input [15:0]ptch_rt;
output signed [11:0]PID_cntrl;
output signed [7:0]ss_tmr;

//Params
localparam signed P_COEFF = 5'h0C;
parameter fast_sim = 0;
localparam inc = fast_sim ? 256 : 1;

//Intermediate Signals
logic [26:0] timer;
logic signed [15:0]PID_cntrl_temp;
logic signed [14:0]P_term;
logic signed[9:0]ptch_err_sat;
logic signed [14:0]I_term;
logic signed [12:0]D_term;	
logic [17:0] integrator; 
logic signed [17:0] adder;
logic signed [17:0]ptch_err_sat_ext;
logic ov;

// Sign extends ptch_err_sat to add with integrator.
assign ptch_err_sat_ext = {{8{ptch_err_sat[9]}}, ptch_err_sat[9:0]};
assign adder = ptch_err_sat_ext[17:0] + integrator[17:0];

// Checks MSB of both operands and sees if they match, otherwise, it overflowed.
assign ov = (integrator[17] === ptch_err_sat_ext[17] && adder[17] !== integrator[17]) ? 1'b1: 1'b0;

// If there is no overflow, we add ptch_err_sat to integrator, otherwise we maintain 
// the previous value of integrator. If the rider is not on, we set integrator to 0.
always_ff@(posedge clk, negedge rst_n)begin
	if(!rst_n)
		integrator <= 0;
	else if(rider_off)
		integrator <= 18'h0;
	else if (vld && ~ov) 
		integrator <= adder;
end

// Increments timer until the upper bits begins to fill up, then, freeze the value.
// If power up is not enabled however, set timer to 0.
always_ff@(posedge clk, negedge rst_n) begin
	if(!rst_n)
		timer <= 27'h0;
	else if(!pwr_up)
		timer <= 27'h0;
	else if(&timer[26:8] == 1'b0) 
		timer <= timer + inc;
end

// Sets the upper bits of timer to ss_tmr.
assign ss_tmr = timer[26:19];

// ptch_err_sat is the 10-bit saturated version of the 16-bit ptch, 
// set to the maximum positive value if too high to represent or set to the most negative value if too negative to represent.
assign ptch_err_sat = (~ptch[15] & |ptch[14:9]) ? 10'h1FF : (ptch[15] & ~&ptch[14:9]) ? 10'h200 :
ptch[9:0];

// P_term is the 10-bit saturated ptch multiplied by the P_COEFF
assign P_term = $signed(ptch_err_sat)* $signed(P_COEFF);

// I_term is integrator divided by 64, so shifted 6 bits
generate if(fast_sim)
assign I_term = (~integrator[17] & |integrator[16:15]) ? 15'h3FFF : (integrator[17] & ~&integrator[16:15]) ? 15'h800 : integrator[15:1];
else
assign I_term =  {{3{integrator[17]}}, integrator[17:6]};
endgenerate

// D_term is ptch_rt divided by 64, so shifted 6 bits, and is then 1's complemented.
assign D_term = {{3{~ptch_rt[15]}}, ~ptch_rt[15:6]};

// Temp variable to use for saturation, currently is a 16-bit sum of P, I, D terms
assign PID_cntrl_temp = {{{3{D_term[12]}},D_term[12:0]} + {P_term[14],P_term[14:0]} + {I_term[14],I_term[14:0]}}; 

// Saturates PID_cntrl_temp to be a 12-bit value, set to the maximum positive value if too high to represent or set to the most negative value if too negative to represent.
assign PID_cntrl = (PID_cntrl_temp[15] & ~&PID_cntrl_temp[14:11]) ? 12'h800 :
			      (~PID_cntrl_temp[15] & |PID_cntrl_temp[14:11]) ? 12'h7FF : PID_cntrl_temp[11:0];
 
endmodule



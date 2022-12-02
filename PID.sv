module PID(clk, rst_n, vld, ptch, ptch_rt, pwr_up, rider_off, ss_tmr, PID_cntrl);

input clk;
input vld;
input rst_n;
input pwr_up;
input rider_off;
parameter FAST_SIM = 1;
input  [15:0] ptch;
input  [15:0] ptch_rt;
output [7:0] ss_tmr;
output [11:0] PID_cntrl;
//////////////////////////////////////////////////////
logic signed[17:0] integrator;						
localparam signed P_COEFF = 5'h0C;				//used in the calulation of P term
logic signed [9:0] ptch_err_sat;			//saturate value of ptch to 10 bits
//////// Internal Signals for Itegrator //////////
logic signed [17:0] ptch_err_sat_ext;
logic signed [17:0] sum_ptch_err_sat_ext_and_integrator;
logic ov;
logic vld_and_ov_n;
logic signed [17:0] rider_off_input_0;
logic signed [17:0] rider_off_output;
//////////Internal Signals for ss_tmr ////////////
logic [8:0] ss_tmr_inc;
logic [26:0] ss_tmr_27b;
//////////////////////////////////////////////////
logic signed [14:0]P_term;					
logic signed [14:0]I_term;
logic signed [12:0]D_term;
logic signed [15:0]PID_sum;					//sum of sign extend values of the P, I, D terms
logic signed [15:0]P_term_signExt;			//sign extended value of P term for PID_sum
logic signed [15:0]I_term_signExt;			//sign extended value of I term for PID_sum
logic signed [15:0]D_term_signExt;			//sign extended value of D term for PID_sum
////////////////////////////////////////////
assign ptch_err_sat = (ptch[15]) ? ((&ptch[14:9]) ? ptch[9:0] 	//saturate ptch to 10 bits
	: 10'h200) : ((|ptch[14:9]) ? 10'h1FF : ptch[9:0]);

///////// Itegrator Calculations ///////
assign ptch_err_sat_ext = {{9{ptch_err_sat[9]}},ptch_err_sat[8:0]};
assign sum_ptch_err_sat_ext_and_integrator = ptch_err_sat_ext [17:0] + integrator [17:0];

assign ov = (integrator[17] !== sum_ptch_err_sat_ext_and_integrator[17] && ptch_err_sat_ext[17]
	=== integrator[17]) ? (1'b1) : (1'b0);	//check overflow
	
always_ff @(posedge clk or negedge rst_n)begin
	if(!rst_n)
		integrator <= 18'h00000;
	else if(rider_off)
		integrator <= 18'h00000;
	else if(vld && ~ov)
		integrator <= sum_ptch_err_sat_ext_and_integrator;
end 

/////////////////// PID cntrl calulation//////////////////////////
assign P_term = $signed(ptch_err_sat) * $signed(P_COEFF);		//calculate P I D terms
generate if(FAST_SIM)begin
	assign ss_tmr_inc = 9'd256;
	assign I_term = (integrator[17] & ~&integrator[16:15]) ? 15'h8000
		: (~integrator[17] & |integrator[16:15] ? (15'h3FFF) : (integrator[15:1]));
	end
	else begin
		assign ss_tmr_inc = 9'd1;
		assign I_term = {{4{integrator[17]}},integrator[16:6]};
	end
endgenerate
		
assign D_term = {{4{~ptch_rt[15]}},~ptch_rt[14:6]};

assign P_term_signExt = {{2{P_term[14]}},P_term[13:0]};			//sign extened P I D terms for addition
assign I_term_signExt = {{2{I_term[14]}},I_term[13:0]};
assign D_term_signExt = {{4{D_term[12]}},D_term[11:0]};

assign PID_sum = D_term_signExt + I_term_signExt + P_term_signExt;

assign PID_cntrl = (PID_sum[15]) ? ((&PID_sum[14:11]) ? PID_sum[11:0] : 	//saturate PID_sum to 12 bits
	12'h800) : ((|PID_sum[14:11]) ? 12'h7FF : PID_sum[11:0]);

/////////////// Soft Start Timer ////////////
always_ff @(posedge clk or negedge rst_n) 
	if(!rst_n)
		ss_tmr_27b <= 27'h00000000;
	else if(~pwr_up)
		ss_tmr_27b <= 27'h00000000;
	else if(&ss_tmr_27b[26:8] == 1'b0)
		ss_tmr_27b <= ss_tmr_27b + ss_tmr_inc;
		
assign ss_tmr = ss_tmr_27b[26:19];

endmodule

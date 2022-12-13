//Team name: RIP Rudy
module inertial_integrator (clk, rst_n, vld, ptch_rt, AZ, ptch);

////// Inputs //////
input clk;					//clock
input rst_n;				//reset
input vld;					//high for a single clock cycle when new inertial readings are valid
input signed [15:0] ptch_rt;		//16-bit signed raw ptch rate from inertial sensor
input signed [15:0] AZ;			//will be used for sensor fusion (acceleration in Z direction)

////// Outputs //////
output logic signed [15:0] ptch;			//fully compensated and "fused" 16-bit signed pitch

////// COEFF //////
localparam signed PTCH_RT_OFFSET = 16'h0050;
logic signed [26:0] FUSION_PTCH_OFFSET;			//added into integration of ptch_int
localparam signed AZ_OFFSET = 16'h00A0;

////// Internal Signals //////
logic signed [26:0] ptch_int;					//pitch integrating accumulator 
logic signed [15:0] ptch_rt_comp;
logic signed [15:0] AZ_comp;
logic signed [25:0] ptch_acc_product;
logic signed [15:0] ptch_acc;

////// Code //////
assign ptch_rt_comp = $signed(ptch_rt) - $signed(PTCH_RT_OFFSET);

assign AZ_comp = $signed(AZ) - $signed(AZ_OFFSET);


always_comb begin
	ptch_acc_product = AZ_comp * $signed(377);		//327 is a fudge factor
	ptch_acc = {{3{ptch_acc_product[25]}},ptch_acc_product[25:13]};
	FUSION_PTCH_OFFSET = (ptch_acc > ptch) ? 1024 : $signed(-1024);
end

always_ff @(posedge clk, negedge rst_n) begin
	if(!rst_n)
		ptch_int <= 0;
	else if(vld)
		ptch_int <= (ptch_int - {{11{ptch_rt_comp[15]}}, ptch_rt_comp} + FUSION_PTCH_OFFSET);
end

assign ptch = ptch_int[26:11];			//fully compensated and "fused" 16-bit signed pitch

endmodule
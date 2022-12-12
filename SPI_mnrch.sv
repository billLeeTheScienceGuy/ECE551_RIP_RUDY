module SPI_mnrch(clk, rst_n, wt_data, wrt, rd_data, SS_n, SCLK, MOSI, MISO, done);

// Inputs 
input logic clk;				//50MHz system clk
input logic rst_n;				//50MHz reset
input logic [15:0] wt_data;		//data command begin sent to inertial sensor
input logic wrt;				//a high for 1 clock period would initiate a SPI transaction
input logic MISO;				// serial data out to monarch

// Outputs
output logic [15:0] rd_data;	//data from SPI serf, For inertial sensor we will only ever use [7:0]
output logic SS_n;				// active low serf select
output logic SCLK;				// Serial clock
output logic MOSI;				// serial data 
output logic done; 				//tells when done

//Intermediate Signals for SCLK
logic [3:0] SCLK_cnt;
logic SCLK_d;
logic init;

//Intermediate Signals for MOSI
logic [15:0] shft_reg;
logic smpl;
logic shft;
logic MISO_smpl;

//Intermediate Signals for done15
logic done15;
logic [3:0] bit_cntr;
logic set_done;

//Intermediate Signal to decrease timing
logic [15:0] rd_data_temp;
logic SCLK_temp;
logic MOSI_temp;

//States 
typedef enum reg [1:0] {IDLE, SKIP, START, BACK} state_t;
state_t state, nxt_state;

/////////////////////////////////////

// SCLK 
always_ff @(posedge clk)
	if (SCLK_d)
		SCLK_cnt <= 4'b1011;
	else
		SCLK_cnt <= SCLK_cnt + 4'h1;
		
assign SCLK_temp = SCLK_cnt[3];

always_ff @(posedge clk)
	SCLK <= SCLK_temp;

//MOSI
always_ff @(posedge clk) begin
	if(!rst_n)
		MISO_smpl <= 1'b0;
	if(smpl)
		MISO_smpl <= MISO;
end 

//shft_reg
always_ff @(posedge clk) begin
	if(init)
		shft_reg <= wt_data;
	else if(shft)
		shft_reg <= {shft_reg[14:0], MISO_smpl};
end
assign MOSI_temp = shft_reg[15];

always_ff @(posedge clk)
	MOSI <= MOSI_temp;

//done15
always_ff @(posedge clk) begin
	if(init)
		bit_cntr <= 4'h0;
	else if(shft)
		bit_cntr <= bit_cntr + 1'b1;
end
assign done15 = &bit_cntr;

//State Machine
always_ff @(posedge clk, negedge rst_n) begin
	if(!rst_n)
			state <= IDLE;
	else
		state <=nxt_state;
end

always_comb begin
	set_done = 1'b0;
	init = 1'b0;
	SCLK_d = 1'b0;
	shft = 1'b0;
	smpl = 1'b0;
	nxt_state = state;

	case(state)
		default: begin
			SCLK_d = 1'b1;
			if(wrt) begin
				init = 1'b1;
				nxt_state = SKIP;
			end
		end
		
		SKIP: if(SCLK_cnt == 4'hF) begin
				nxt_state = START;
			end
		
		START: begin 
			if(done15)begin
				nxt_state = BACK;
			end
			else if(SCLK_cnt == 4'h7)begin
				smpl = 1'b1;
			end
			else if(SCLK_cnt == 4'hF)begin
				shft = 1'b1;
			end
		end
		
		BACK: begin 
			if(SCLK_cnt == 4'hF) begin
				set_done = 1'b1;
				shft = 1'b1;
				SCLK_d = 1'b1;
				nxt_state = IDLE;
			end
			else if(SCLK_cnt == 4'h7) begin
				smpl = 1'b1;
			end
		end
	endcase		
end

//done
always_ff @(posedge clk, negedge rst_n) begin
	if(!rst_n)
		done <= 1'b0;
	else if(init)
		done <= 1'b0;
	else if(set_done)
		done <= 1'b1;	
end

//SS_n
always_ff @(posedge clk, negedge rst_n) begin
	if(!rst_n)
		SS_n <= 1'b1;
	else if(init)
		SS_n <= 1'b0;
	else if(set_done)
		SS_n <= 1'b1;	
end

assign rd_data_temp = shft_reg;

always_ff @(posedge clk)
	rd_data <= rd_data_temp;

endmodule
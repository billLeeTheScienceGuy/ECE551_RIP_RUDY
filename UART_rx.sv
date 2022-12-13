
module UART_rx(clk,rst_n,RX,clr_rdy,rx_data,rdy);

input clk, rst_n, RX, clr_rdy;		
output logic [7:0] rx_data;	
output logic rdy;	

typedef enum reg[1:0]{IDLE,RECEIVE} state_t;
state_t state, nxt_state;

logic start, receiving, shift, set_rdy, RX_temp, RX_temp2;
logic [8:0] rx_shft_reg;
localparam CLKS_PER_BIT = 12'hA2C;
logic [3:0]bit_cnt;
logic [11:0]baud_cnt, baud_cnt_start;

// Changes bit count based on the state machine.
// Possible outcomes: bit_cnt <= 0, bit_cnt maintains, bit_cnt++.
always_ff@(posedge clk, negedge rst_n) 
begin
	if(!rst_n)
		bit_cnt <= 4'h0;
	else if(start)
		bit_cnt <= 4'h0;
	else if(shift)
		bit_cnt <= bit_cnt + 1;
end

// Changes baud caunt based on the state machine.
// Possible outcomes: baud_cnt <= 0, baud_cnt maintains, baud_cnt++, 
// baud_cnt <= baud_cnt_start.
always_ff@(posedge clk, negedge rst_n) 
begin
	if(!rst_n)
		baud_cnt <= 12'h000;
	else if(start || shift) 
		baud_cnt <= baud_cnt_start;
	else if(receiving)
		baud_cnt <= baud_cnt + 1;
end
// Shifts register based on state machine.
// Possible outcomes: rx_shift_reg shifts 1 right, RX_temp2 is appended into
// rx_shift_reg, rx_shift_reg maintains.
always_ff@(posedge clk, negedge rst_n) 
begin
	if(!rst_n)
		rx_shft_reg <= 9'h1FF;
	else if(shift)
		rx_shft_reg <= {RX_temp2, rx_shft_reg[8:1]};
end

// Changes baud_cnt starting value.
always_comb begin
	if(start)
		baud_cnt_start = 12'h516;
	else
		baud_cnt_start = 12'h0;
end

// Metastabiltiy for RX
always_ff@(posedge clk, negedge rst_n) 
begin
	if(!rst_n) 
	begin
		RX_temp <= 1;
		RX_temp2 <= 1;
	end
	
	else 
	begin
		RX_temp <= RX;
		RX_temp2 <= RX_temp;
	end
	
end

// Sets up the state machine logic for receiving, also sets the next state logic
// and loads the defautl values.
always_comb begin
	set_rdy = 0;
	start = 0 ;
	receiving = 0;
	nxt_state = state;
	
	case(state)
		RECEIVE: if(bit_cnt == 4'd10) begin
			set_rdy = 1;
			nxt_state = IDLE;
		end
		else 
		begin 
			receiving = 1; 
		end
		
		default: if(!RX_temp2) begin
			start = 1;
			nxt_state = RECEIVE;
		end
	endcase
end

assign shift = (baud_cnt == CLKS_PER_BIT);
assign rx_data = rx_shft_reg[7:0];

always_ff @(posedge clk, negedge rst_n) 
begin
		if(!rst_n)
			state <= IDLE; 
		else
			state <= nxt_state; 
end

always_ff @(posedge clk, negedge rst_n) 
begin
		if(!rst_n)
			rdy <= 1'b0; 
		else if (start || clr_rdy)
			rdy <= 1'b0; 
		else if(set_rdy)
			rdy <= 1'b1;
end
endmodule


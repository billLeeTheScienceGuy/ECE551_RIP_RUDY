`timescale 1ns/1ps
module UART_tx(clk, rst_n, tx_data, trmt, tx_done, TX);

input clk, rst_n, trmt;
output logic TX, tx_done;
input logic [7:0]tx_data;
logic transmitting, load, shift, set_done, clr_done;

typedef enum reg{IDLE, TRANSMIT} state_t;
state_t state, nxt_state;
logic [3:0]bit_cnt;
logic [11:0]baud_cnt;
logic [8:0]tx_shift_reg;

// AKA Baud Rate
localparam CLKS_PER_BIT = 12'hA2C;

// Changes baud caunt based on the state machine.
// Possible outcomes: baud_cnt <= 0, baud_cnt maintains, baud_cnt++.
always_ff@(posedge clk, negedge rst_n) begin
	if(!rst_n)
		baud_cnt <= 12'h0;
	else if (load || shift) 
		baud_cnt <= 0;
	else if(transmitting) 
		baud_cnt <= baud_cnt + 1;
end
// Changes bit count based on the state machine.
// Possible outcomes: bit_cnt <= 0, bit_cnt maintains, bit_cnt++.
always_ff@(posedge clk, negedge rst_n) begin
	if(!rst_n)
		bit_cnt <= 4'h0; 
	else if (load)
		bit_cnt <= 4'h0;
	else if (shift) 
		bit_cnt <= bit_cnt + 1;
end
// Shifts register based on state machine.
// Possible outcomes: tx_shift_reg shifts 1 right, tx_data is appended with 1 bit into
// tx_shift_reg, tx_shift_reg maintains.
always_ff@(posedge clk, negedge rst_n) begin
	if(!rst_n)
		tx_shift_reg <= 9'h1FF;
	else if (load)
		tx_shift_reg <= {tx_data, 1'b0};
	else if (shift) 
		tx_shift_reg <= {1'b1, tx_shift_reg[8:1]};
end

//State machine state flop
always_ff@(posedge clk, negedge rst_n)
begin
	if(!rst_n)
		state <= IDLE;
	else
		state <= nxt_state;
end

// Sets up the state machine, starts by loading default values and logic for next state.
always_comb begin 
load = 0;
transmitting = 0;
set_done = 0;
clr_done = 0;
nxt_state = state;
	
	case(state)
		TRANSMIT: 
			if(bit_cnt == 4'd10) 
			begin
				set_done = 1;
				nxt_state = IDLE;
			end
			else 
			transmitting = 1;
		// This default state is IDLE.
		default: if(trmt)
			begin 
				load = 1;		
				clr_done = 1;
				nxt_state = TRANSMIT;
			end
	endcase
end 
// Makes sure there are no errors at the output.
always_ff @(posedge clk, negedge rst_n) begin
		if(!rst_n)
			tx_done <= 1'b0; 
		else if (clr_done)
			tx_done <= 1'b0; 
		else if(set_done)
			tx_done <= 1'b1;
	end

// Gets the LSB of the shift register.
assign TX = tx_shift_reg[0];	
// Makes sure shift only happens when baud_cnt is equal to our baud rate.
assign shift = (baud_cnt == CLKS_PER_BIT);


endmodule

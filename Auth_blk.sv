`timescale 1ns/1ps
module Auth_blk(clk, rst_n, RX, rider_off, pwr_up);

//inputs for Auth_blk
input clk;
input rst_n;
input RX;
input rider_off;

//output of Auth_blk
output logic pwr_up;

//intermediate signals for Auth_blk
logic rx_rdy;
logic clr_rx_rdy;
logic [7:0] rx_data;

//Declare UART_rx 
UART_rx rx(.clk(clk), .rst_n(rst_n), .RX(RX), .clr_rdy(clr_rx_rdy), .rx_data(rx_data), .rdy(rx_rdy));

//States for Auth_SM
typedef enum logic [1:0] {OFF, PWR1, PWR2} state_t;
state_t state, nxt_state;

//Go to next state
always_ff @(posedge clk, negedge rst_n) begin
	if(!rst_n)
		state <= OFF;
	else
		state <= nxt_state;
end

//State logics
always_comb begin
	pwr_up = 0;
	clr_rx_rdy = 0;
	nxt_state = state;
	
	case(state)
		
		default: if(rx_rdy && (rx_data == 8'h67)) begin
			pwr_up = 1;
			clr_rx_rdy = 1;
			nxt_state = PWR1;
		end
		
		PWR1: begin
			if(rx_rdy && (rx_data == 8'h73)) begin
				if(rider_off) begin
					clr_rx_rdy = 1;
					pwr_up = 0;
					nxt_state = OFF;
				end
				else begin
					pwr_up = 1;
					clr_rx_rdy = 1;
					nxt_state = PWR2;
				end
			end
			else
				pwr_up = 1;
		end
		
		PWR2: begin
			if (rider_off) begin
				pwr_up = 0;
				nxt_state = OFF;
			end
			else if(rx_rdy && (rx_data == 8'h67)) begin
				clr_rx_rdy = 1;
				pwr_up = 1;
				nxt_state = PWR1;
			end
			else
				pwr_up = 1;
		end
		
	endcase
end

endmodule
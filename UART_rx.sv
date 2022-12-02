module UART_rx(clk, rst_n, RX, clr_rdy , rx_data, rdy);
	
	input clk, rst_n, clr_rdy, RX;
	output [7:0] rx_data;
	output reg rdy;
	
	
	//meta stability RX
	logic RX1, RX2;
	always_ff @(posedge clk, negedge rst_n)begin
		if(!rst_n)begin
			RX1 <= 1;
			RX2 <= 1;
		end
		RX1 <= RX;
		RX2 <= RX1;
	end
	
	
	reg [8:0] rx_shift_reg;
	logic reciving, start;
	logic shift;
	logic set_rdy;
	typedef enum reg [1:0] {IDLE, START} state_t;
	state_t state, nxt_state;
	logic set_done;
	/*
	State machine
	*/
	always_ff @(posedge clk, negedge rst_n)begin
		if(!rst_n)
			state <= IDLE;
		else
			state <= nxt_state;
	end
	
	always_comb begin
		reciving = 0;
		set_rdy = 0; 
		start = 0;
		nxt_state = state;
		case(state)
			IDLE:if (!RX2)begin
				nxt_state = START;
				start = 1;
				reciving = 1;
			end
			default: if(set_done) begin   
				nxt_state = IDLE;
				start = 0;
				set_rdy = 1;
			end else begin
				
				reciving = 1;
			end
		endcase	
	end
	
	/*
	rdy signal
	*/
	always_ff @(posedge clk, negedge rst_n)begin
		if(!rst_n)
			rdy <= 0;
		else if(clr_rdy)
			rdy <= 0;
		else if(start)
			rdy <=0; 
		else if(set_rdy)
			rdy <=1;
		
	end 
	
	/*
	put into rx_data
	*/
	
	always_ff @(posedge clk)begin
		if(shift)
			rx_shift_reg <= {RX2 ,rx_shift_reg[8:1]};
		
	end
	assign rx_data = {rx_shift_reg[7:0]};
	
	reg [11:0] baud_cnt;
	
	/*
	counting down
	*/
	
	always_ff @(posedge clk)begin
		if(start)
			baud_cnt <= 12'd1302;
		else if(shift)		
			baud_cnt <= 12'd2604;
		
		else if(reciving)
			baud_cnt <= baud_cnt - 1'b1;
		
	end
	
	assign shift = (baud_cnt[11:0] === 12'd00000000000) ? 1'b1 : 1'b0;
	
	/*
	bit_cnt
	*/
	
	reg [3:0] bit_cnt;
	always_ff @(posedge clk)begin
		if(start)
			bit_cnt <= 3'b0;
		else if(shift)
			bit_cnt <= bit_cnt + 1'b1;
	end
	
	assign set_done = (bit_cnt[3:0] === 4'hA) ? 1'b1 : 1'b0;
		
	
	
	
	
endmodule
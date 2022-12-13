
module piezo_drv(batt_low, too_fast, en_steer, clk, rst_n, piezo, piezo_n);

//inputs and outputs
input logic clk;
input logic rst_n;
input logic batt_low;
input logic too_fast;
input logic en_steer;
output logic piezo;
output logic piezo_n;

//Intermediate Signals
logic reset_timer;
logic [24:0]note_duration;
logic [24:0]note_temp_duration;
logic [24:0]timer_duration;
logic [27:0]seconds;
logic [27:0]timer_seconds;
logic [14:0]note_frequency;
logic [14:0]note_temp_frequency;
logic [14:0]timer_frequency;
logic piezo_temp;
logic piezo_n_temp;

//FAST_SIM
parameter fast_sim = 0;

//States
typedef enum reg [2:0] {IDLE, G6, C7, E7, G7, E7_2, G7_2} state_t;
state_t state, nxt_state;

/////////////////////////////////////////////////
//////////            STATES           //////////
/////////////////////////////////////////////////
always_ff @(posedge clk, negedge rst_n)begin
    if(!rst_n)
        state <= IDLE;
    else
        state <= nxt_state;
end

always_comb begin
    reset_timer = 0;
    note_duration = 1;
    note_frequency = 0;
    nxt_state = state;
   
    case(state)
       
        G6:begin
                note_frequency = 15'd31888;
                note_duration = 25'h7FFFFF; 
            if(((too_fast || (en_steer && !batt_low))) && timer_duration == 0) begin
                nxt_state = C7;
                reset_timer = 1;
                note_frequency = 15'd18961;
                note_duration = 25'h7FFFFF; 
            end
            else if(batt_low && (timer_duration == 0)) begin
                nxt_state = IDLE;
            end
                else if(timer_duration == 0)
                nxt_state = IDLE;
            end

       
        C7:begin
                note_frequency = 15'd23890;
                note_duration = 25'h7FFFFF; 
            if(((too_fast || (en_steer && !batt_low))) && timer_duration == 0) begin
                nxt_state = E7;
                reset_timer = 1;
                note_frequency = 15'd18961;
                note_duration = 25'h7FFFFF; 
            end
            else if(batt_low && (timer_duration == 0)) begin
                note_duration = 25'h7FFFFF; 
                note_frequency = 15'd31888;
                reset_timer = 1;
                nxt_state = G6;
            end
                else if(timer_duration == 0)
					reset_timer = 1;
                nxt_state = IDLE;
            end
       
        E7:begin
                note_frequency = 15'd18961;
                note_duration = 25'h7FFFFF; 
            if(too_fast && (timer_duration == 0)) begin
                nxt_state = G6;
                reset_timer = 1;
                note_frequency = 15'd31888;
                note_duration = 25'h7FFFFF; 
            end
            else if(batt_low && (timer_duration == 0)) begin
                note_duration = 25'h7FFFFF; 
                note_frequency = 15'd23890;
                reset_timer = 1;
                nxt_state = C7;
            end
                else if(en_steer && timer_duration == 0) begin
                nxt_state = G7;
                note_duration = 25'h7FFFFF + 25'h3FFFFF;
                note_frequency = 15'd15944;
                end
                else if(timer_duration == 0)
                nxt_state = IDLE;
            end
       
        G7: begin
                note_frequency = 15'd15944;
					 note_duration = 25'h7FFFFF + 25'h3FFFFF;
            if(batt_low && (timer_duration == 0)) begin
                note_duration = 25'h7FFFFF;
                note_frequency = 15'd18961;
                reset_timer = 1;
                nxt_state = E7;
            end
            else if (en_steer && (timer_duration == 0))begin
                note_duration = 25'h3FFFFF;
                note_frequency = 15'd18961;
                nxt_state = E7_2;
            end
                else if(timer_duration == 0)
                nxt_state = IDLE;
            end
       
        E7_2: begin
                note_frequency = 15'd18961;
                note_duration = 25'h3FFFFF;
            if(batt_low && (timer_duration == 0)) begin
                note_duration[22] = 1'b1;
					 note_duration[21] = 1'b1;
                note_frequency = 15'd15944;
                reset_timer = 1;
                nxt_state = G7;
            end
            else if (en_steer && (timer_duration == 0))begin
                note_duration = 25'hFFFFFF;
                note_frequency = 15'd15944;
                nxt_state = G7_2;
                reset_timer = 1;
            end
                else if(timer_duration == 0)
                nxt_state = IDLE;
            end
       
        G7_2:begin
                note_frequency = 15'd15944;
                note_duration = 25'hFFFFFF;
            if(batt_low && (timer_duration == 0)) begin
                note_duration = 25'h3FFFFF;
                note_frequency = 15'd18961;
                reset_timer = 1;
                nxt_state = E7_2;
            end
            else if (en_steer && (timer_duration == 0))begin
                reset_timer = 1;
                nxt_state = IDLE;
            end
                else if(timer_duration == 0)
                nxt_state = IDLE;
            end
			default: begin          //IDLE State
            if(too_fast) begin 
                reset_timer = 1;
                note_frequency = 15'd31888;
                note_duration = 25'h7FFFFF;
                nxt_state = G6;
            end
            else if(batt_low && (timer_seconds == 0)) begin
                reset_timer = 1;
                note_duration = 25'h1FFFFF;
                note_frequency = 15'd15944;
                nxt_state = G7_2;
            end
            else if(en_steer && (timer_seconds == 0)) begin
                note_duration = 25'h7FFFFF;
                note_frequency = 15'd31888;
                reset_timer = 1;
                nxt_state = G6;
            end
        end
       
    endcase
end

/////////////////////////////////////////////////
//////////       Counters/Timers       //////////
/////////////////////////////////////////////////

generate 
    if(fast_sim) begin
        assign note_temp_duration = note_duration / 512;
        assign note_temp_frequency = note_frequency / 512;
        assign seconds = 28'd5000;
end
    else begin
		  assign note_temp_duration = note_duration;
		  assign note_temp_frequency = note_frequency;
        assign seconds = 28'd150000000;
		  end
endgenerate

always_ff@(posedge clk)
    if(reset_timer)
        timer_duration <= note_temp_duration;
	 else if(timer_duration == 0)
		 timer_duration <= note_temp_duration;
    else 
        timer_duration <= timer_duration - 1'b1;

always_ff@(posedge clk)
    if(reset_timer)
        timer_frequency <= note_temp_frequency;
    else if(timer_frequency == 0)
        timer_frequency <= note_temp_frequency;
    else
        timer_frequency <= timer_frequency - 1'b1;
always_ff @(posedge clk, negedge rst_n)
    if(!rst_n)
        timer_seconds <= seconds;
    else if(timer_seconds == 0)
        timer_seconds <= seconds;
    else 
        timer_seconds <= timer_seconds - 1'b1;

//Temp values for Improving Timing
assign piezo = (timer_frequency >= {1'b0, note_temp_frequency[14:1]});
assign piezo_n_temp = ~piezo;

endmodule
`timescale 1ns/1ps
module steer_en_SM(clk,rst_n,tmr_full,sum_gt_min,sum_lt_min,diff_gt_1_4,
                   diff_gt_15_16,clr_tmr,en_steer,rider_off);

  input logic clk;				// 50MHz clock
  input logic rst_n;				// Active low asynch reset
  input logic tmr_full;			// asserted when timer reaches 1.3 sec
  input logic sum_gt_min;			// asserted when left and right load cells together exceed min rider weight
  input logic sum_lt_min;			// asserted when left_and right load cells are less than min_rider_weight

  /////////////////////////////////////////////////////////////////////////////
  // HEY HOFFMAN...you are a moron.  sum_gt_min would simply be ~sum_lt_min. 
  // Why have both signals coming to this unit??  ANSWER: What if we had a rider
  // (a child) who's weigth was right at the threshold of MIN_RIDER_WEIGHT?
  // We would enable steering and then disable steering then enable it again,
  // ...  We would make that child crash(children are light and flexible and 
  // resilient so we don't care about them, but it might damage our Segway).
  // We can solve this issue by adding hysteresis.  So sum_gt_min is asserted
  // when the sum of the load cells exceeds MIN_RIDER_WEIGHT + HYSTERESIS and
  // sum_lt_min is asserted when the sum of the load cells is less than
  // MIN_RIDER_WEIGHT - HYSTERESIS.  Now we have noise rejection for a rider
  // who's weight is right at the threshold.  This hysteresis trick is as old
  // as the hills, but very handy...remember it.
  //////////////////////////////////////////////////////////////////////////// 

  input logic diff_gt_1_4;		// asserted if load cell difference exceeds 1/4 sum (rider not situated)
  input logic diff_gt_15_16;		// asserted if load cell difference is great (rider stepping off)
  output logic clr_tmr;		// clears the 1.3sec timer
  output logic en_steer;	// enables steering (goes to balance_cntrl)
  output logic rider_off;	// held high in initial state when waiting for sum_gt_min
  
  logic rider_off_temp;
  logic en_steer_temp;

  // You fill out the rest...use good SM coding practices ///
  typedef enum logic [1:0]{IDLE, WAITING, STEERING} state_t;
  state_t state, nxt_state;

  always_ff@(posedge clk, negedge rst_n) begin
    if(!rst_n)
    state <= IDLE;
    else
    state <= nxt_state;
  end

  always_comb begin
    clr_tmr = 0;
    en_steer_temp = 0;
    rider_off_temp = 1;
    nxt_state = state;

    case(state)
      WAITING: if(sum_lt_min) begin
        rider_off_temp = 1;
        nxt_state = IDLE;
      end
      else if (diff_gt_1_4) begin
        clr_tmr= 1;
        rider_off_temp = 0;
      end
      else if (tmr_full) begin
        nxt_state = STEERING;
        rider_off_temp = 0;
        en_steer_temp = 1;
      end
      else begin 
        rider_off_temp = 0;
      end 
      STEERING: 
      if(sum_lt_min) begin
        rider_off_temp = 1;
        nxt_state = IDLE;
      end
      else if(diff_gt_15_16) begin
        clr_tmr = 1;
        rider_off_temp = 0;
        nxt_state = WAITING;
      end
      else begin 
        en_steer_temp = 1; 
        rider_off_temp = 0;
      end 
      // Default state is IDLE or "INITIAL"
      IDLE: 
      if(sum_gt_min) begin
        rider_off_temp = 0;
        clr_tmr = 1;
        nxt_state = WAITING;
      end
      default :
      nxt_state = IDLE;
    endcase
  end
  
always_ff @(posedge clk)
  rider_off <= rider_off_temp;

always_ff @(posedge clk)
  en_steer <= en_steer_temp;
  
endmodule
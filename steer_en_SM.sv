module steer_en_SM(clk,rst_n,tmr_full,sum_gt_min,sum_lt_min,diff_gt_1_4,
                   diff_gt_15_16,clr_tmr,en_steer,rider_off);

  input clk;				// 50MHz clock
  input rst_n;				// Active low asynch reset
  input tmr_full;			// asserted when timer reaches 1.3 sec
  input sum_gt_min;			// asserted when left and right load cells together exceed min rider weight
  input sum_lt_min;			// asserted when left_and right load cells are less than min_rider_weight

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

  input diff_gt_1_4;		// asserted if load cell difference exceeds 1/4 sum (rider not situated)
  input diff_gt_15_16;		// asserted if load cell difference is great (rider stepping off)
  output logic clr_tmr;		// clears the 1.3sec timer
  output logic en_steer;	// enables steering (goes to balance_cntrl)
  output logic rider_off;	// held high in intitial state when waiting for sum_gt_min
  
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
    en_steer = 0;
    rider_off = 0;
    nxt_state = state;

    case(state)
      WAITING: if(diff_gt_1_4) begin
        clr_tmr = 1;
      end
      else if (tmr_full & !diff_gt_1_4) begin
        en_steer = 1;
        nxt_state = STEERING;
      end
      else if (sum_lt_min) begin
        rider_off = 1;
        nxt_state = IDLE;
      end
      STEERING: if(~diff_gt_15_16 && ~sum_lt_min)
        en_steer = 1;
      else if(sum_lt_min) begin
        rider_off = 1;
        nxt_state = IDLE;
      end
      else if(diff_gt_15_16) 
        clr_tmr = 1;
      // Default state is IDLE or "INITIAL"
      default: 
      if(~sum_gt_min) 
        rider_off = 1;
      else if (sum_gt_min) begin
        clr_tmr = 1;
        nxt_state = WAITING;
      end
      


    endcase
  end
  
  
endmodule
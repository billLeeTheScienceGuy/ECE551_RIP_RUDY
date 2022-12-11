`timescale 1ns/1ps
module A2D_intf(clk, rst_n, nxt, lft_ld, rght_ld, steer_pot, batt, SS_n, SCLK, MOSI, MISO);

input clk, rst_n, nxt, MISO;
output SS_n, SCLK, MOSI;
logic wrt, update, en_r, en_l, en_batt, en_steer, done;
logic [15:0] rd_data, wt_data;
logic [2:0] channel;
output logic [11:0] lft_ld, rght_ld, batt, steer_pot;
logic [1:0] round_count;
typedef enum reg [2:0] {IDLE, SEND1, WAIT, SEND2} state_t;
state_t state, nxt_state;
SPI_mnrch SPI(.clk(clk), .rst_n(rst_n), .wrt(wrt), .wt_data(wt_data),. MISO(MISO), .rd_data(rd_data), .MOSI(MOSI), .done(done),.SS_n(SS_n),.SCLK(SCLK));
// Round Robin Counter
always@(posedge clk, negedge rst_n)
    if(!rst_n)
        round_count <= 2'b0;
    else if(update)
        round_count++;
assign en_l = round_count == 2'b00;
assign en_r = round_count == 2'b01;
assign en_steer = round_count == 2'b10;
assign en_batt = round_count == 2'b11;
assign channel = en_l ? 3'b0 : en_r ? 3'b100 : en_steer ? 3'b101 : 3'b110;
always_ff@(posedge clk, negedge rst_n)
    if(!rst_n)
        state <= IDLE;
    else
        state <= nxt_state;
always_ff@(posedge clk, negedge rst_n)
    if(!rst_n)
        batt <= 12'h0;
    else if(en_batt && update)
        batt <= rd_data[11:0];
always_ff@(posedge clk, negedge rst_n)
    if (!rst_n)
        rght_ld <= 12'h0;
    else if (en_r && update)
        rght_ld <= rd_data[11:0];
always_ff@(posedge clk, negedge rst_n)
    if (!rst_n)
        lft_ld <= 12'h0;
    else if (en_l && update)
        lft_ld <= rd_data[11:0];
always_ff@(posedge clk, negedge rst_n)
    if (!rst_n)
        steer_pot <= 12'h0;
    else if (en_steer && update)
        steer_pot <= rd_data[11:0];
always_comb begin
    wrt = 0;
    update = 0;
    nxt_state = state;
    case(state)
    IDLE: if(nxt) begin 
        wrt = 1;
        update = 0;
        nxt_state = SEND1;
    end
    SEND1: if (done) begin 
        nxt_state = WAIT;
        end
    WAIT: begin
      wrt = 1;
      nxt_state = SEND2;
    end
    SEND2: if(done) begin
        update = 1;
        nxt_state = IDLE;
    end
 
    endcase
end
assign wt_data = {2'b00,channel[2:0],11'h000};
endmodule
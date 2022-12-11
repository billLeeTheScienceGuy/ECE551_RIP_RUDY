`default_nettype none
`timescale 1ns/1ps
module A2D_intf_tb();

logic clk, rst_n, nxt, MISO;
logic [11:0]lft_ld, rght_ld, batt, steer_pot;
logic SCLK, MOSI, a2d_SS_n;


A2D_intf A2D(.clk(clk),.rst_n(rst_n), .nxt(nxt), .lft_ld(lft_ld), .rght_ld(rght_ld),
.steer_pot(steer_pot),.batt(batt),.SS_n(a2d_SS_n),.SCLK(SCLK),.MOSI(MOSI),.MISO(MISO));

ADC128S ADC(.clk(clk),.rst_n(rst_n),.MISO(MISO),.MOSI(MOSI),.SS_n(a2d_SS_n),.SCLK(SCLK));

initial begin 
    clk = 1'b0;
    rst_n = 1'b0;
    nxt = 1'b0;
    @(negedge clk);
    rst_n = 1'b1;
    @(posedge clk);
    nxt = 1'b1;

    @(posedge clk);
    nxt = 1'b0;


    fork
        begin : timeout1
            repeat(3000)@(posedge clk);
            $display("Yahtzee! Test failed, timed out while waiting for conversion");
            $stop;
        end
        begin @(posedge A2D.done);
            disable timeout1;
        end
    join
    @(A2D.state == 2'b00);
    if(lft_ld !== 12'hC00) begin
        $display("Yahtzee! Test failed, expected value for left_ld was not found.");
        $stop;
    end
    $display("Yahoo! Left_ld test passed!");
    @(posedge clk);
    nxt = 1'b1;

    @(posedge clk);
    nxt = 1'b0;
	fork
        begin : timeout2
            repeat(3000)@(posedge clk);
            $display("Yahtzee! Test failed, timed out while waiting for conversion");
            $stop;
        end
        begin @(posedge A2D.done);
            disable timeout2;
        end
    join
    @(A2D.state == 2'b0);
    repeat(50)@(posedge clk);
    if(rght_ld !== 12'hBF4) begin
        $display("Yahtzee! Test failed, expected value for right_ld was not found.");
        $stop;
    end
    $display("Yahoo! Right_ld test passed!");
@(posedge clk);
nxt = 1'b1;

@(posedge clk);
nxt = 1'b0;
fork
    begin : timeout3
        repeat(3000)@(posedge clk);
        $display("Yahtzee! Test 2 failed, timed out while waiting for conversion");
        $stop;
    end
    begin @(posedge A2D.done);
        disable timeout3;
    end
join
@(A2D.state == 2'b0);
repeat(50)@(posedge clk);
if(steer_pot !== 12'hBE5) begin
    $display("Yahtzee! Test 3 failed, expected value for right_ld was not found.");
    $stop;
end
$display("Yahoo! steer_pot test passed!");
@(posedge clk);
nxt = 1'b1;
@(posedge clk);
nxt = 1'b0;
fork
    begin : timeout4
        repeat(3000)@(posedge clk);
        $display("Yahtzee! Test 4 failed, timed out while waiting for conversion");
        $stop;
    end
    begin @(posedge A2D.done);
        disable timeout4;
    end
join
@(A2D.state == 2'b0);
repeat(50)@(posedge clk);
if(batt !== 12'hBD6) begin
    $display("Yahtzee! Test failed, expected value for batt was not found.");
    $stop;
end
$display("Yahoo! batt test passed!");
$display("All tests passed!! Yay");
$stop;
end
always #5 clk = ~clk;

endmodule
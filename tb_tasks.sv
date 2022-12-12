`timescale 1ns/1ps
  

task init;
    clk = 0;
    RST_n = 0;
    rider_lean = 0;
    cmd = 8'h0;
    send_cmd = 0;
    ld_cell_lft = 0;
    ld_cell_rght = 0;
    batt = 0;
    steerPot = 0;
    OVR_I_lft = 0;
    OVR_I_rght = 0;
    repeat(2)@(negedge clk);
    RST_n = 1;
    $display("We gon check for the inertial sensor to be initialized.");
    wait(iDUT.iNEMO.state === 3'b110);
    $display("Initialized! Lets ya some hoos.");
   
endtask 

task riderOn_noGo;
    $display("Running test riderOn_noGo");
    assert(iDUT.pwr_up === 0);
    $display("Yahoo! riderOn_noGo Test passed!!!");
endtask 

task riderOn_go;
    send_command(8'h67, clk, send_cmd , cmd_sent, cmd);
    $display("Running test riderOn_go");
    assert(iDUT.pwr_up === 1);
    $display("Yahoo! riderOn_go Test passed!!!");
endtask

task riderLeaning;
    $display("Running test riderLeaning");
    rider_lean = $signed(16'h1F00);
    repeat(10000)@(negedge clk);
    assert(iPHYS.net_torque === $signed(16'h1F00));
    $display("Yahoo! riderLeaning Test passed!!!");
endtask

task segwayShutdown;
    send_command(8'h73, clk, send_cmd, cmd_sent, cmd);
    repeat(10000)@(posedge clk);
    if(!iDUT.pwr_up  && !iDUT.rider_off) begin
		$display("ERROR: pwr_up should be 1 when rider_off is 0");
		$stop;
	end
	else if(iDUT.pwr_up && iDUT.rider_off) begin
		$display("ERROR: pwr_up should be 0 when rider_off is 1");
		$stop;
    end
    $display("Yahoo! segwayShutdown Test passed!!!");

endtask


task chargeYourSegway;
    $display("Running test chargeYourSegway");
    batt = batt - 12'h500;
    repeat(30000)@(posedge clk);
    assert (iDUT.batt_low === 1);
    $display("Yahoo! chargeYourSegway Test passed!!!");
endtask 

task slowDown;
    $display("Running test slowDown");
    rider_lean = $signed(16'h0);
    repeat(300000) @(posedge clk) begin
    #5;
    rider_lean += 8'h50;
    end
    @(posedge iDUT.too_fast);
    assert (iDUT.too_fast === 1);
    $display("Yahoo! slowDown Test Passed !!!");
endtask

task areYaSteering;
    $display("Running test areYaSteering");
    @(posedge iDUT.en_steer);
    assert (iDUT.en_steer === 1);
    $display("Yahoo! areYaSteering Test Passed !!!");
endtask

task automatic send_command(input [7:0]command, ref clk, send_cmd , cmd_sent, ref [7:0] cmd);
    @(negedge clk);
    cmd = command;
    send_cmd = 1'b1;
    @(negedge clk);
    send_cmd = 1'b0;
    @(posedge cmd_sent);
    $display("Command successfully sent");
    repeat(2)@(negedge clk);
endtask


task DUT_reset;
  RST_n = 0;
  @(posedge clk);
  @(negedge clk);
  RST_n = 1;
  @(posedge clk);
endtask

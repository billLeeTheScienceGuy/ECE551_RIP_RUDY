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
    @(negedge clk);
    RST_n = 1;
    repeat(2)@(negedge clk);
endtask 

task riderOn_noGo;
    $display("Running test riderOn_noGo");
    assert(iDUT.pwr_up === 0);
    $display("Yahoo! riderOn_noGo Test passed!!!");
endtask 

task riderOn_go;
    send_command(8'h67, clk, send_cmd , cmd_sent, cmd);
    repeat(300000)@(posedge clk);
    repeat(10)@(posedge iDUT.iNEMO.wrt);
    $display("Running test riderOn_go");
    assert(iDUT.pwr_up === 1);
    $display("Yahoo! riderOn_go Test passed!!!");
endtask

task riderLeaning;
    $display("Running test riderLeaning");
    rider_lean = $signed(16'h1FFF);
    assert(iPHYS.net_torque === 16'h1FFF);
    $display("Yahoo! riderLeaning Test passed!!!");
endtask

task chargeYourSegway;
    $display("Running test chargeYourSegway");
    DUT_reset;
    batt = batt - 12'h500;
    iA2D.iSPI.shft_reg_rx = batt;
    repeat(10)@(posedge clk);
    iA2D.iSPI.SCLK_ff1 = 1;
    iA2D.iSPI.SCLK_ff2 = 0;
    assert (iDUT.iBUZZ.batt_low === 1);
    $display("Yahoo! chargeYourSegway Test passed!!!");
endtask

task automatic waitForSignal (ref signal, clk, input int clocks);
    fork
        begin : timeout 
            repeat(clocks) @(posedge clk);
            $display("Timed out whilst waiting for signal");
            $stop();
        end
        begin @(posedge signal);
            disable timeout;
        end
    join
endtask

task automatic send_command(input [7:0]command, ref clk, send_cmd , cmd_sent, ref [7:0] cmd);
    @(negedge clk);
    send_cmd = 1'b1;
    cmd = command;
    @(negedge clk);
    send_cmd = 1'b0;
    @(posedge iDUT.iAuth.rx.rdy);
    @(posedge cmd_sent);
    $display("Command successfully sent");
    @(negedge clk);
endtask

task send_s;
    cmd = 8'h73;
    send_cmd = 1;
    @(negedge iDUT.clk);
    send_cmd = 0;
    @(cmd_sent);
    repeat(2)@(negedge iDUT.clk);
endtask

task DUT_reset;
  RST_n = 0;
  @(posedge clk);
  @(negedge clk);
  RST_n = 1;
  @(posedge clk);
endtask




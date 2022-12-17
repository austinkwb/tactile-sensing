`timescale 1ns / 1ps
`default_nettype none

module buffer_tb;
  logic clk;
  logic rst;

  logic [3:0] test_case;
  logic [10:0] hcount_in, hcount_out;
  logic [9:0] vcount_in, vcount_out;
  logic data_valid_in, data_valid_out;
  logic [15:0] data_in;
  logic [2:0][15:0] data_out; //make this 2D packed

  /* A quick note about this simulation! Most waveform viewers
   * (including GTKWave) don't display arrays in their output
   * unless the array is packed along all dimensions. This is
   * to prevent the amount of data GTKWave has to render from 
   * getting too large, but it also means you'll have to use
   * $display statements to read out from your arrays.
  */

  buffer #(
    .SW_WIRE_CNT('d16),
    .RD_WIRE_CNT('d16)
  ) uut (
    .clk_in(clk),
    .rst_in(rst),
    .hcount_in(hcount_in),
    .vcount_in(vcount_in),
    .data_in(data_in),
    .data_valid_in(data_valid_in),

    .data_out(data_out),
    .hcount_out(hcount_out),
    .vcount_out(vcount_out),
    .data_valid_out(data_valid_out));

  always begin
    #5;
    clk = !clk;
  end

  initial begin
    $dumpfile("buffer.vcd");
    $dumpvars(0, buffer_tb);
    $display("Starting Sim");
    test_case = 0;
    clk = 0;
    rst = 0;
    #10;
    rst = 1;
    #10;
    rst = 0;

    //240x320 

    
    //case 1: hcount and vcount are delayed by 2
    hcount_in = 11'b0;
    vcount_in = 10'b0;
    data_in = 12'b0;
    data_valid_in = 1'b0;

    
    test_case = 1; 
    #10;
    for (int i_vcount = 0; i_vcount<4; i_vcount= i_vcount+1) begin
      for (int i_hcount = 0; i_hcount<5; i_hcount= i_hcount+1) begin
        data_valid_in = 1'b1;
        vcount_in = i_vcount;
        hcount_in = i_hcount;
        data_in = 0;
        #10;
      end
    end
    data_valid_in = 1'b0;

    #50;
    rst = 1;
    #10;
    rst = 0;

    //case 2: no valid input
    test_case = 2; 
    #10;
    for (int i_vcount = 0; i_vcount<6; i_vcount= i_vcount+1) begin
      for (int i_hcount = 0; i_hcount<5; i_hcount= i_hcount+1) begin
        data_valid_in = 1'b0;
        vcount_in = i_vcount;
        hcount_in = i_hcount;
        data_in = i_vcount + i_hcount;
        #10;
      end
    end
    data_valid_in = 1'b0;

    #50;
    rst = 1;
    #10;
    rst = 0;

    
    //case 3: output is properly delayed with input
    test_case = 3; 
    #10;
    for (int i_vcount = 0; i_vcount<6; i_vcount= i_vcount+1) begin
      for (int i_hcount = 0; i_hcount<5; i_hcount= i_hcount+1) begin
        data_valid_in = 1'b1;
        vcount_in = i_vcount;
        hcount_in = i_hcount;
        data_in = (i_hcount == 1 && vcount_in == 1) ? 1 : 0;
        #10;
      end
    end
    data_valid_in = 1'b0;
    
    rst = 1;
    #10;
    rst = 0;
    #10;

    #100

    //case 4: test hcount delay
    test_case = 4; 
    for (int i_vcount = 0; i_vcount<5; i_vcount= i_vcount+1) begin
      for (int i_hcount = 0; i_hcount<6; i_hcount= i_hcount+1) begin
        data_valid_in = 1'b1;
        vcount_in = i_vcount;
        hcount_in = i_hcount;
        data_in = vcount_in;
        #10;
      end
    end
    data_valid_in = 1'b0;
    
    rst = 1;
    #10;
    rst = 0;
    #10;
    test_case = 5; //reset
    for (int i_vcount = 0; i_vcount<5; i_vcount= i_vcount+1) begin
      for (int i_hcount = 0; i_hcount<6; i_hcount= i_hcount+1) begin
        data_valid_in = 1'b1;
        vcount_in = i_vcount;
        hcount_in = i_hcount;
        data_in = 0;
        #10;
      end
    end
    data_valid_in = 1'b0;
    #100
    rst = 1;
    #10;
    rst = 0;
    #10;

    //case 6: full image case
    test_case = 6; 
    for (int i_vcount = 0; i_vcount<'d16; i_vcount= i_vcount+1) begin
      for (int i_hcount = 0; i_hcount<'d16; i_hcount= i_hcount+1) begin
        data_valid_in = 1'b1;
        vcount_in = i_vcount;
        hcount_in = i_hcount;
        data_in = {i_vcount[8:0], i_hcount[8:0]};
        #10;
      end
    end
    data_valid_in = 1'b0;

    $display("Finishing Sim");
    $finish;
  end
endmodule //buffer_tb

`default_nettype wire

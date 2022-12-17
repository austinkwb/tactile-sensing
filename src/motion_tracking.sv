`timescale 1ns / 1ps
`default_nettype none

//TODO:Consider adding adjaceny checking???

module motion_tracking #(
  parameter SW_WIRE_CNT = 'd16,
  parameter RD_WIRE_CNT = 'd16,
  parameter CYCLE_TIMEOUT = 'd16250000 //.25 timeout
  )(
  input wire clk,
  input wire rst,
  input wire [10:0] hcount_in,
  input wire [9:0] vcount_in,
  input wire [10:0] x_com,
  input wire [9:0] y_com,
  input wire [1:0] scale_in,

  output logic blue
  );

  reg [$clog2(CYCLE_TIMEOUT)-'d1:0] timeout_cnt;
  reg[$clog2(SW_WIRE_CNT*RD_WIRE_CNT):0] blue_cnt;
  
  reg [9:0] sw_wires, y_wires;
  reg [10:0] rd_wires, x_wires;
  reg [SW_WIRE_CNT - 'd1:0][RD_WIRE_CNT - 'd1:0] blue_toggle;
  reg live;
  assign live = blue_cnt >= 'd3;
  always_comb begin
    //assuming valid bc all invalid are black pixels
    if(scale_in == 2'b0) begin
      rd_wires = hcount_in;
      sw_wires = vcount_in;

      y_wires = y_com;
      x_wires = x_com;
    end else if (scale_in == 2'b01) begin
      rd_wires = hcount_in >> $clog2('d16);
      sw_wires = vcount_in >> $clog2('d16);

      y_wires = y_com >> $clog2('d16);
      x_wires = x_com >> $clog2('d16);
    end else if (scale_in == 2'b10) begin
      rd_wires = hcount_in >> $clog2('d32);
      sw_wires = vcount_in >> $clog2('d32);

      y_wires = y_com >> $clog2('d32);
      x_wires = x_com >> $clog2('d32);
    end else begin
      rd_wires = hcount_in >> $clog2('d64);
      sw_wires = vcount_in >> $clog2('d64);

      y_wires = y_com >> $clog2('d64);
      x_wires = x_com >> $clog2('d64);
    end

    if(sw_wires < SW_WIRE_CNT && rd_wires < RD_WIRE_CNT && live) begin
      blue = blue_toggle[sw_wires][rd_wires];
    end else begin
      blue = 0;
    end
  end

  always@(posedge clk) begin
    if(rst) begin
      timeout_cnt <= 0;
      blue_cnt <= 0;
      blue_toggle <= 0;
    end else begin
      if(sw_wires == y_wires && rd_wires == x_wires && !blue_toggle[sw_wires][rd_wires]) begin
        blue_toggle[sw_wires][rd_wires] <= 'b1;
        blue_cnt <= blue_cnt +'d1;
        timeout_cnt <= 0;
      end else begin
        if(timeout_cnt == CYCLE_TIMEOUT) begin
          blue_toggle <= 0;
          timeout_cnt <= 0;
          blue_cnt <= 0;
        end else begin
          timeout_cnt <= timeout_cnt + 'd1;
        end
      end
    end
  end

endmodule

`default_nettype wire
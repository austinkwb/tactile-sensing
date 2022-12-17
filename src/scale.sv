`timescale 1ns / 1ps
`default_nettype none

module scale #(
  parameter SW_WIRE_CNT = 'd16,
  parameter RD_WIRE_CNT = 'd16
  )(
  input wire [1:0] scale_in,
  input wire [10:0] hcount_in,
  input wire [9:0] vcount_in,
  input wire [11:0] data_in,
  output logic [11:0] data_out
);

  always_comb begin
    if (scale_in == 2'b00) begin
      if (hcount_in < SW_WIRE_CNT && vcount_in < RD_WIRE_CNT) data_out = data_in;
      else data_out = 16'h0000;
    end else if (scale_in == 2'b01) begin
      if (hcount_in < (SW_WIRE_CNT*'d16) && vcount_in < (RD_WIRE_CNT*'d16)) data_out = data_in;
      else data_out = 16'h0000;
    end else if (scale_in == 2'b10) begin
      if (hcount_in < (SW_WIRE_CNT*'d32) && vcount_in < (RD_WIRE_CNT*'d32)) data_out = data_in;
      else data_out = 16'h0000;
    end else begin
      if (hcount_in < (SW_WIRE_CNT*'d64) && vcount_in < (RD_WIRE_CNT*'d64)) data_out = data_in;
      else data_out = 16'h0000;
    end
  end

endmodule


`default_nettype wire

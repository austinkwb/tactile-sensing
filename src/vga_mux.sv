module vga_mux (
    input wire [11:0] data_in,
    input wire mask_on,
    input wire mask_in,
    input wire blue_in,
    input wire blue_on,
    input wire crosshair_on,
    input wire crosshair_in,
    output logic [11:0] data_out
);

  /*
  0: normal data out
  1: thresholded channel image b/w

  upper bits:
  0: nothing:
  1: crosshair
  */

  logic [11:0] l_1;
  always_comb begin
    case (mask_on)
      2'b0: l_1 = data_in;
      2'b1: l_1 = mask_in?data_in:12'h000;
    endcase
  end

  logic [11:0] l_2;
  always_comb begin
    case (blue_on)
      2'b0: l_2 = l_1;
      2'b1: l_2 = blue_in? 12'h00F:l_1;
    endcase
  end

  logic [11:0] l_3;
  always_comb begin
    case (crosshair_on)
      2'b0: l_3 = l_2;
      2'b1: l_3 = crosshair_in ? 12'h0F0:l_2;
    endcase
  end
  assign data_out = l_3;
endmodule

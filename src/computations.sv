`timescale 1ns / 1ps
`default_nettype none

module computation #(
    parameter SW_WIRE_CNT = 'd16,
    parameter RD_WIRE_CNT = 'd16
) (
    input wire clk,
    input wire rst,
    input wire [2:0] k_select,
    input wire [11:0] in_bram_data,

    output wire [$clog2(SW_WIRE_CNT*RD_WIRE_CNT)-1:0] in_bram_addr,
    output wire [11:0] out_bram_data,
    output wire [$clog2(SW_WIRE_CNT):0] sw_wires,
    output wire [$clog2(RD_WIRE_CNT):0] rd_wires
);

    logic [5:0][7:0] shift;
    logic [5:0][2:0][2:0][7:0] coeffs;

  generate
    genvar i;
    for (i=0; i<6; i=i+1)begin
        kernels #(.K_SELECT(i)) kernel (
            .rst_in(rst),

            .coeffs(coeffs[i]),
            .shift(shift[i])
        );
    end
  endgenerate

  convolution #(
    .SW_WIRE_CNT(SW_WIRE_CNT),
    .RD_WIRE_CNT(RD_WIRE_CNT)
    ) conv(
        .clk(clk),
        .rst(rst),
        .data_in(in_bram_data),
        .coeffs(k_select > 5 ? coeffs[0] : coeffs[k_select]),
        .shift(k_select > 5 ? shift[0] : shift[k_select]),

        .bram_addr(in_bram_addr),
        .sw_wires(sw_wires),
        .rd_wires(rd_wires),
        .data_out(out_bram_data)
      );

endmodule

`default_nettype wire

`timescale 1ns / 1ps
`default_nettype none

module convolution #(
    parameter SW_WIRE_CNT = 'd16,
    parameter RD_WIRE_CNT = 'd16
) (
    input wire clk,
    input wire rst,
    input wire [11:0] data_in,
    input wire [7:0] shift,
    input wire [2:0][2:0][7:0] coeffs,

    output wire [$clog2(SW_WIRE_CNT*RD_WIRE_CNT)-1:0] bram_addr,
    output wire [$clog2(SW_WIRE_CNT):0] sw_wires,
    output wire [$clog2(RD_WIRE_CNT):0] rd_wires,
    output wire [11:0] data_out
);

reg [RD_WIRE_CNT-'d1:0][11:0] rd_cache0, rd_cache1, rd_cache2;
reg [$clog2(SW_WIRE_CNT):0] sw_cnt, prev_sw_cnt, prev_sw_cnt1, prev_sw_cnt2, prev_sw_cnt3, prev_sw_cnt4;
reg [$clog2(RD_WIRE_CNT):0] rd_cnt, prev_rd_cnt, prev_rd_cnt1, prev_rd_cnt2, prev_rd_cnt3, prev_rd_cnt4;

reg [31:0] signed_data_p0, signed_data_p1, signed_data_p2, signed_data_comb, signed_data_res;
reg [11:0] reg_data_out;
reg [11:0] identity, identity1, identity2;
reg [$clog2(SW_WIRE_CNT*RD_WIRE_CNT)-1:0] reg_bram_addr;
reg valid, valid1, valid2;

assign sw_wires = prev_sw_cnt4;
assign rd_wires = prev_rd_cnt4;
assign data_out = reg_data_out;
assign bram_addr = reg_bram_addr;


always_comb begin
    if(rd_cnt + 'd1 >= RD_WIRE_CNT) begin
        reg_bram_addr = ((rd_cnt + 'd1) % RD_WIRE_CNT) + (((sw_cnt + 'd1) % SW_WIRE_CNT) * SW_WIRE_CNT);
    end else begin
        reg_bram_addr = (rd_cnt + 'd1) + (sw_cnt * SW_WIRE_CNT);
    end
end

always@(posedge clk) begin
    if(rst) begin
        rd_cache0 <= 0;
        rd_cache1 <= 0;
        rd_cache2 <= 0;
        sw_cnt <= 0;
        rd_cnt <= 0;
    end else begin
        //stage 0
        rd_cache0[rd_cnt] <= data_in;

        if(rd_cnt + 'd1 == RD_WIRE_CNT) begin
            sw_cnt <= (sw_cnt + 'd1) % SW_WIRE_CNT;
            prev_sw_cnt <= sw_cnt;

            rd_cache1 <= rd_cache0;
            rd_cache2 <= rd_cache1;
        end
        rd_cnt <= (rd_cnt + 'd1) % RD_WIRE_CNT;
        prev_rd_cnt <= rd_cnt;

        //stage 1
        valid <= (prev_sw_cnt != 0 && prev_sw_cnt != SW_WIRE_CNT - 'd1 &&
                  prev_rd_cnt != 0 && prev_rd_cnt != RD_WIRE_CNT - 'd1);

        identity <= rd_cache1[prev_rd_cnt];

        signed_data_p0 <= $signed({1'b0, rd_cache0[prev_rd_cnt - 'd1]}) * $signed(coeffs[0][0]) +
                          $signed({1'b0, rd_cache0[prev_rd_cnt      ]}) * $signed(coeffs[0][1]) +
                          $signed({1'b0, rd_cache0[prev_rd_cnt + 'd1]}) * $signed(coeffs[0][2]);

        signed_data_p1 <= $signed({1'b0, rd_cache1[prev_rd_cnt - 'd1]}) * $signed(coeffs[1][0]) +
                          $signed({1'b0, rd_cache1[prev_rd_cnt      ]}) * $signed(coeffs[1][1]) +
                          $signed({1'b0, rd_cache1[prev_rd_cnt + 'd1]}) * $signed(coeffs[1][2]);

        signed_data_p2 <= $signed({1'b0, rd_cache2[prev_rd_cnt - 'd1]}) * $signed(coeffs[2][0]) +
                          $signed({1'b0, rd_cache2[prev_rd_cnt      ]}) * $signed(coeffs[2][1]) +
                          $signed({1'b0, rd_cache2[prev_rd_cnt + 'd1]}) * $signed(coeffs[2][2]);

        prev_rd_cnt1 <= prev_rd_cnt;
        prev_sw_cnt1 <= prev_sw_cnt;
        //stage 2
        signed_data_comb <= $signed(signed_data_p0) + $signed(signed_data_p1) + $signed(signed_data_p2);

        valid1 <= valid;
        identity1 <= identity;
        prev_rd_cnt2 <= prev_rd_cnt1;
        prev_sw_cnt2 <= prev_sw_cnt1;
        //stage 3
        signed_data_res <= $signed(signed_data_comb) >>> shift;

        valid2 <= valid1;
        identity2 <= identity1;
        prev_rd_cnt3 <= prev_rd_cnt2;
        prev_sw_cnt3 <= prev_sw_cnt2;
        //stage 4
        if(valid2) begin
            reg_data_out <= signed_data_res;
        end else begin
            reg_data_out <= identity2;
        end
        prev_rd_cnt4 <= prev_rd_cnt3;
        prev_sw_cnt4 <= prev_sw_cnt3;
    end
end

endmodule

`default_nettype wire

`default_nettype none
`timescale 1ns / 1ps

module mux_select #(
    parameter SW_WIRE_CNT = 'd16,
    parameter RD_WIRE_CNT = 'd16
    ) (
    input wire clk_in,
    input wire pulse_sw,
    input wire pulse_rd,
    input wire rst,
    output wire [$clog2(SW_WIRE_CNT):0] sw_mux_sel,
    output wire [$clog2(RD_WIRE_CNT):0] rd_mux_sel
    );

    logic [$clog2(SW_WIRE_CNT-1):0] sw_mux_sel_reg;
    assign sw_mux_sel = sw_mux_sel_reg;

    logic [$clog2(RD_WIRE_CNT-1):0] rd_mux_sel_reg;
    assign rd_mux_sel = rd_mux_sel_reg;

    initial begin
        sw_mux_sel_reg = 0;
        rd_mux_sel_reg = 0;
    end

    always_ff @(posedge clk_in) begin
        if (rst) begin
            sw_mux_sel_reg <= 0;
            rd_mux_sel_reg <= 0;
        end else begin
            if (pulse_sw) begin
                sw_mux_sel_reg <= sw_mux_sel_reg + 'd1;
                if (sw_mux_sel_reg + 'd1 > SW_WIRE_CNT-'d1) begin
                    sw_mux_sel_reg <= 0;
                end
            end

            if (pulse_rd) begin
                rd_mux_sel_reg <= rd_mux_sel_reg + 'd1;
                if (rd_mux_sel_reg + 'd1 > RD_WIRE_CNT-'d1) begin
                    rd_mux_sel_reg <= 0;
                end
            end
        end
    end

endmodule

`default_nettype wire
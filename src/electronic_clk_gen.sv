`timescale 1ns / 1ps
`default_nettype none

module electronic_clk_gen #(
    parameter RD_WIRE_CNT = 'd16,
    parameter ADC_TQUIET = 'd4,
    parameter GLOBAL_DIV = 'd1000
) (
    input wire clk_ref,
    output wire clk_adc
);
    reg [$clog2(GLOBAL_DIV):0] adc_cnt;
    logic clk_adc_reg;
    assign clk_adc = clk_adc_reg;

    initial begin
        adc_cnt = 0;
        clk_adc_reg = 0;
    end

    always@(posedge clk_ref) begin
        if (adc_cnt == (GLOBAL_DIV -'d1)) begin
            clk_adc_reg <= !clk_adc_reg;
            adc_cnt <= 0;
        end
        adc_cnt <= adc_cnt + 'd1;
    end
endmodule

`default_nettype wire
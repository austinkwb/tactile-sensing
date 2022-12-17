`timescale 1ns / 1ps
`default_nettype none

module pulse_gen #(
    parameter SW_WIRE_CNT = 'd16,
    parameter RD_WIRE_CNT = 'd16,
    parameter TSERIAL = 'd16,
    parameter TQUIET = 'd4
) (
    input wire clk_ref,
    input wire rst,
    input wire active_on,

    output wire pulse_sw,
    output wire pulse_rd
);

    reg [$clog2(SW_WIRE_CNT * RD_WIRE_CNT):0] sw_cnt;
    reg [$clog2(TSERIAL + TQUIET):0] rd_cnt;

    reg pulse_sw_reg, pulse_rd_reg;
    assign pulse_sw = pulse_sw_reg;
    assign pulse_rd = pulse_rd_reg;

    initial begin
        sw_cnt = 0;
        rd_cnt = 0;

        pulse_sw_reg = 0;
        pulse_rd_reg = 0;
    end

    always@(posedge clk_ref) begin
        if (rst) begin 
            pulse_sw_reg <= 0;
            sw_cnt <= 0;
            pulse_rd_reg <= 0;
            rd_cnt <= 0;
        end else begin 
            if (active_on) begin 
                if(sw_cnt == (RD_WIRE_CNT*(TSERIAL + TQUIET)) - 'd1) begin
                    pulse_sw_reg <= 1;
                    sw_cnt <= 0;
                end else begin
                    pulse_sw_reg <= 0;
                    sw_cnt <= sw_cnt + 1'd1;
                end

                if(rd_cnt == ((TSERIAL + TQUIET) - 'd1)) begin
                    pulse_rd_reg <= 1;
                    rd_cnt <= 0;
                end else begin
                    pulse_rd_reg <= 0;
                    rd_cnt <= rd_cnt + 1'd1;
                end
            end else begin
                pulse_sw_reg <= 0;
                pulse_rd_reg <= 0;
            end
        end
    end

endmodule

`default_nettype wire
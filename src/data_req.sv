`default_nettype none
`timescale 1ns / 1ps

//yoinked from Lab 4b mirror.sv, Adapted for wires

module data_req #(
    parameter SW_WIRE_CNT = 'd16,
    parameter RD_WIRE_CNT = 'd16,
    parameter HORIZONTAL_PIXEL = 'd1024,  //should be 1024
    parameter VERTICAL_PIXEL = 'd768 // should theoretically be 768 but idk
    )(
    input wire clk_in,
    input wire rst_in,
    input wire [1:0] scale_in,
    input wire mirror_in,
    input wire [10:0] hcount_in,
    input wire [9:0] vcount_in,

    output logic [$clog2(SW_WIRE_CNT * RD_WIRE_CNT)-1:0] addr_out
    );
    logic [10:0] hcount_temp;
    logic [9:0] vcount_pip;

    always_ff @(posedge clk_in) begin
        if (rst_in) begin
            hcount_temp <= 0;
            vcount_pip <= 0;
            addr_out <= 0;
        end else begin
            vcount_pip <= vcount_in;
            if(scale_in==2'b0)begin
                hcount_temp <= mirror_in?(RD_WIRE_CNT-hcount_in):hcount_in;
                addr_out <= hcount_temp + SW_WIRE_CNT*vcount_pip;
            end else if (scale_in==2'b01)begin
                hcount_temp <= mirror_in?((RD_WIRE_CNT*'d16)-hcount_in):hcount_in;
                addr_out <= (hcount_temp >> $clog2('d16)) + SW_WIRE_CNT*(vcount_pip >> $clog2('d16));
            end else if (scale_in == 2'b10)begin
                hcount_temp <= mirror_in?((RD_WIRE_CNT*'d32)-hcount_in):hcount_in;
                addr_out <= (hcount_temp >> $clog2('d32)) + SW_WIRE_CNT*(vcount_pip >> $clog2('d32));
            end else begin
                hcount_temp <= mirror_in?((RD_WIRE_CNT*'d64)-hcount_in):hcount_in;
                addr_out <= (hcount_temp >> $clog2('d64)) + SW_WIRE_CNT*(vcount_pip >> $clog2('d64));
            end
        end
    end

endmodule

`default_nettype wire
`default_nettype none
`timescale 1ns / 1ps

module visualizer #(
    parameter SW_WIRE_CNT = 'd16,
    parameter RD_WIRE_CNT = 'd16,
    parameter DATA_THRESH_LOW = 'd0,
    parameter DATA_THRESH_HIGH = 'd4095
) (
    input wire clk,
    input wire rst,
    input wire [11:0]  data_in,

    output wire [11:0] data_out
);

reg[3:0] r, g, b;
assign data_out = {r, g, b};
reg [11:0] data_scaled;
assign data_scaled = ((data_in - DATA_THRESH_LOW) * 'd767) >> $clog2(DATA_THRESH_HIGH - DATA_THRESH_LOW);

always@(posedge clk) begin
    if (rst) begin
        r <= 0;
        g <= 0;
        b <= 0;
    end else begin
        if (data_in <= DATA_THRESH_LOW) begin
            r <= 0;
            g <= 0;
            b <= 0;
        end else if(data_in >= DATA_THRESH_HIGH) begin
            r <= 'd255;
            g <= 'd255;
            b <= 'd255;
        end else begin
            if(data_scaled > 'd255) begin
                if(data_scaled > 'd511) begin //Green
                    r <= 'd255;
                    g <= data_scaled - 'd256;
                    b <= 0;
                end else begin //Blue
                    r <= 'd255;
                    g <= 'd255;
                    b <= data_scaled - 'd512;
                end
            end else begin //Red
                r <= data_scaled;
                g <= 0;
                b <= 0;
            end
        end
    end
end

endmodule

`default_nettype wire
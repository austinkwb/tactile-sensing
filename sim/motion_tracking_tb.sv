`default_nettype none
`timescale 1ns / 1ps

//ONLY RUNS IN VIVADO SIMULATOR

module motion_tracking_tb #(SW_WIRE_CNT = 'd16, RD_WIRE_CNT = 'd16)();

    logic clk_50mhz;
    logic rst;
    logic [10:0] hcount_in;
    logic [9:0] vcount_in;
    logic [10:0] x_com;
    logic [9:0] y_com;
    logic [1:0] scale_in;
    logic blue;

    motion_tracking #(
        .SW_WIRE_CNT('d16),
        .RD_WIRE_CNT('d16)
    ) motion (
        .clk(clk_50mhz),
        .rst(rst),
        .hcount_in(hcount_in),
        .vcount_in(vcount_in),
        .x_com(x_com),
        .y_com(y_com),
        .scale_in(2'b11),
        .blue(blue)
    );

    always begin
        clk_50mhz = ~clk_50mhz;
        #20;
    end

    always@(posedge clk_50mhz) begin

        if(hcount_in == 'd1023) begin
            //vcount_in <= vcount_in + 'd1;
            hcount_in <= 'd0;
        end else begin
            hcount_in <= hcount_in + 'd1;
        end


        x_com <= x_com + 'd1;

        y_com <= 0;
    end

    //initial block for test simulation
    initial begin
        $display("Starting Sim"); //print nice message
        $dumpfile("motion_tracking_tb.vcd"); //file to store value change dump (vcd)
        $dumpvars(0, motion_tracking_tb); //store everything at the current level and below
        $display("Testing assorted values");
        rst = 0;
        clk_50mhz = 0; //initialize clock
        vcount_in = 0;
        hcount_in = 0;
        x_com = 0;
        scale_in = 0;


        #20;  //wait a little bit of time at beginning
        rst = 1; //reset system
        #20;
        rst = 0;

        #5000000;

        $display("Finishing Sim"); //print nice message
        $finish;
    end

endmodule

`default_nettype wire
`default_nettype none
`timescale 1ns / 1ps

module mux_select_tb();

    logic clk_100mhz;
    logic rst;

    logic clk_sw;
    logic clk_rd;
    logic clk_adc;

    electronic_clk_gen #(
        .RD_WIRE_CNT('d16),
        .ADC_TQUIET('d4),
        .GLOBAL_DIV('d100)
    ) test (
        .clk_ref(clk_100mhz),
        .rst(rst),
        .clk_sw(clk_sw),
        .clk_rd(clk_rd),
        .clk_adc(clk_adc)
    );

    logic [4:0] sw_wires;
    logic [4:0] rd_wires;

    mux_select #(
        .SW_WIRE_CNT('d16),
        .RD_WIRE_CNT('d16)
    ) mux_test (
        .clk_sw(clk_sw),
        .clk_rd(clk_rd),
        .rst(rst),
        .sw_mux_sel(sw_wires),
        .rd_mux_sel(rd_wires)
    );

    always begin
        clk_100mhz = ~clk_100mhz;
        #10;
    end

    //initial block for test simulation
    initial begin
    $display("Starting Sim"); //print nice message
    $dumpfile("mux_select_tb.vcd"); //file to store value change dump (vcd)
    $dumpvars(0, mux_select_tb); //store everything at the current level and below
    $display("Testing assorted values");
    rst = 0;
    clk_100mhz = 0; //initialize clock

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
`default_nettype none
`timescale 1ns / 1ps

module visualizer_tb();

    logic clk_100mhz;
    logic rst;
    logic [11:0] data_in;

    visualizer #(
     .SW_WIRE_CNT('d16),
    .RD_WIRE_CNT('d16)
    ) test (
    .clk(clk_100mhz),
    .rst(rst),
    .hcount('d10),
    .vcount('d10),
    .data_in(data_in)
);

    always begin
        clk_100mhz = ~clk_100mhz;
        #10;
    end

    //initial block for test simulation
    initial begin
        $display("Starting Sim"); //print nice message
        $dumpfile("visualizer_tb.vcd"); //file to store value change dump (vcd)
        $dumpvars(0, visualizer_tb); //store everything at the current level and below
        $display("Testing assorted values");
        rst = 0;
        clk_100mhz = 0; //initialize clock
        data_in = 0;

        #20;  //wait a little bit of time at beginning
        rst = 1; //reset system
        #20;
        rst = 0;

        for(int i=0; i < 'd2**'d12; i++) begin
            data_in = data_in + 'd1;
            #20;
        end

        $display("Finishing Sim"); //print nice message
        $finish;
    end

endmodule

`default_nettype wire
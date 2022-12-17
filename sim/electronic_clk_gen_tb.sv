`default_nettype none
`timescale 1ns / 1ps

module electronic_clk_gen_tb();

    logic clk_100mhz;
    logic rst;

    electronic_clk_gen #(
        .RD_WIRE_CNT('d2),
        .GLOBAL_DIV('d1000)
    ) test (
        .clk_ref(clk_100mhz),
        .rst(rst)
    );

    always begin
        clk_100mhz = ~clk_100mhz;
        #10;
    end

    //initial block for test simulation
    initial begin
        $display("Starting Sim"); //print nice message
        $dumpfile("electronic_clk_gen.vcd"); //file to store value change dump (vcd)
        $dumpvars(0, electronic_clk_gen_tb); //store everything at the current level and below
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
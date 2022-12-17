
`default_nettype none
`timescale 1ns / 1ps

module adc_read_tb();

    logic clk_50mhz;
    logic rst;
    logic data_in;
    logic adc_cs_out;
    logic valid_out;
    logic error_out;
    logic [11:0] read_out;

    logic [2:0] test_case;
    logic [39:0] test_val;

    adc_read adc( .clk(clk_50mhz), 
                    .rst(rst),
                    .data_in(data_in),
                    .adc_cs_out(adc_cs_out),
                    .valid_out(valid_out),
                    .error_out(error_out),
                    .read_out(read_out));

    always begin
        clk_50mhz = ~clk_50mhz;
        #10;
    end

    //initial block for test simulation
    initial begin
    $display("Starting Sim"); //print nice message
    $dumpfile("adc_read.vcd"); //file to store value change dump (vcd)
    $dumpvars(0, adc_read_tb); //store everything at the current level and below
    $display("Testing assorted values");
    rst = 0;
    data_in = 0;
    clk_50mhz = 0; //initialize clock

    //case 0: testing input 16 zeros
    test_case = 0;
    #20;  //wait a little bit of time at beginning
    rst = 1; //reset system
    #20;
    rst = 0;
    for (int i = 0; i<(30); i= i+1)begin //data
        data_in = 0;
        #20;
    end

    /*
    //case 0: testing input 4 zeros, 12 1s
    test_case = 2;
    for (int i = 0; i<(4); i= i+1)begin //data
        data_in = 0;
        #20;
    end
    for (int i = 0; i<(12); i= i+1)begin //data
        data_in = 1;
        #20;
    end
    test_case = 3;
    for (int i = 0; i<(4); i= i+1)begin //data
        data_in = 0;
        #20;
    end
    for (int i = 0; i<(12); i= i+1)begin //data
        data_in = (i%2==0);
        #20;
    end
    //should break
    test_case = 4;
    for (int i = 0; i<(3); i= i+1)begin //data
        data_in = 0;
        #20;
    end
    for (int i = 0; i<(13); i= i+1)begin //data
        data_in = (i%2==0);
        #20;
    end
    */

    $display("Finishing Sim"); //print nice message
    $finish;
    end

endmodule

`default_nettype wire 
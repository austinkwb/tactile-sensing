`default_nettype none
`timescale 1ns / 1ps

module simple_counter_tb();

    logic clk_in;
    logic rst_in;
    logic add_pulse;
    logic sub_pulse;
    logic [3:0] count_out;

    simple_counter #(
        .MAX_COUNT('d16),
        .START_VAL('d15)
    ) counter (
        .clk_in(clk_in),
        .rst_in(rst_in),
        .add_evt_in(add_pulse),
        .sub_evt_in(sub_pulse),
        .count_out(count_out)
    );

    always begin
        clk_in = ~clk_in;
        #10;
    end

    //initial block for test simulation
    initial begin
    $display("Starting Sim"); //print nice message
    $dumpfile("simple_counter.vcd"); //file to store value change dump (vcd)
    $dumpvars(0, simple_counter_tb); //store everything at the current level and below
    $display("Testing assorted values");
    rst_in = 0;
    clk_in = 0; //initialize clock

    #20;  //wait a little bit of time at beginning
    rst_in = 1; //reset system
    #20;
    rst_in = 0;

    add_pulse = 0;
    sub_pulse = 0;
    #10  //wait a little bit of time at beginning
    //$display("add_pulse = %1b sub_pulse = %1b",add_pulse, sub_pulse);
    $display("add_pulse x5");
    for (integer i = 0; i<5; i= i+1)begin
        add_pulse = 1;
        #10;
        add_pulse = 0;
        $display("count_out = %5d", count_out);
        #10;
    end

    $display("sub_pulse x5");
    for (integer i = 0; i<5; i= i+1)begin
        sub_pulse = 1;
        #10;
        sub_pulse = 0;
        $display("count_out = %5d", count_out);
        #10;
    end

    $display("sub_pulse x3");
    for (integer i = 0; i<3; i= i+1)begin
        sub_pulse = 1;
        #10;
        sub_pulse = 0;
        $display("count_out = %5d", count_out);
        #10;
    end

    $display("sub_pulse x16");
    for (integer i = 0; i<(16); i= i+1)begin
        sub_pulse = 1;
        #10;
        sub_pulse = 0;
        $display("count_out = %5d", count_out);
        #10;
    end

    $display("add_pulse x16");
    for (integer i = 0; i<(16); i= i+1)begin
        add_pulse = 1;
        #10;
        add_pulse = 0;
        $display("count_out = %5d", count_out);
        #10;
    end

    #100

    $display("Finishing Sim"); //print nice message
    $finish;
    end

endmodule

`default_nettype wire 
`default_nettype none
`timescale 1ns / 1ps

module threshold_input_tb();

    logic clk_in;
    logic rst_in;
    logic btnu, btnd, btnl, btnr;
    logic threshold_on;
    logic threshold_lowhi;
    logic [11:0] lower_bound, upper_bound;

    threshold_input thresholder (
        .clk_in(clk_in),
        .rst_in(rst_in),
        .btnu(btnu), .btnd(btnd), .btnl(btnl), .btnr(btnr), //buttons
        .threshold_on(threshold_on), //Switches: 0 is off, 1 is on 
        .threshold_lowhi(threshold_lowhi), //Switches: 0 is low, 1 is high 
        // .cat_out({cag, caf, cae, cad, cac, cab, caa}),
        // .an_out(an),
        .lower_bound_out(lower_bound),
        .upper_bound_out(upper_bound)
    );

    always begin
        clk_in = ~clk_in;
        #10;
    end

    //initial block for test simulation
    initial begin
    $display("Starting Sim"); //print nice message
    $dumpfile("threshold_input.vcd"); //file to store value change dump (vcd)
    $dumpvars(0, threshold_input_tb); //store everything at the current level and below
    $display("Testing assorted values");
    rst_in = 0;
    clk_in = 0; //initialize clock
    btnu = 0;
    btnd = 0;
    btnl = 0;
    btnr = 0;
    threshold_on = 1;
    threshold_lowhi = 0;

    #20;  //wait a little bit of time at beginning
    rst_in = 1; //reset system
    #20;
    rst_in = 0;
    #5

    $display("Threshold: %d, Low(0)/High(1): %d, {btnu: %d, btnd: %d, btnl: %d, btnr: %d}", threshold_on, threshold_lowhi, btnu, btnd, btnl, btnr);
    $display("Lower Bound: %d, Upper Bound: %d", lower_bound, upper_bound);

    threshold_on = 0;
    btnu = 1;
    #20
    $display("Threshold: %d, Low(0)/High(1): %d, {btnu: %d, btnd: %d, btnl: %d, btnr: %d}", threshold_on, threshold_lowhi, btnu, btnd, btnl, btnr);
    $display("Lower Bound: %d, Upper Bound: %d", lower_bound, upper_bound);
    threshold_on = 1;
    btnu = 0;
    #10

    threshold_on = 1;
    btnu = 1;
    #20
    $display("Threshold: %d, Low(0)/High(1): %d, {btnu: %d, btnd: %d, btnl: %d, btnr: %d}", threshold_on, threshold_lowhi, btnu, btnd, btnl, btnr);
    $display("Lower Bound: %d, Upper Bound: %d", lower_bound, upper_bound);
    btnu = 0;
    #10

    threshold_on = 1;
    btnu = 1;
    #20
    $display("Threshold: %d, Low(0)/High(1): %d, {btnu: %d, btnd: %d, btnl: %d, btnr: %d}", threshold_on, threshold_lowhi, btnu, btnd, btnl, btnr);
    $display("Lower Bound: %d, Upper Bound: %d", lower_bound, upper_bound);
    btnu = 0;
    #10

    threshold_on = 1;
    btnu = 0;
    #20
    $display("Threshold: %d, Low(0)/High(1): %d, {btnu: %d, btnd: %d, btnl: %d, btnr: %d}", threshold_on, threshold_lowhi, btnu, btnd, btnl, btnr);
    $display("Lower Bound: %d, Upper Bound: %d", lower_bound, upper_bound);
    btnu = 0;
    #10

    threshold_on = 1;
    btnu = 0;
    btnd = 1;
    #20
    $display("Threshold: %d, Low(0)/High(1): %d, {btnu: %d, btnd: %d, btnl: %d, btnr: %d}", threshold_on, threshold_lowhi, btnu, btnd, btnl, btnr);
    $display("Lower Bound: %d, Upper Bound: %d", lower_bound, upper_bound);
    btnd = 0;
    #10

    threshold_on = 1;
    btnu = 0;
    btnd = 1;
    #20
    $display("Threshold: %d, Low(0)/High(1): %d, {btnu: %d, btnd: %d, btnl: %d, btnr: %d}", threshold_on, threshold_lowhi, btnu, btnd, btnl, btnr);
    $display("Lower Bound: %d, Upper Bound: %d", lower_bound, upper_bound);
    btnd = 0;
    #10

    threshold_on = 1;
    btnl = 1;
    btnd = 0;
    #20
    $display("Threshold: %d, Low(0)/High(1): %d, {btnu: %d, btnd: %d, btnl: %d, btnr: %d}", threshold_on, threshold_lowhi, btnu, btnd, btnl, btnr);
    $display("Lower Bound: %d, Upper Bound: %d", lower_bound, upper_bound);
    btnl = 0;
    #10

    threshold_on = 1;
    btnu = 1;
    #20
    $display("Threshold: %d, Low(0)/High(1): %d, {btnu: %d, btnd: %d, btnl: %d, btnr: %d}", threshold_on, threshold_lowhi, btnu, btnd, btnl, btnr);
    $display("Lower Bound: %d, Upper Bound: %d", lower_bound, upper_bound);
    btnu = 0;
    #10;

    #100

    $display("Finishing Sim"); //print nice message
    $finish;
    end

endmodule

`default_nettype wire 
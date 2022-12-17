`default_nettype none
`timescale 1ns / 1ps

module uart_tb();

    logic clk_100mhz;
    logic rst;
    logic [11:0] data_in;
    logic data_valid_in;
    logic data_out;
    logic uart_ready;
    logic uart_flag;
    logic [3:0] test_case;

    uart_transmit test (
        .clk_in(clk_100mhz),
        .rst_in(rst),
        .data_in(data_in),
        .transmit_active(1'b1),
        .data_valid_in(data_valid_in),
        .ready_out(uart_ready),
        .data_out(data_out)
    );

    always begin
        clk_100mhz = ~clk_100mhz;vv
        #10;
    end

    //initial block for test simulation
    initial begin
        $display("Starting Sim"); //print nice message
        $dumpfile("uart_tb.vcd"); //file to store value change dump (vcd)
        $dumpvars(0, uart_tb); //store everything at the current level and below
        $display("Testing assorted values");
        rst = 0;
        clk_100mhz = 0; //initialize clock
        data_in = 12'b0;
        data_valid_in = 0;

        #20;  //wait a little bit of time at beginning
        rst = 1; //reset system
        #20;
        rst = 0;

        test_case = 1;
        #1000;
        data_valid_in = 1;
        data_in = 12'b1010_1010_1010;
        #20;
        data_valid_in = 0;
        data_in = 12'b0;
        #20;
        
        while (~uart_ready) begin
            #20;
        end

        test_case = 2;
        #1000
        data_valid_in = 1;
        data_in = 12'b0000_0000_0000;
        #20;
        data_valid_in = 0;
        data_in = 12'b0;
        
        while (~uart_ready) begin
            #20;
        end

        test_case = 3;
        #1000
        data_valid_in = 1;
        data_in = 12'b1111_1111_1111;
        #20;
        data_valid_in = 0;
        data_in = 12'b0;
        
        while (~uart_ready) begin
            #20;
        end

        $display("Finishing Sim"); //print nice message
        $finish;
    end

endmodule

`default_nettype wire
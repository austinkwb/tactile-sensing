module uart_full_tb();

    logic clk_100mhz;
    logic rst_in;
    logic [11:0] data_in;
    logic data_valid_in;
    logic uart_active;
    logic data_out;
    logic [7:0] read_addr;
    logic [3:0] test_case;
    logic [7:0] debug_in;

    uart #(
        .SW_WIRE_CNT('d16), //Switching wire count
        .RD_WIRE_CNT('d16),  //Sampling/Read wire count
        .CLOCK_RATE('d100_000_000),
        .BAUD_RATE('d10_115_200)
    ) uart_test (
        .clk_in(clk_100mhz),
        .rst_in(rst_in),
        .uart_active(uart_active),
        .data_in(data_in),
        .debug_in(debug_in),

        .read_addr(read_addr),
        .uart_output(data_out)
    );

    always begin
        clk_100mhz = ~clk_100mhz;
        #10;
    end

    //initial block for test simulation
    initial begin
    $display("Starting Sim"); //print nice message
    $dumpfile("uart_full_tb.vcd"); //file to store value change dump (vcd)
    $dumpvars(0, uart_full_tb); //store everything at the current level and below
    $display("Testing assorted values");
    rst_in = 0;
    clk_100mhz = 0; //initialize clock
    uart_active = 1;
    debug_in = 0;
    data_in = 12'hFFFF_FFFF_FFFF;

    #20;  //wait a little bit of time at beginning
    rst_in = 1; //reset system
    #20;
    rst_in = 0;

    #700000;

    $display("Finishing Sim"); //print nice message
    $finish;
    end



endmodule
    
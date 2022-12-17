`default_nettype none
`timescale 1ns / 1ps

module convolution_tb #(SW_WIRE_CNT = 'd16, RD_WIRE_CNT = 'd16)();

    logic clk_50mhz;
    logic rst;
    logic [11:0] data_in;
    logic signed [2:0][2:0][7:0] coeffs;
    logic signed [7:0] shift;

    kernels #(
        .K_SELECT(0)
    ) kern (
        .rst_in(rst),
        .coeffs(coeffs),
        .shift(shift)
    );

    logic [$clog2(SW_WIRE_CNT*RD_WIRE_CNT)-1:0] bram_addr;
    logic [$clog2(SW_WIRE_CNT):0] sw_wires;
    logic [$clog2(RD_WIRE_CNT):0] rd_wires;
    logic [11:0] data_out;

    convolution #(
        .SW_WIRE_CNT('d16),
        .RD_WIRE_CNT('d16)
    ) conv (
        .clk(clk_50mhz),
        .rst(rst),
        .data_in(data_in),
        .shift(shift),
        .coeffs(coeffs),

        .bram_addr(bram_addr),
        .sw_wires(sw_wires),
        .rd_wires(rd_wires),
        .data_out(data_out)
    );

    always begin
        clk_50mhz = ~clk_50mhz;
        #20;
    end

    always@(posedge clk_50mhz) begin
        data_in <= bram_addr == ('d7) + ('d7 * SW_WIRE_CNT) ? 'd4095 : 'd0;
        // if(sw_wires == 'd7 && rd_wires == 'd7) begin
        //     $display("%s", data_out == 'd4095);
        // end
    end

    //initial block for test simulation
    initial begin
        $display("Starting Sim"); //print nice message
        $dumpfile("convolution_tb.vcd"); //file to store value change dump (vcd)
        $dumpvars(0, convolution_tb); //store everything at the current level and below
        $display("Testing assorted values");
        rst = 0;
        clk_50mhz = 0; //initialize clock
        data_in = 0;

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
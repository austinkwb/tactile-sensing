`default_nettype none
`timescale 1ns / 1ps

module pulse_gen_uart_tb();

    logic clk_100mhz;
    logic rst;
    logic rst_in;
    parameter SW_WIRE_CNT = 16;
    parameter RD_WIRE_CNT = 16;
    logic clk_in;
    assign clk_in = clk_100mhz;
    assign rst_in = rst;
    logic [10:0] i;

    logic uart_ready, uart_ready_past, pulse_uart;
    logic pulse_sw, pulse_rd;
    logic [$clog2(SW_WIRE_CNT):0] sw_wire;
    logic [$clog2(RD_WIRE_CNT):0] rd_wire;

    pulse_gen #(
        .RD_WIRE_CNT(RD_WIRE_CNT),
        .SW_WIRE_CNT(SW_WIRE_CNT),
        .TSERIAL('d1),
        .TQUIET('d0)
    ) uart_pulse_gen (
        .clk_ref(clk_in),
        .rst(rst_in),
        .active_on(uart_ready),
        .pulse_sw(pulse_sw),
        .pulse_rd(pulse_rd)
    );

    //counts the wires
    mux_select #(
      .SW_WIRE_CNT(SW_WIRE_CNT),
      .RD_WIRE_CNT(RD_WIRE_CNT)
    ) uart_wire_select (
      .clk_in(clk_in),
      .rst(rst_in),
      .pulse_sw(pulse_sw),
      .pulse_rd(pulse_rd),
      .sw_mux_sel(sw_wire),
      .rd_mux_sel(rd_wire)
    );

    always begin
        clk_100mhz = ~clk_100mhz;
        #10;
    end

    // always_ff @(posedge clk_in) begin
    //     pulse_uart <= uart_ready && ~uart_ready_past;
    //     uart_ready_past <= uart_ready;
    // end

    //initial block for test simulation
    initial begin
    $display("Starting Sim"); //print nice message
    $dumpfile("pulse_gen_uart_tb.vcd"); //file to store value change dump (vcd)
    $dumpvars(0, pulse_gen_uart_tb); //store everything at the current level and below
    $display("Testing assorted values");
    rst = 0;
    uart_ready = 0;
    i = 0;
    clk_100mhz = 0; //initialize clock

    #20;  //wait a little bit of time at beginning
    rst = 1; //reset system
    #20;
    rst = 0;
    #10

    while (i < 50) begin
        uart_ready = 1;
        #20;
        uart_ready = 0;
        #60;
        i = i + 1;
    end

    $display("Finishing Sim"); //print nice message
    $finish;
    end

endmodule

`default_nettype wire 
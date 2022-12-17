`default_nettype none
`timescale 1ns / 1ps

module pulse_gen_tb();

    logic clk_100mhz;
    logic rst;
    parameter RD_WIRE_CNT = 'd16;
    parameter SW_WIRE_CNT = 'd16;

    //logic clk_sw;
    //logic clk_rd;
    logic clk_adc;

    electronic_clk_gen #(
        .RD_WIRE_CNT(RD_WIRE_CNT),
        .ADC_TQUIET('d4),
        .GLOBAL_DIV('d10)
    ) test (
        .clk_ref(clk_100mhz),
        .clk_adc(clk_adc)
    );

    //Pulse generation for wire count changing
  localparam ADC_DATA_IN_SIZE = 'd16;
  logic pulse_sw, pulse_rd;
  pulse_gen #(
      .RD_WIRE_CNT('d16),
      .SW_WIRE_CNT('d16),
      .TQUIET('d4),
      .TSERIAL(ADC_DATA_IN_SIZE)
  ) pulse_test (
      .clk_ref(clk_adc),
      .rst(rst),
      .active_on(1'b1),
      .pulse_sw(pulse_sw),
      .pulse_rd(pulse_rd)
  );

    logic [$clog2(SW_WIRE_CNT):0] sw_wires;
  logic [$clog2(RD_WIRE_CNT):0] rd_wires;
//   assign jb[3:0] = sw_wires;
//   assign jd[3:0] = rd_wires;
  //begin the reading
  mux_select #(
      .SW_WIRE_CNT(SW_WIRE_CNT),
      .RD_WIRE_CNT(RD_WIRE_CNT)
  ) mux_select (
      .clk_in(clk_adc),
      .rst(rst),
      .pulse_sw(pulse_sw),
      .pulse_rd(pulse_rd),
      .sw_mux_sel(sw_wires),
      .rd_mux_sel(rd_wires)
    );

    logic data_in;
    logic adc_cs_out;
    logic valid_out;
    logic error_out;
    logic [11:0] read_out;

    logic [2:0] test_case;
    logic [39:0] test_val;

    adc_read adc( .clk(clk_adc), 
                    .rst(rst),
                    .data_in(data_in),
                    .pulse_rd(pulse_rd),
                    .adc_cs_out(adc_cs_out),
                    .valid_out(valid_out),
                    .error_out(error_out),
                    .read_out(read_out));

    always begin
        clk_100mhz = ~clk_100mhz;
        #10;
    end

    //initial block for test simulation
    initial begin
    $display("Starting Sim"); //print nice message
    $dumpfile("pulse_gen_tb.vcd"); //file to store value change dump (vcd)
    $dumpvars(0, pulse_gen_tb); //store everything at the current level and below
    $display("Testing assorted values");
    rst = 0;
    data_in = 0;
    clk_100mhz = 0; //initialize clock

    #20;  //wait a little bit of time at beginning
    rst = 1; //reset system
    #20;
    rst = 0;

    #10000000;

    $display("Finishing Sim"); //print nice message
    $finish;
    end

endmodule

`default_nettype wire 
`timescale 1ns / 1ps
`default_nettype none

module top_level #(
  parameter SW_WIRE_CNT = 'd16, //Switching wire count
  parameter RD_WIRE_CNT = 'd16,  //Sampling/Read wire count
  parameter ADC_CLK_DIVIDE = 'd4, //speed of ADC clock
  parameter BAUD_RATE = 'd115_200 //speed of UART baud
  ) (
  //system
  input wire clk_100mhz, //clock @ 100 mhz
  input wire btnc, //used for reset
  output wire [2:0] led, //Error Flags
  input wire [15:0] sw, //Switches inputs
  input wire btnu, btnd, btnl, btnr, //Thresholding
  output logic caa, cab, cac, cad, cae, caf, cag, //Thresholding
  output logic [7:0] an, //Thresholding

  //adc
  input wire jc_adc_read_d0, //adc read ins
  output wire jc_cs, //Drive the ADC
  output wire jc_clk, //Drive the ADC

  //switching/reading wires
  output wire [3:0] jb, //Drives the mux for SW wires
  output wire [3:0] jd, //Drives the mux for RD wires

  //uart
  // input wire uart_txd_in,
  output logic uart_rxd_out,

  //vga
  output logic [3:0] vga_r, vga_g, vga_b,
  output logic vga_hs, vga_vs
  );

  //Switches for User Input
  logic [1:0] scale_input;
  logic mirror_input;
  logic threshold_highlow_input;
  logic conv_filter_input;
  logic crosshair_on_input;
  logic uart_active_input;
  logic mask_on_input;
  logic blue_on_input;
  logic uart_truncate_input;

  assign scale_input = sw[1:0];
  assign mirror_input = sw[2];
  assign threshold_highlow_input = sw[3];
  assign conv_filter_input = sw[6:4];

  assign crosshair_on_input = sw[11];
  assign mask_on_input = sw[12];
  assign blue_on_input = sw[13];
  assign uart_truncate_input = sw[14];
  assign uart_active_input = sw[15];

  //System Reset
  logic sys_rst; //global system reset
  assign sys_rst = btnc;

  //VISUALIZATION SETUP ----------------------------------------------
  logic clk_65mhz; //65 MHz clock lines
  vga_clk_gen clk_gen0 (
    .clk_in1(clk_100mhz),
    .clk_out1(clk_65mhz)
  );
  
  //vga module generation signals:
  logic [10:0] hcount;    // pixel on current line
  logic [9:0] vcount;     // line number
  logic hsync, vsync, blank; //control signals for vga
  logic [3:0] r_val, g_val, b_val;
  //Generate VGA timing signals:
  vga vga_gen(
    .pixel_clk_in(clk_65mhz),
    .hcount_out(hcount),
    .vcount_out(vcount),
    .hsync_out(hsync),
    .vsync_out(vsync),
    .blank_out(blank)
  );
  
  //DATA ACQUISITION ----------------------------------------------
  //ADC clock generation
  wire clk_adc;
  localparam ADC_TQUIET = 'd4; //Clock cycles for for ADC reset
  electronic_clk_gen #(
    .RD_WIRE_CNT(RD_WIRE_CNT),
    .ADC_TQUIET(ADC_TQUIET),
    .GLOBAL_DIV(ADC_CLK_DIVIDE)
  ) clk_gen1 (
    .clk_ref(clk_65mhz),
    .clk_adc(clk_adc)
  );
  
  //Pulse generation for wire count changing
  localparam ADC_DATA_IN_SIZE = 'd16;
  logic pulse_sw, pulse_rd;
  pulse_gen #(
      .RD_WIRE_CNT(RD_WIRE_CNT),
      .SW_WIRE_CNT(SW_WIRE_CNT),
      .TQUIET(ADC_TQUIET),
      .TSERIAL(ADC_DATA_IN_SIZE)
  ) pulse_test (
      .clk_ref(clk_adc),
      .rst(sys_rst),
      .active_on(1'b1),
      .pulse_sw(pulse_sw),
      .pulse_rd(pulse_rd)
  );
  
  //Switching Counter and link to wires
  logic [$clog2(SW_WIRE_CNT):0] sw_wires;
  logic [$clog2(RD_WIRE_CNT):0] rd_wires;
  assign jb[3:0] = sw_wires;
  assign jd[3:0] = rd_wires;
  //begin the reading
  mux_select #(
      .SW_WIRE_CNT(SW_WIRE_CNT),
      .RD_WIRE_CNT(RD_WIRE_CNT)
  ) mux_select (
      .clk_in(clk_adc),
      .pulse_sw(pulse_sw),
      .pulse_rd(pulse_rd),
      .rst(sys_rst),
      .sw_mux_sel(sw_wires),
      .rd_mux_sel(rd_wires)
  );

  //ADC Read In
  logic adc_cs;
  logic [11:0] adc_output;
  logic adc_valid;
  logic adc_error_flag;
  assign led[0] = !adc_error_flag; //if ADC reader is misaligned
  assign jc_cs = adc_cs;
  assign jc_clk = clk_adc;
  adc_read #(
    .ADC_TQUIET(ADC_TQUIET)
  ) adc_reader(
    .clk(clk_adc),
    .rst(sys_rst),
    .pulse_rd(pulse_rd),
    .data_in(jc_adc_read_d0), //read in serial adc data
    .adc_cs_out(adc_cs),
    .valid_out(adc_valid),
    .error_out(adc_error_flag),
    .read_out(adc_output) //12 bit value after 16 of one adc value
  );

  //Clock verification
  logic clk_adc_valid;
  assign led[1] = clk_adc_valid; //ADC is properly reading bits and sending valid signals
  always@(posedge clk_adc) begin
    if(sys_rst) begin
      clk_adc_valid <= 0;
    end else if(adc_valid) begin
      clk_adc_valid <= 1;
    end
  end

  //Pipeline mux wires
  logic [$clog2(SW_WIRE_CNT):0] sw_wires_pipe;
  logic [$clog2(RD_WIRE_CNT):0] rd_wires_pipe;
  always@(posedge clk_adc) begin
    if (pulse_rd) begin
      sw_wires_pipe <= sw_wires;
      rd_wires_pipe <= rd_wires;
    end
  end

  //BRAM for Raw Data
  logic [11:0] raw_bram_data_out;
  logic [$clog2(SW_WIRE_CNT*RD_WIRE_CNT)-1:0] raw_read_addr_req;
  data_array #(
    .SW_WIRE_CNT(SW_WIRE_CNT),
    .RD_WIRE_CNT(RD_WIRE_CNT)
  ) rawdata_bram_storage (
    .clk_write(clk_adc), //when to write in?
    .clk_read(clk_65mhz),
    .rst(sys_rst),

    //writing in information
    .sw_write_in(sw_wires_pipe),
    .rd_write_in(rd_wires_pipe),
    .data_in(adc_output),
    .data_valid_in(adc_valid),

    //reading out information
    .read_addr(raw_read_addr_req),
    .data_out(raw_bram_data_out)
  );

  //DATA ANALYSIS (COMPUTATION) ----------------------------------------------
  //Set Threshold Value
  logic [11:0] threshold_lower_bound;
  logic [11:0] threshold_upper_bound;
  threshold_input #(
    .DATA_THRESH_LOW(0),
    .DATA_THRESH_HIGH('d4095)
  ) thresholder (
      .clk_in(clk_65mhz),
      .rst_in(sys_rst),
      .btnu(btnu), .btnd(btnd), .btnl(btnl), .btnr(btnr), //buttons
      .threshold_lowhi(threshold_highlow_input), //Switches: 0 is low, 1 is high
      .cat_out({cag, caf, cae, cad, cac, cab, caa}),
      .an_out(an),
      .lower_bound_out(threshold_lower_bound),
      .upper_bound_out(threshold_upper_bound)
  );
  //Scaled data to visualzier
  logic [11:0] scaled_data;
  scale #(
    .SW_WIRE_CNT(SW_WIRE_CNT),
    .RD_WIRE_CNT(RD_WIRE_CNT)
  ) scale_viz (
    .scale_in(scale_input),
    .hcount_in(hcount),
    .vcount_in(vcount),
    .data_in(vis_bram_data_out),
    .data_out(scaled_data)
  );

  //Threshold Action for COM:
  logic mask;
  assign mask = (scaled_data > threshold_lower_bound) && (scaled_data < threshold_upper_bound);
  
  //Threshold action for Convolution:
  reg [11:0] comp_data_in;
  always_comb begin
    if(raw_bram_data_out < threshold_lower_bound) begin
      comp_data_in = threshold_lower_bound;
    end else if(raw_bram_data_out > threshold_upper_bound) begin
      comp_data_in = threshold_upper_bound;
    end else begin
      comp_data_in = raw_bram_data_out;
    end
  end

 //Convolution
  wire [$clog2(SW_WIRE_CNT):0] data_sw_wires;
  wire [$clog2(RD_WIRE_CNT):0] data_rd_wires;
  wire [11:0] comp_data;
  computation #(
      .SW_WIRE_CNT(SW_WIRE_CNT),
      .RD_WIRE_CNT(RD_WIRE_CNT)
  ) comp (
      .clk(clk_65mhz),
      .rst(sys_rst),
      .k_select(conv_filter_input),
      .in_bram_data(comp_data_in),

      .in_bram_addr(raw_read_addr_req),
      .out_bram_data(comp_data),
      .sw_wires(data_sw_wires),
      .rd_wires(data_rd_wires)
  );

  //BRAM for Computation data (VIS)
  logic [11:0] vis_bram_data_out;
  logic [$clog2(SW_WIRE_CNT*RD_WIRE_CNT)-1:0] vis_read_addr_req;
  data_array #(
    .SW_WIRE_CNT(SW_WIRE_CNT),
    .RD_WIRE_CNT(RD_WIRE_CNT)
  ) vis_bram_storage (
    .clk_write(clk_65mhz), //when to write in?
    .clk_read(clk_65mhz),
    .rst(sys_rst),

    //writing in information
    .sw_write_in(data_sw_wires),
    .rd_write_in(data_rd_wires),
    .data_in(comp_data),
    .data_valid_in(1'b1),

    //reading out information
    .read_addr(vis_read_addr_req),
    .data_out(vis_bram_data_out)
  );

  //BRAM for Computation data UART
  logic [11:0] uart_bram_data_out;
  logic [$clog2(SW_WIRE_CNT*RD_WIRE_CNT)-1:0] uart_read_addr_req;
  data_array #(
    .SW_WIRE_CNT(SW_WIRE_CNT),
    .RD_WIRE_CNT(RD_WIRE_CNT)
  ) uart_bram_storage (
    .clk_write(clk_65mhz), //when to write in?
    .clk_read(clk_65mhz),
    .rst(sys_rst),

    //writing in information
    .sw_write_in(data_sw_wires),
    .rd_write_in(data_rd_wires),
    .data_in(comp_data),
    .data_valid_in(1'b1),

    //reading out information
    .read_addr(uart_read_addr_req),
    .data_out(uart_bram_data_out)
  );

  //Center of Mass:
  logic [10:0] x_com, x_com_calc;
  logic [9:0] y_com, y_com_calc;
  logic new_com;
  center_of_mass com_m(
    .clk_in(clk_65mhz),
    .rst_in(sys_rst),
    .x_in(hcount),
    .y_in(vcount),
    .valid_in(mask),
    .tabulate_in((hcount==0 && vcount==0)),
    .x_out(x_com_calc),
    .y_out(y_com_calc),
    .valid_out(new_com));

  //Update center of mass x_com, y_com based on new_com signal
  logic crosshair;
  always_ff @(posedge clk_65mhz)begin
    if (sys_rst)begin
      x_com <= 0;
      y_com <= 0;
    end if(new_com)begin
      x_com <= x_com_calc;
      y_com <= y_com_calc;
    end
  end
  assign crosshair = ((vcount==y_com)||(hcount==x_com));

  //Motion Tracking:
  logic blue;
  motion_tracking #(
    .SW_WIRE_CNT(SW_WIRE_CNT),
    .RD_WIRE_CNT(RD_WIRE_CNT),
    .CYCLE_TIMEOUT('d16250000)
  ) motion (
    .clk(clk_65mhz),
    .rst(sys_rst),
    .hcount_in(hcount),
    .vcount_in(vcount),
    .x_com(x_com),
    .y_com(y_com),
    .scale_in(scale_input),

    .blue(blue)
  );

  reg blue_check;
  assign led[2] = blue_check;
  always@(posedge clk_65mhz) begin
    if(blue) begin
      blue_check <= 1;
    end else if(btnl) begin
      blue_check <= 0;
    end
  end

  //VISUALIZATION  ----------------------------------------------
  //uart output
  uart #(
    .SW_WIRE_CNT(SW_WIRE_CNT),
    .RD_WIRE_CNT(RD_WIRE_CNT),
    .CLOCK_RATE('d65_000_000),
    .BAUD_RATE(BAUD_RATE)
  ) uart_output (
    .clk_in(clk_65mhz),
    .rst_in(sys_rst),
    .uart_active(uart_active_input),
    .truncate(uart_truncate_input),
    .data_in(uart_bram_data_out),

    .read_addr(uart_read_addr_req),
    .uart_output(uart_rxd_out)
  );

  //User inputs for data output size to VGA monitor
  //Extract data from bram
  data_req #(
    .SW_WIRE_CNT(SW_WIRE_CNT),
    .RD_WIRE_CNT(RD_WIRE_CNT),
    .HORIZONTAL_PIXEL('d1024),
    .VERTICAL_PIXEL('d768)
  ) bram_read (
    .clk_in(clk_65mhz),
    .rst_in(sys_rst),
    .scale_in(scale_input),
    .mirror_in(mirror_input),
    .hcount_in(hcount),
    .vcount_in(vcount),
    .addr_out(vis_read_addr_req)
  );

  logic [11:0] vis_data;
  //Visualizer with rgb gradient logic
  visualizer #(
    .SW_WIRE_CNT(SW_WIRE_CNT),
    .RD_WIRE_CNT(RD_WIRE_CNT),
    .DATA_THRESH_HIGH('d4095),
    .DATA_THRESH_LOW('d0)
  ) vga_out (
    .clk(clk_65mhz),
    .rst(sys_rst),
    .data_in(scaled_data),
    .data_out(vis_data)
  );

  logic [11:0] mux_data;
  vga_mux vga_options (
    .data_in(vis_data),
    .mask_on(mask_on_input),
    .mask_in(mask),
    .blue_on(blue_on_input),
    .blue_in(blue),
    .crosshair_on(crosshair_on_input),
    .crosshair_in(crosshair),
    .data_out(mux_data)
  );

  //Video Pipeline, Blanking Logic
  logic blank1, blank2; //latency 1 cycle
  always_ff @(posedge clk_65mhz)begin
    vga_r <= ~blank2?mux_data[11:8]:0;
    vga_g <= ~blank2?mux_data[7:4]:0;
    vga_b <= ~blank2?mux_data[3:0]:0;
  end
  logic hsync1, hsync2, hsync3;
  logic vsync1, vsync2, vsync3;
  always@(posedge clk_65mhz) begin
    hsync1 <= hsync;
    hsync2 <= hsync1;
    hsync3 <= hsync2;

    vsync1 <= vsync;
    vsync2 <= vsync1;
    vsync3 <= vsync2;

    blank1 <= blank;
    blank2 <= blank1;
  end
  assign vga_hs = ~hsync3;
  assign vga_vs = ~vsync3;

endmodule

`default_nettype wire

`default_nettype none
`timescale 1ns / 1ps

//Reads buttons and uses seven segment to allow for user inputs
module threshold_input #(
  parameter DATA_THRESH_LOW = 0,
  parameter DATA_THRESH_HIGH = 'd4095
)(
  input wire clk_in,
  input wire rst_in,

  //User settingss
  input wire btnu, btnd, btnl, btnr, //buttons
  input wire threshold_lowhi, //Switches: 0 is low, 1 is high 
  output wire [6:0] cat_out,
  output wire [7:0] an_out,

  //Data
  output logic [11:0] lower_bound_out,
  output logic [11:0] upper_bound_out
  //output logic mask_out
);
  logic [11:0] lower_bound, upper_bound;
  assign lower_bound_out = lower_bound;
  assign upper_bound_out = upper_bound;

  logic lower_active, upper_active;
  assign lower_active = ~threshold_lowhi;
  assign upper_active = threshold_lowhi;
  button_counter #(
    .START_VAL(DATA_THRESH_LOW)
  ) lower_counter (
    .clk_in(clk_in),
    .rst_in(rst_in),
    .btnu(btnu), .btnd(btnd), .btnl(btnl), .btnr(btnr),
    .count_active(lower_active),
    .thresh_value_out(lower_bound)
  );
  button_counter #(
    .START_VAL(DATA_THRESH_HIGH)
  ) upper_counter (
    .clk_in(clk_in),
    .rst_in(rst_in),
    .btnu(btnu), .btnd(btnd), .btnl(btnl), .btnr(btnr),
    .count_active(upper_active),
    .thresh_value_out(upper_bound)
  );

  seven_segment_controller #(
    .COUNT_TO(16'd4096)
  )seven_seg (
    .clk_in(clk_in),
    .rst_in(rst_in),
    .val_in({4'b0, upper_bound, 4'b0 , lower_bound}),
    .cat_out(cat_out),
    .an_out(an_out)
  );

endmodule

module button_counter #(
    parameter START_VAL = 'd0
  )(
    input wire clk_in,
    input wire rst_in,
    input wire btnu, btnd, btnl, btnr,
    input wire count_active,

    output wire [11:0] thresh_value_out
    );

    logic btnu_pulse;
    logic btnd_pulse;
    logic btnl_pulse;
    logic btnr_pulse;
    pulse_tracker btnu_pulse_t (
        .clk_in(clk_in),
        .rst_in(rst_in),
        .signal_in(btnu),
        .signal_out(btnu_pulse));
    pulse_tracker btnd_pulse_t (
        .clk_in(clk_in),
        .rst_in(rst_in),
        .signal_in(btnd),
        .signal_out(btnd_pulse));
    pulse_tracker btnl_pulse_t (
        .clk_in(clk_in),
        .rst_in(rst_in),
        .signal_in(btnl),
        .signal_out(btnl_pulse));
    pulse_tracker btnr_pulse_t (
        .clk_in(clk_in),
        .rst_in(rst_in),
        .signal_in(btnr),
        .signal_out(btnr_pulse));

    logic [1:0] nibble_count; //Counts 2, 1, 0
    logic [12:0] thresh_value; //Stores the total number
    assign thresh_value_out = thresh_value;

    logic add_pulse, sub_pulse;
    assign add_pulse = count_active && btnl_pulse;
    assign sub_pulse = count_active && btnr_pulse;
    //The state machine for the hex didget that you are in
    simple_counter #(
      .MAX_COUNT(3),
      .START_VAL(0)
    ) nibble_counter (
        .clk_in(clk_in),
        .rst_in(rst_in),
        .add_evt_in(add_pulse),
        .sub_evt_in(sub_pulse),
        .count_out(nibble_count)
    );

    logic add_pulse_0, sub_pulse_0;
    logic add_pulse_1, sub_pulse_1;
    logic add_pulse_2, sub_pulse_2;
    assign add_pulse_0 = (nibble_count == 2'b00) && count_active && btnu_pulse;
    assign sub_pulse_0 = (nibble_count == 2'b00) && count_active && btnd_pulse;
    assign add_pulse_1 = (nibble_count == 2'b01) && count_active && btnu_pulse;
    assign sub_pulse_1 = (nibble_count == 2'b01) && count_active && btnd_pulse;
    assign add_pulse_2 = (nibble_count == 2'b10) && count_active && btnu_pulse;
    assign sub_pulse_2 = (nibble_count == 2'b10) && count_active && btnd_pulse;

    //If the hex dig is selected, then only change that one if a button is pressed
    //warning that the START_VAL parameter is a bit scuffed
    //because its technically just truncated to fill in a bunch of 1s
    simple_counter #(
      .MAX_COUNT('d16),
      .START_VAL(START_VAL)
    ) nibble_0 (
        .clk_in(clk_in),
        .rst_in(rst_in),
        .add_evt_in(add_pulse_0),
        .sub_evt_in(sub_pulse_0),
        .count_out(thresh_value[3:0])
    );
    simple_counter #(
      .MAX_COUNT('d16),
      .START_VAL(START_VAL)
    ) nibble_1 (
        .clk_in(clk_in),
        .rst_in(rst_in),
        .add_evt_in(add_pulse_1),
        .sub_evt_in(sub_pulse_1),
        .count_out(thresh_value[7:4])
    );
    simple_counter #(
      .MAX_COUNT(16),
      .START_VAL(START_VAL)
    ) nibble_2 (
        .clk_in(clk_in),
        .rst_in(rst_in),
        .add_evt_in(add_pulse_2),
        .sub_evt_in(sub_pulse_2),
        .count_out(thresh_value[11:8])
    );
endmodule

module simple_counter #(
    parameter MAX_COUNT = 'd16,
    parameter START_VAL = 'd0
    )(  
    input wire          clk_in,
    input wire          rst_in,
    input wire          add_evt_in,
    input wire          sub_evt_in,
    output logic [$clog2(MAX_COUNT)-1:0] count_out
    );

    logic [$clog2(MAX_COUNT)-1:0] internal_count;
    assign count_out = internal_count;

    initial begin
        internal_count = START_VAL;
    end

    always_ff @(posedge clk_in) begin
        if (rst_in) begin
            internal_count <= START_VAL;
        end else begin
            if (add_evt_in) begin
                internal_count <= internal_count + 'b1;
                if (internal_count + 'b1 == MAX_COUNT) begin
                  internal_count <= 0;
                end
            end else if (sub_evt_in) begin
                internal_count <= internal_count - 'b1;
                if (internal_count == 'b0) begin
                  internal_count <= MAX_COUNT - 'b1;
                end
            end else begin
                internal_count <= internal_count;
            end
        end
    end
endmodule

module pulse_tracker (
    input wire clk_in,
    input wire rst_in,
    input wire signal_in,
    output logic signal_out
    );
    logic signal_past;

    always_ff @(posedge clk_in) begin 
      if (rst_in) begin
        signal_past <= 0;
        signal_out <= 0;
      end else begin
        if ((signal_past == 0) && (signal_in == 1)) begin
            signal_out <= 1; //is a rising edge
        end else begin 
            signal_out <= 0;
        end
        signal_past <= signal_in;
      end
    end
endmodule

module seven_segment_controller #(parameter COUNT_TO = 'd100_000)
                        (input wire         clk_in,
                         input wire         rst_in,
                         input wire [31:0]  val_in,
                         output logic[6:0]   cat_out,
                         output logic[7:0]   an_out
                        );
  logic [7:0]	segment_state; //which of the numbers you are on
  logic [31:0]	segment_counter; 
  logic [3:0]	routed_vals;
  logic [6:0]	led_out;
  /* TODO: wire up routed_vals (-> x_in) with your input, val_in
   * Note that x_in is a 4 bit input, and val_in is 32 bits wide
   * Adjust accordingly, based on what you know re. which digits
   * are displayed when...
   */

  always_comb begin
      case (segment_state)
          8'b0000_0001 : routed_vals = val_in[3:0];
          8'b0000_0010 : routed_vals = val_in[7:4];
          8'b0000_0100 : routed_vals = val_in[11:8];
          8'b0000_1000 : routed_vals = val_in[15:12];
          8'b0001_0000 : routed_vals = val_in[19:16];
          8'b0010_0000 : routed_vals = val_in[23:20];
          8'b0100_0000 : routed_vals = val_in[27:24];
          8'b1000_0000 : routed_vals = val_in[31:28];
          default : routed_vals= 4'b0000;
      endcase
  end
   

  bto7s mbto7s (.x_in(routed_vals), .s_out(led_out));
  assign cat_out = ~led_out; //<--note this inversion is needed
  assign an_out = ~segment_state; //note this inversion is needed
  always_ff @(posedge clk_in)begin
    if (rst_in)begin
      segment_state <= 8'b0000_0001;
      segment_counter <= 32'b0;
    end else begin
      if (segment_counter == COUNT_TO) begin
        segment_counter <= 32'd0;
        segment_state <= {segment_state[6:0],segment_state[7]};
    	end else begin
    	  segment_counter <= segment_counter +1;
    	end
    end
  end
endmodule // seven_segment_controller

/* TODO: drop your bto7s module from lab 1 here! */
module bto7s(input wire [3:0]   x_in,output logic [6:0] s_out);
        // array of bits that are "one hot" with numbers 0 through 15
        logic [15:0] num;
        assign num[0] = ~x_in[3] && ~x_in[2] && ~x_in[1] && ~x_in[0];
        assign num[1] = ~x_in[3] && ~x_in[2] && ~x_in[1] && x_in[0];
        assign num[2] = x_in == 4'd2;
        assign num[3] = x_in == 4'd3;
        assign num[4] = x_in == 4'd4;
        assign num[5] = x_in == 4'd5;
        assign num[6] = x_in == 4'd6;
        assign num[7] = x_in == 4'd7;
        assign num[8] = x_in == 4'd8;
        assign num[9] = x_in == 4'd9;
        assign num[10] = x_in == 4'd10;
        assign num[11] = x_in == 4'd11;
        assign num[12] = x_in == 4'd12;
        assign num[13] = x_in == 4'd13;
        assign num[14] = x_in == 4'd14;
        assign num[15] = x_in == 4'd15;

        assign s_out[0] = ~(num[1] || num[4] || num[11] || num[13]);
        assign s_out[1] = ~(num[5] || num[6] || num[11] || num[12] || num[14] || num[15] );
        assign s_out[2] = ~(num[2] || num[12] || num[14] || num[15]);
        assign s_out[3] = ~(num[1] || num[4] || num[7] || num[10] || num[15]);
        assign s_out[4] = (num[0] || num[2] || num[6] || num[8] || num[10] || num[11] || num[12] || num[13] || num[14] || num[15]);
        assign s_out[5] = (num[0] || num[4] || num[5] || num[6] || num[8] || num[9] || num[10] || num[11] || num[12] || num[14] || num[15]);
        assign s_out[6] = (num[2] || num[3] || num[4] || num[5] || num[6] || num[8] || num[9] || num[10] || num[11] || num[13] || num[14] || num[15]);
endmodule // bto7s

`default_nettype wire


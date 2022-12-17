`timescale 1ns / 1ps
`default_nettype none

//yoinked from lab 4b

module center_of_mass (
                         input wire clk_in,
                         input wire rst_in,
                         input wire [10:0] x_in,
                         input wire [9:0]  y_in,
                         input wire valid_in,
                         input wire tabulate_in,
                         output logic [10:0] x_out,
                         output logic [9:0] y_out,
                         output logic valid_out);

  localparam SUMMING = 0;
  localparam DIVIDE_WAIT = 1;
  localparam END_FRAME = 2;
  logic [1:0] state;

  //using default size of dividier
  logic [31:0] x_sum, x_divisor;
  logic [31:0] y_sum, y_divisor;
  logic divide_flag, send_to_divide;
  logic x_ready_cycle, y_ready_cycle;

  logic [31:0] x_divide_q, x_r;
  logic x_ready, x_error, x_busy;
  divider #(.WIDTH(32)) x_divide (.clk_in(clk_in), .rst_in(rst_in),
              .dividend_in(x_sum), .divisor_in(x_divisor), .data_valid_in(send_to_divide),
              .quotient_out(x_divide_q), .remainder_out(x_r),
              .data_valid_out(x_ready), .error_out(x_error), .busy_out(x_busy));

  logic [31:0] y_divide_q, y_r;
  logic y_ready, y_error, y_busy;
  divider #(.WIDTH(32)) y_divide (.clk_in(clk_in), .rst_in(rst_in),
              .dividend_in(y_sum), .divisor_in(y_divisor), .data_valid_in(send_to_divide),
              .quotient_out(y_divide_q), .remainder_out(y_r),
              .data_valid_out(y_ready), .error_out(y_error), .busy_out(y_busy));

  always_ff @(posedge clk_in) begin
    if (rst_in) begin
      state <= SUMMING;
      x_sum <= 0;
      y_sum <= 0;
      x_divisor <= 0;
      y_divisor <= 0;
      x_ready_cycle <= 0;
      y_ready_cycle <= 0;
      x_out <= 11'b0;
      y_out <= 10'b0;
      valid_out <= 1'b0;
      divide_flag <= 0;
      send_to_divide <= 0;
    end else begin
      case(state)

        SUMMING: begin
          if (valid_in && !divide_flag) begin
              if (x_in > 0) begin
                x_sum <= x_sum + x_in;
                x_divisor <= x_divisor + 32'b1;
              end
              if (y_in > 0) begin
                y_sum <= y_sum + y_in;
                y_divisor <= y_divisor + 32'b1;
              end
          end else if ((tabulate_in || divide_flag) && (x_divisor > 32'b0) && (y_divisor > 32'b0)) begin 
            //x_divide and y_divide modules get the signal to divide
            if (~x_busy && ~y_busy) begin
              send_to_divide <= 1'b1;
              divide_flag <= 1'b0;
              state <= DIVIDE_WAIT; 
            end else divide_flag <= 1'b1;
          end
        end

        DIVIDE_WAIT: begin
          send_to_divide <= 1'b0;
          if (x_ready) x_ready_cycle <= 1;
          if (y_ready) y_ready_cycle <= 1;

          if (x_ready_cycle && y_ready_cycle) begin //both divisions are completed
            if (x_error || y_error) begin
              valid_out <= 1'b0; //no valid data
            end else begin
              x_out <= x_divide_q[10:0];
              y_out <= y_divide_q[9:0];
              valid_out <= 1'b1;
            end
            state <= END_FRAME;
          end
        end

        END_FRAME: begin
          x_ready_cycle <= 0;
          y_ready_cycle <= 0;
          x_sum <= 0;
          y_sum <= 0;
          x_divisor <= 0;
          y_divisor <= 0;
          valid_out <= 1'b0;
          divide_flag <= 0;
          send_to_divide <= 0;
          state <= SUMMING;
        end

      endcase
    end
  end
endmodule

//given in lab 4b
module divider #(parameter WIDTH = 32) (input wire clk_in,
                input wire rst_in,
                input wire[WIDTH-1:0] dividend_in,
                input wire[WIDTH-1:0] divisor_in,
                input wire data_valid_in,
                output logic[WIDTH-1:0] quotient_out,
                output logic[WIDTH-1:0] remainder_out,
                output logic data_valid_out,
                output logic error_out,
                output logic busy_out);
  localparam RESTING = 0;
  localparam DIVIDING = 1;
  logic [WIDTH-1:0] quotient, dividend;
  logic [WIDTH-1:0] divisor;
  logic state;
  always_ff @(posedge clk_in)begin
    if (rst_in)begin
      quotient <= 0;
      dividend <= 0;
      divisor <= 0;
      remainder_out <= 0;
      busy_out <= 1'b0;
      error_out <= 1'b0;
      state <= RESTING;
      data_valid_out <= 1'b0;
    end else begin
      case (state)
        RESTING: begin
          if (data_valid_in)begin
            state <= DIVIDING;
            quotient <= 0;
            dividend <= dividend_in;
            divisor <= divisor_in;
            busy_out <= 1'b1;
            error_out <= 1'b0;
          end
          data_valid_out <= 1'b0;
        end
        DIVIDING: begin
          if (dividend<=0)begin
            state <= RESTING; //similar to return statement
            remainder_out <= dividend;
            quotient_out <= quotient;
            busy_out <= 1'b0; //tell outside world i'm done
            error_out <= 1'b0;
            data_valid_out <= 1'b1; //good stuff!
          end else if (divisor==0)begin
            state <= RESTING;
            remainder_out <= 0;
            quotient_out <= 0;
            busy_out <= 1'b0; //tell outside world i'm done
            error_out <= 1'b1; //ERROR
            data_valid_out <= 1'b1; //valid ERROR
          end else if (dividend < divisor) begin
            state <= RESTING;
            remainder_out <= dividend;
            quotient_out <= quotient;
            busy_out <= 1'b0;
            error_out <= 1'b0;
            data_valid_out <= 1'b1; //good stuff!
          end else begin
            //state staying in.
            state <= DIVIDING;
            quotient <= quotient + 1'b1;
            dividend <= dividend-divisor;
          end
        end
      endcase
    end
  end
endmodule

`default_nettype wire
`timescale 1ns / 1ps
`default_nettype none

module uart #(
        parameter SW_WIRE_CNT = 'd16, //Switching wire count
        parameter RD_WIRE_CNT = 'd16,  //Sampling/Read wire count
        parameter CLOCK_RATE = 'd65_000_000,
        parameter BAUD_RATE = 'd115_200 //aka pulses per second
    )(
        input wire clk_in,
        input wire rst_in,
        input wire uart_active,
        input wire truncate,
        input wire [11:0] data_in,

        output wire [$clog2(RD_WIRE_CNT * SW_WIRE_CNT)-1:0] read_addr,
        output wire uart_output
    );
    
    localparam NEW_FRAME_ID = 8'b0000_0000;

    logic uart_ready_past, pulse_uart;
    logic uart_ready, data_valid_in;
    logic pulse_sw, pulse_rd;
    logic newframe_pulse_rd;
    logic transmitter_output;
    logic [$clog2(SW_WIRE_CNT):0] sw_wire;
    logic [$clog2(RD_WIRE_CNT):0] rd_wire;
    localparam DATA_IN_MAX = 'd4096; //2**12
    localparam DATA_OUT_MAX = 'd256; //2**8
    logic [7:0] data_scaled, data_truncate, uart_data;

    //When UART has finished outputting the last of a value
    //Creates a UART pulse that counts pulse gen, and consequently changes the wires
    always_ff @(posedge clk_in) begin
        pulse_uart <= uart_ready && ~uart_ready_past && uart_active;
        uart_ready_past <= uart_ready;
    end
    pulse_gen #(
        .RD_WIRE_CNT(RD_WIRE_CNT),
        .SW_WIRE_CNT(SW_WIRE_CNT),
        .TSERIAL('d1),
        .TQUIET('d0)
    ) uart_pulse_gen (
        .clk_ref(clk_in),
        .rst(rst_in),
        .active_on(pulse_uart && ~new_frame),
        .pulse_sw(pulse_sw),
        .pulse_rd(pulse_rd)
    );
    //counts the wires, one cycle latency
    mux_select #(
      .SW_WIRE_CNT(SW_WIRE_CNT),
      .RD_WIRE_CNT(RD_WIRE_CNT)
    ) uart_wire_select (
      .clk_in(clk_in),
      .rst(rst_in),
      .pulse_sw(pulse_sw && ~new_frame),
      .pulse_rd((pulse_rd || newframe_pulse_rd) && ~new_frame),
      .sw_mux_sel(sw_wire),
      .rd_mux_sel(rd_wire)
    );
    
    localparam IDLE = 0;
    localparam NEWFRAME_SIG = 1;
    localparam READ00 = 2;
    logic [1:0] state;
    logic new_frame;
    always_ff @(posedge clk_in) begin
        if (rst_in) begin
            new_frame <= 1'b0;
            state <= IDLE;
        end else begin
            case (state)
                IDLE: begin
                    if ((sw_wire == '0 && rd_wire == '0) && pulse_uart) begin 
                        new_frame <= 1'b1;
                        state <= NEWFRAME_SIG;
                    end 
                end
                
                NEWFRAME_SIG: begin
                    if (new_frame && pulse_uart) begin 
                        new_frame <= 1'b0;
                        newframe_pulse_rd <= 1;
                        state <= READ00;
                    end
                end
                
                READ00: begin
                    newframe_pulse_rd <= 0;
                    state <= IDLE;
                end

            endcase
        end
    end

    //caculates address for bram request
    assign read_addr = rd_wire + RD_WIRE_CNT * sw_wire;
    //bram request, two cycle latency
    assign data_scaled = (data_in * DATA_OUT_MAX) / DATA_IN_MAX;
    assign data_truncate = data_in[11:4];
    
    //holds that will be ready by time to be pulled in
    assign data_valid_in = uart_ready; 
    
    //if a new frame, then send in the new frame buffer otherwise send in data
    assign uart_data = new_frame ? NEW_FRAME_ID : (truncate ? data_truncate : data_scaled);

    uart_transmit #(
        .CLOCK_RATE(CLOCK_RATE),
        .BAUD_RATE(BAUD_RATE)
    )transmitter (
        .clk_in(clk_in),
        .rst_in(rst_in),
        .data_in(uart_data),
        .data_valid_in(data_valid_in),
        .transmit_active(uart_active),
        .uart_ready(uart_ready),
        .data_out(transmitter_output)
    );

    assign uart_output = transmitter_output;

endmodule

module uart_transmit #(
    parameter CLOCK_RATE = 'd65000000,
    parameter BAUD_RATE = 'd115200 //aka pulses per second
    )(
    input wire clk_in,
    input wire rst_in,
    input wire [7:0] data_in,
    input wire data_valid_in,
    input wire transmit_active,
    output logic uart_ready,
    output logic data_out
    );

    logic [8:0] shift_buffer;
    localparam BAUD_MAX = CLOCK_RATE/BAUD_RATE;
    logic [$clog2(BAUD_MAX):0] baud_counter;
    logic [4:0] data_counter;

    always_ff @(posedge clk_in) begin
        if (rst_in) begin
            shift_buffer <= 10'b1_1111_1111;
            baud_counter <= 0;
            data_counter <= 0;
            data_out <= 1'b1;
            uart_ready <= 0;
        end else begin
            if (transmit_active) begin 
                if (baud_counter + 1'b1 == BAUD_MAX) begin 
                    data_out <= shift_buffer[0]; //output data lsb first
                    shift_buffer <= {1'b1, shift_buffer[8:1]};

                    //increment data counter
                    if (data_counter + 1'b1 == 'd10) begin
                        uart_ready <= 1'b1;
                        data_out <= 1'b1; //the "rest bit"
                        data_counter <= 'd9;
                        
                        if (data_valid_in) begin 
                            shift_buffer <= {data_in, 1'b0};
                            data_counter <= 1'd0; //reset
                            uart_ready <= 1'd0;
                        end
                    end else begin 
                        data_counter <= data_counter + 1'b1;
                    end

                    baud_counter <= 0; //end baud_counter
                end else begin
                    baud_counter <= baud_counter + 1'b1;
                end

            end else begin
                data_out <= 1'b1;
                baud_counter <= 1'b0;
                data_counter <= 1'b0;
                uart_ready <= 1'b0;
            end
        end
    end

endmodule

`default_nettype wire
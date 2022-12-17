
//reads in the values in serial from the ADC and outputs the entire read

`default_nettype none
`timescale 1ns / 1ps

module adc_read #(
        parameter ADC_TQUIET = 'd4
        ) (
        input wire clk,
        input wire rst,
        input wire data_in, //read in serial adc data
        input wire pulse_rd,
        output logic adc_cs_out, //output the cs signal
        output logic valid_out, //high after 16 of one adc value
        output logic error_out, //high if 4 leading 0s do not happen
        output logic [11:0] read_out); //12 bit value after 16 of one adc value

        logic [3:0] state;
        localparam WAITING = 0;
        localparam READING = 1;
        localparam PAUSE = 2;
        localparam ERROR = 3;
        logic [11:0] data;
        logic [$clog2(ADC_TQUIET):0] pulse_delay;
        logic [1:0] zero_count; //count to 4
        logic [4:0] data_count; //count to 12

        initial begin
            read_out = 0;
            state = PAUSE;
            adc_cs_out = 1;
            data = 0;
            pulse_delay = 0;
            zero_count = 0;
            data_count = 0;
            valid_out = 0;
            error_out = 0;
        end

        always_ff @(posedge clk) begin
            if (rst) begin
                read_out <= 0;
                state <= PAUSE;
                adc_cs_out <= 1;
                data <= 0;
                pulse_delay <= 0;
                zero_count <= 0;
                data_count <= 0;
                valid_out <= 0;
                error_out <= 0;
            end else begin
                case (state)
                    PAUSE: begin
                        read_out <= 0;
                        valid_out <= 0;
                        if (pulse_rd) pulse_delay <= 1;
                        else if (pulse_delay == 'd1) pulse_delay <= pulse_delay + 'd1;
                        else if (pulse_delay == 'd2) begin
                            pulse_delay <= 0;
                            state <= WAITING;
                            adc_cs_out <= 0;
                        end else adc_cs_out <= 1'b1;
                    end

                    WAITING: begin //Checking for 4 (actually 3) leading 0s
                        if (data_in == 0) begin
                            zero_count <= zero_count + 1'd1;
                            if (zero_count >= 3-1) begin
                                zero_count <= 0;
                                state <= READING;
                            end
                        end else begin
                            error_out <= 1;
                            state <= ERROR;
                        end
                    end

                    READING: begin //Reading out 12 bits of data
                        data_count <= data_count + 1'd1;
                        data <= {data[10:0], data_in};
                        if (data_count >= 11) begin
                            data_count <= 0;
                            state <= PAUSE;
                            read_out <= {data[10:0], data_in};
                            data <= 0;
                            valid_out <= 1'd1;
                        end
                    end

                    ERROR: begin //If the 4 leading 0s do not exist, means ADC is out of sync
                        read_out <= 0;
                        valid_out <= 0;
                        error_out <= 1'b1;
                        adc_cs_out <= 1'b1;
                        //stuck until reset
                    end
                endcase
            end
        end

endmodule

`default_nettype wire
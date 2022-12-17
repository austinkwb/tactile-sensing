`default_nettype none
`timescale 1ns / 1ps

module data_array #(
    parameter SW_WIRE_CNT = 'd16,
    parameter RD_WIRE_CNT = 'd16
    ) (
    input wire clk_write, //write clock
    input wire clk_read, //read clock
    input wire rst,
    //writing in from the ADC
    input wire [$clog2(SW_WIRE_CNT):0] sw_write_in,
    input wire [$clog2(RD_WIRE_CNT):0] rd_write_in,
    input wire [11:0] data_in,
    input wire data_valid_in,
    
    //reading out request
    input wire [$clog2(SW_WIRE_CNT * RD_WIRE_CNT)-1:0] read_addr,
    //reading out information
    output logic [11:0] data_out
    );

    logic [11:0] bram_data_out;

    // caculate write rom address
    logic [$clog2(SW_WIRE_CNT*RD_WIRE_CNT)-1:0] write_addr;
    assign write_addr = (rd_write_in) + (sw_write_in * SW_WIRE_CNT);

    logic [11:0] write_output; //don't need this value
    xilinx_true_dual_port_read_first_2_clock_ram #(
        .RAM_WIDTH('d12),                     // RAM data width- ADC Output
        .RAM_DEPTH(SW_WIRE_CNT * RD_WIRE_CNT),// RAM depth (number of entries)- Number of sensor points
        .RAM_PERFORMANCE("HIGH_PERFORMANCE"), // Select "HIGH_PERFORMANCE"
        .INIT_FILE("")                        // Specify name/location of RAM initialization file if using one (leave blank if not)
        ) storage_array (
        //port a: write in values
        .addra(write_addr),
        .dina(data_in),
        .clka(clk_write),
        .wea(data_valid_in),
        .ena(1'b1),
        .rsta(rst),
        .regcea(1'b0), //disable output
        .douta(write_output), //disable output

        //port b: read out values
        .addrb(read_addr),  // Port B address bus, width determined from RAM_DEPTH
        .dinb(11'b0), //disable input
        .clkb(clk_read),
        .web(1'b0), //disable input
        .enb(1'b1),
        .rstb(rst),
        .regceb(1'b1),
        .doutb(bram_data_out)
        );

    always_ff @(posedge clk_read) begin
        data_out <= bram_data_out;
    end

endmodule

`default_nettype wire
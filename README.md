# tactile-sensing

A pressure tactile sensor reading and visulization program.
Reads off a piezoresitive embrodiered array designed in the The Computational Design & Fabrication Group (CDFG) in CSAIL.

Written by Tiffany Louie (tklouie) and Austin White (akwb) for 6.111 Fall 2022
Thank you to our project advisor Joe Steinmeyer, and class TAs Fisher and Jay. Also thank you to Michael Foshey and Yiyue Luo in CDFG lab.

## Electronic Connections
FPGA: Digilent Nexys A7

VGA:
* Connect to VGA display

LEDs:
* 0 ADC signal is alined
* 1 ADC is aligned and sending out valid signal if on
* 2 ADC is sending out valid signal aligned to clk_rd

Seven Segment:
* Top 4 are the upper threshold
* Bottom 4 are the lower threshold

Swiches:
* sw[1:0] are for display scale
* sw[2] is for mirroring
* sw[3] is whether user controls top or bottom threshold
* sw[4:6] is the convolution filter

* sw[11] is crosshair display on
* sw[12] threshold mask (black screen) display on
* sw[13] motion tracking (blue) display on
* sw[14] uart control: scale or bottom values
* sw[15] uart communication on

Buttons:
* btnc is reset
* btnu/btnd controls numbers increasing or decreasing
* btnl/bntr controls which nibble (sig fig) of the threshold user is controlling

Wires:
* JB: Swithcing wires control (S0-S4 of switching mux)
* JD: Reading wire control (S0-S4 of reading mux)
* JC: ADC readout

UART:
* Can communicate through UART on connected computer, run python script **fpga_tactile.py** for heat map visulization 

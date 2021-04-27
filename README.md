# UART Communication Protocol Verilog Implemetation

## About 

This is a repository for UART protocol's hardware implementation.
Kindly feel free to look around and suggest changes as well.

## Usage

Firstly you will need `iverilog` or an equivalent tool to verify it's working.
To view waveform, kindly use `gtkwave`.

Steps to view the output:

+ Launch terminal and clone the repository into your local system.
+ `cd` into the directory.
+ Type the following command `iverilog -o uart tb_uart.v uart.v`.
+ Once the above command is executed, run `vvp uart`.
+ This should display the output on the terminal window.
+ To view waveform, run `gtkwave tb_uart.vcd`

## UART Protocol Basics

(Will update README soon with images and a satisfying explanation)

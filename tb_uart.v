`timescale 1ns/1ps
module tb_uart_rx();
    // Common
    reg reset_;

    // for Rx
    wire [7:0] rx_datareg;
    wire error1, error2;
    wire rx_handshake; //read_not_ready_out
    reg sample_clk;
    reg host_not_ready; // read_not_ready_in

    // for Tx
    reg [7:0] data_bus;
    reg t_byte;
    reg ld_tx_datareg;
    reg clk;
    reg byte_ready;
    wire serial_out;

    uart_tx TX(
        .data_bus(data_bus),
        .byte_ready(byte_ready),
        .ld_tx_datareg(ld_tx_datareg),
        .clk(clk), .reset_(reset_),
        .serial_out(serial_out),
        .t_byte(t_byte)
    );

    uart_rx RX(
        .rx_datareg(rx_datareg),
        .error1(error1),
        .error2(error2),
        .rx_handshake(rx_handshake),
        .serial_in(serial_out),
        .sample_clk(sample_clk),
        .reset_(reset_),
        .host_not_ready(host_not_ready)
    );

    // Clock at Tx
    initial
    begin
        clk = 1'b0;
    end
    always
    begin
        #5 clk = ~clk;
    end

    // Clock at Rx
    // The frequency is 8 times that of the Tx to sample effectively
    initial
    begin
        sample_clk = 1'b0;
    end
    always
    begin
        #0.625 sample_clk = ~sample_clk;
    end

    initial
    begin
        $dumpfile("uart_rx.vcd");
        $dumpvars(0, tb_uart_rx);
    end

    initial
    begin
        $monitor($time, " Serial input = %x | Clock = %x | Reset = %x | Output = %x", data_bus, sample_clk, reset_, rx_datareg);
    end

    initial
    begin
        #1 reset_ = 1'b0;
        #3 reset_ = 1'b1;
        host_not_ready = 1'b0;

        // Set up Tx, and start sending
        data_bus = 8'haa;
        ld_tx_datareg = 1'b1;
        #10 byte_ready = 1'b1;
        #10 t_byte = 1'b1;

        #200 $finish;
    end
endmodule
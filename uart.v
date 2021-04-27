module uart_tx(
    input [7:0] data_bus,
    input byte_ready,
    input ld_tx_datareg,
    input t_byte,
    input clk,
    input reset_,
    output serial_out
);

    reg [7:0] tx_datareg;
    reg [8:0] tx_shiftreg;
    reg ld_tx_shiftreg;
    reg [2:0] state, next_state;
    reg [2:0] bit_count;
    reg clr;
    reg shift;
    reg start;

    parameter idle = 3'b001;
    parameter waiting = 3'b010;
    parameter sending = 3'b100;
    parameter all_ones = 9'b111111111;

    assign serial_out = tx_shiftreg[0]; //Output is LSB of shift register

    always @ (state or bit_count or t_byte or byte_ready)
    begin
        ld_tx_shiftreg = 0;
        clr = 0;
        shift = 0;
        start = 0;
        next_state = state;

        case(state)
            idle:
                if(byte_ready == 1)
                begin
                    ld_tx_shiftreg = 1;
                    next_state = waiting;
                end

            waiting:
                if(t_byte == 1)
                begin
                    start = 1;
                    next_state = sending;
                end

            sending:
                if(bit_count != 9)
                    shift = 1;
                else
                begin
                    clr = 1;
                    next_state = idle;
                end

            default: next_state = idle;
        endcase
    end

    always @ (posedge clk or negedge reset_)
    begin
        if(reset_ == 0)
            state <= idle;
        else
            state <= next_state;
    end

    always @ (posedge clk or negedge reset_)
    begin
        if(reset_ == 0)
        begin
            tx_shiftreg <= all_ones;
            bit_count <= 0; end
        else
        begin
            if(ld_tx_datareg == 1)
                tx_datareg <= data_bus;

            if(ld_tx_shiftreg == 1)
                tx_shiftreg <= {tx_datareg, 1'b1};

            if(start == 1)
                tx_shiftreg[0] <= 0;

            if(clr == 1)
                bit_count <= 0;

            else if(shift == 1)
                bit_count <= bit_count+1;

            if(shift == 1)
                tx_shiftreg <= {1'b1, tx_shiftreg[8:1]};
        end
    end
endmodule

module uart_rx(
    output reg [7:0] rx_datareg,
    output reg error1, error2,
    output rx_handshake, // read_not_ready_out
    input serial_in,
    input sample_clk,
    input reset_,
    input host_not_ready // read_not_ready_in
);

    parameter idle = 2'b00;
    parameter starting = 2'b01;
    parameter receiving = 2'b11;

    reg [7:0] rx_shiftreg;
    reg [3:0] sample_counter;
    reg [4:0] bit_counter;
    reg [1:0] state, next_state;

    reg inc_bit_counter, clr_bit_counter, inc_sample_counter, clr_sample_counter, shift, load, rx_handshake;

    always @(state or serial_in or host_not_ready or sample_counter or bit_counter)
    begin
        rx_handshake = 0;
        clr_sample_counter = 0;
        clr_bit_counter = 0;
        inc_sample_counter = 0;
        inc_bit_counter = 0;
        shift = 0;
        error1 = 0;
        error2 = 0;
        load = 0;
        next_state = state;

        case (state)
            idle: if(serial_in == 0) next_state = starting;

            starting:
                begin
                    if(serial_in == 1)
                    begin
                        next_state = idle;
                        clr_sample_counter = 1;
                    end
                    else if(sample_counter == 3) // Check if sample_counter == half_word - 1 (half_word = word_size/2 = 8/2 = 4) = 3
                    begin
                        next_state = receiving;
                        clr_sample_counter = 1;
                    end
                    else inc_sample_counter = 1;
                end
            receiving:
                begin
                    if(sample_counter < 7) // word_size - 1
                    begin
                        inc_sample_counter = 1;
                    end
                    else
                    begin
                       clr_sample_counter = 1;
                       if(bit_counter != 8)
                       begin
                           shift = 1;
                           inc_bit_counter = 1;
                       end
                       else
                       begin
                           next_state = idle;
                           rx_handshake = 1;
                           clr_bit_counter = 1;
                           if(host_not_ready == 1)
                                error1 = 1;
                           else if(serial_in == 0)
                                error2 = 1;
                           else
                               load = 1;
                       end
                    end
                end
            default: next_state = idle;
        endcase
    end

    // State transitions and register transfers

    always @ (posedge sample_clk)
    begin
        if(reset_ == 0)
        begin
            state <= idle;
            sample_counter <= 0;
            bit_counter <= 0;
            rx_datareg <= 0;
            rx_shiftreg <= 0;
        end

        else begin
            state <= next_state;

            if(clr_sample_counter == 1)
                sample_counter <= 0;
            else if(inc_sample_counter == 1)
                sample_counter <= sample_counter + 1;

            if(clr_bit_counter == 1)
                bit_counter <= 0;
            else if(inc_bit_counter == 1)
                bit_counter <= bit_counter + 1;

            if(shift == 1)
                rx_shiftreg <= {serial_in, rx_shiftreg[7:1]};
            if(load == 1)
                rx_datareg <= rx_shiftreg;
        end
    end
endmodule
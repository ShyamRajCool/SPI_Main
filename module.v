`timescale 1 ns / 100 ps

//A BCD counter is needed to divide the clk in to the clk out (should be put within spi_main) (done)

module spi_main(
                input[7:0] MISO, //Main in subnode out
                input[7:0] POMI, //primary out main in (the value that will be used for MOSI)

                input
                reset,
                clk_in, //(resolved)
                data_in, //works as both start and checking for next
                CPOL, 
                CPHA, 

                output reg [7:0] MOSI, //Main out subnode in
                output reg [7:0] PIMO, //primary in main out (transfers the value it received from MISO)
                
                output
                cs, //CS is toggled based on data_in
                done, //done is toggled after all pieces of MISO and POMI are sampled
                divider //clk divider (f/10)
);


    parameter[1:0] IDLE = 0, TRANSFER = 1, STOP = 2; 

    wire[3:0] clock_counter;
    
    reg[1:0] state, next_state;
    reg[3:0] sample_counter_pos; //Goes to 8
    reg[3:0] sample_counter_neg; //Goes to 8

    //This needs to be checked
    bcdcount divide10 (.clk(clk_in), .reset(reset), .q(clock_counter));
    assign divider = clock_counter == 9;


    always @ (*) begin
        case(state)
            IDLE: next_state = TRANSFER ? data_in : IDLE; 
            TRANSFER: next_state = TRANSFER ? (clock_counter == 4'd9) && ((data_in == 1'b1)): STOP;
            STOP: next_state = IDLE;
            default: next_state = IDLE;
        endcase
    end

    always @ (posedge clk_in) begin
        if (reset) begin
            state <= IDLE;
            MOSI <= {8{1'b0}}; //this part needs refinement
            PIMO <= {8{1'b0}};
        end
        else begin
            state <= next_state;
        end
    end

    always @ (posedge divider, posedge reset) begin
        if (reset) begin
            sample_counter_pos <= 4'h0;
        end
        else begin
            if (CPOL == 0 && CPHA == 0) begin
                PIMO[sample_counter_pos] <= MISO[sample_counter_pos];
                sample_counter_pos <= sample_counter_pos + 1'b1;
            end
            else if (CPOL == 0 && CPHA == 1) begin
                MOSI[sample_counter_pos] <= POMI[sample_counter_pos];
                sample_counter_pos <= sample_counter_pos + 1'b1;
            end
            else if (CPOL == 1 && CPHA == 0) begin
                MOSI[sample_counter_pos] <= POMI[sample_counter_pos];
                sample_counter_pos <= sample_counter_pos + 1'b1;
            end
            else if (CPOL == 1 && CPHA == 1) begin
                PIMO[sample_counter_pos] <= MISO[sample_counter_pos];
                sample_counter_pos <= sample_counter_pos + 1'b1;
            end
        end
    end

    always @ (negedge divider, posedge reset) begin  //Same as the last part, this also needs refinement; namely, the reset logic
            if (reset) begin
                sample_counter_neg <= 4'h0;
            end
            else begin
                if (CPOL == 0 && CPHA == 0) begin
                    MOSI[sample_counter_neg] <= POMI[sample_counter_neg];
                    sample_counter_neg <= sample_counter_neg + 1'b1;
                end
                else if (CPOL == 0 && CPHA == 1) begin
                    PIMO[sample_counter_neg] <= MISO[sample_counter_neg];
                    sample_counter_neg <= sample_counter_neg + 1'b1;
                end
                else if (CPOL == 1 && CPHA == 0) begin
                    PIMO[sample_counter_neg] <= MISO[sample_counter_neg];
                    sample_counter_neg <= sample_counter_neg + 1'b1;
                end
                else if (CPOL == 1 && CPHA == 1) begin
                    MOSI[sample_counter_neg] <= POMI[sample_counter_neg];
                    sample_counter_neg <= sample_counter_neg + 1'b1;
                end
            end
    end

    assign cs = ~(data_in);
    assign done = sample_counter_pos == 8 && sample_counter_neg == 8; //This makes sure that 8 samples were taken (it should have stopped at the 7 spot)

endmodule

//This is a counter for dividing the clock with frequency f by 10 (so the resulting frequency will be f/10)
module bcdcount(input clk, reset, 
                output reg [3:0] q
);
    always @ (posedge clk) begin //sync reset
        if (reset) begin
            q <= 4'b0000;
        end
        else begin
            if (q == 4'b1001) begin
                q <= 4'b0000;
            end
            else begin
                q <= q + 1'b1;
            end
        end
    end

endmodule

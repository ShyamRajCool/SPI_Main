`timescale 1ns / 100 ps

//A BCD counter is needed to divide the clk in to the clk out (should be put within spi_main)

module spi_main(
                input[7:0] MISO, 
                input[7:0] POMI, //primary out main in (the value that will be used ofr MOSI)

                input
                reset,
                clk_in, //this part may be wrong 
                data_in, //works as both start and checking for next
                CPOL, 
                CPHA, 

                output reg [7:0] MOSI,
                output reg [7:0] PIMO, //primary in main out (transfers the value it received from MISO)
                
                output
                cs,
                done, 
                divider
);


    parameter[1:0] IDLE = 0, TRANSFER = 1, STOP = 2; 

    wire[3:0] clock_counter;
    
    reg[1:0] state, next_state;
    reg[3:0] sample_counter; //Goes to 8

    bcdcount divide10 (.clk(clk_in), .reset(reset), .q(clock_counter));
    assign divider = clock_counter == 8;


    always @ (*) begin
        case(state)
            IDLE: next_state = TRANSFER ? data_in : IDLE;
            TRANSFER: next_state = TRANSFER ? (clock_counter == 4'd8) && ((data_in == 1'b1) && (~cs == 1'b1)): STOP;
            STOP: next_state = IDLE;
            default: next_state = IDLE;
        endcase
    end

    always @ (posedge clk_in) begin
        if (reset) begin
            state <= IDLE;
        end
        else begin
            state <= next_state;
        end
    end

    always @ (posedge divider) begin
        if (reset) begin
            sample_counter <= 4'h0;
        end
        else begin
            if (CPOL == 0 && CPHA == 0) begin
                PIMO[sample_counter] <= MISO[sample_counter];
                sample_counter <= sample_counter + 1'b1;
            end
            else if (CPOL == 0 && CPHA == 1) begin
                MOSI[sample_counter] <= POMI[sample_counter];
                sample_counter <= sample_counter + 1'b1;
            end
            else if (CPOL == 1 && CPHA == 0) begin
                MOSI[sample_counter] <= POMI[sample_counter];
                sample_counter <= sample_counter + 1'b1;
            end
            else if (CPOL == 1 && CPHA == 1) begin
                PIMO[sample_counter] <= MISO[sample_counter];
                sample_counter <= sample_counter + 1'b1;
            end
        end
    end

    always @ (negedge divider) begin
            if (reset) begin
                sample_counter <= 4'h0;
            end
            if (CPOL == 0 && CPHA == 0) begin
                MOSI[sample_counter] <= POMI[sample_counter];
                sample_counter <= sample_counter + 1'b1;
            end
            else if (CPOL == 0 && CPHA == 1) begin
                PIMO[sample_counter] <= MISO[sample_counter];
                sample_counter <= sample_counter + 1'b1;
            end
            else if (CPOL == 1 && CPHA == 0) begin
                PIMO[sample_counter] <= MISO[sample_counter];
                sample_counter <= sample_counter + 1'b1;
            end
            else if (CPOL == 1 && CPHA == 1) begin
                MOSI[sample_counter] <= POMI[sample_counter];
                sample_counter <= sample_counter + 1'b1;
            end
    end

    assign cs = ~((state == IDLE) && data_in);
    assign done = sample_counter == 8;

endmodule


module bcdcount(input clk, reset, 
                output reg [3:0] q
);

    always @ (posedge clk) begin //async reset
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

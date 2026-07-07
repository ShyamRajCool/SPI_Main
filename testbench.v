`timescale 1 ns / 100 ps

module tb_clock_gen;

    reg[7:0] input_MISO, input_POMI;
    reg reset, data_in, CPOL, CPHA;
    reg clk;

    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    wire[7:0] MOSI, PIMO;
    wire cs, done, divider;
    wire[3:0] clock_counter;

    spi_main uut(
        .MISO(input_MISO), 
        .POMI(input_POMI), 
        .reset(reset),
        .clk_in(clk),
        .data_in(data_in), 
        .CPOL(CPOL),
        .CPHA(CPHA),
        .MOSI(MOSI), 
        .PIMO(PIMO), 
        .cs(cs), 
        .done(done), 
        .divider(divider)
    );


    initial begin
        $dumpfile("output.vcd");
        $dumpvars(0, tb_clock_gen);

        reset = 1'b1;
        #10;

        reset = 1'b0;
        #10;
        data_in = 1'b1;
        CPOL = 1'b0;
        CPHA = 1'b0;

        input_MISO = 8'b10101011;
        input_POMI = 8'b11010011;

        #800
        $finish;

    end

endmodule

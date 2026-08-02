`timescale 1ns / 1ps

module tb_spi_slave ();
    logic clk, rst;
    logic [7:0] tx_data;
    logic [7:0] rx_data;
    logic busy, done;
    logic sclk, ss_n, mosi, miso;

    always #5 clk = ~clk;

    spi_slave #(
        .CPOL(0), 
        .CPHA(0)
    ) dut (
        .clk(clk), 
        .rst(rst),
        .tx_data(tx_data), 
        .rx_data(rx_data),
        .busy(busy), 
        .done(done),
        .sclk(sclk), 
        .ss_n(ss_n), 
        .mosi(mosi), 
        .miso(miso)
    );

    task send_bit_by_tb(input [7:0] mosi_val);
        integer i;
        begin
            ss_n = 1'b0;
            repeat(3) @(posedge clk); 
            #1; // HW driving timing

            for (i = 7; i >= 0; i = i - 1) begin
                mosi = mosi_val[i];
                @(posedge clk); 
                #1; 
                sclk = 1'b1;  
                @(posedge clk); 
                #1; 
                sclk = 1'b0;
            end

            @(posedge clk); 
            #1;
            ss_n = 1'b1;
            repeat(10) @(posedge clk);
        end
    endtask

    initial begin
        clk = 0; 
        rst = 1; 
        sclk = 0; 
        ss_n = 1; 
        mosi = 0;
        tx_data = 8'h00;
        #100; 
        rst = 0;
        repeat(10) @(posedge clk);

        $display(" Master -> Slave Data (Slave input data): 0x5A");
        tx_data = 8'h5A; 
        send_bit_by_tb(8'hFF); 

        repeat(20) @(posedge clk);
        $finish;
    end
endmodule
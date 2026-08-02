`timescale 1ns / 1ps

module spi_slave_top (
    input logic clk,
    input logic rst,

    input logic [7:0] slave_sw,  // slave input

    // SPI 
    input  logic sclk,
    input  logic ss_n,
    input  logic mosi,
    output logic miso,

    // slave FND
    output logic [3:0] fnd_com,
    output logic [7:0] fnd_data,

    // Monitoring
    output logic busy,
    output logic done
);

    logic [7:0] rx_data;
    logic [7:0] tx_data;    // result to send back to master via MISO (slave_sw + rx_data)
    logic w_done;           // 1-cycle pulse from spi_slave, rx_data / transfer - complete signal

    spi_slave #(
        .CPOL(0),
        .CPHA(0)
    ) U_SPI_SLAVE (
        .clk    (clk),
        .rst    (rst),
        .tx_data(tx_data),
        .sclk   (sclk),
        .ss_n   (ss_n),
        .mosi   (mosi),
        .miso   (miso),
        .rx_data(rx_data),
        .busy   (busy),
        .done   (w_done)
    );

    fnd_controller U_FND_SLAVE (
        .clk     (clk),
        .rst     (rst),
        .rx_data (rx_data),
        .done    (w_done),
        .fnd_com (fnd_com),
        .fnd_data(fnd_data)
    );

    // alu result Flip-Flop
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            tx_data <= 8'h00;
        end else if (w_done) begin
            tx_data <= slave_sw + rx_data;  // captures slave_sw at the moment Master's start triggers this transfer (w_done)
        end
    end

    // slave done signal display (toggle, for LED/monitoring)
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            done <= 1'b0;
        end else if (w_done) begin
            done <= ~done;
        end else begin
            done <= done;
        end
    end
endmodule

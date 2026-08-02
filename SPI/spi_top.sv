`timescale 1ns / 1ps

// simulation version top module
module spi_top (
    input logic clk,
    input logic rst,

    // SPI Master input
    input logic [7:0] master_sw,
    input logic       master_btn,
    // SPI Slave input
    input  logic [7:0] slave_sw,

    output logic [3:0] master_fnd_com,
    output logic [7:0] master_fnd_data,
    output logic       master_busy,
    output logic       master_done,
    
    output logic [3:0] slave_fnd_com,
    output logic [7:0] slave_fnd_data,
    output logic       slave_busy,
    output logic       slave_done
);
    logic sclk, mosi, miso, ss_n;

    spi_master_top U_MASTER_TOP (
        .clk      (clk),
        .rst      (rst),
        .master_sw(master_sw),
        .i_btn    (master_btn),
        .sclk     (sclk),
        .mosi     (mosi),
        .miso     (miso),
        .ss_n     (ss_n),
        .fnd_com  (master_fnd_com),
        .fnd_data (master_fnd_data),
        .busy     (master_busy),
        .done     (master_done)
    );

    spi_slave_top U_SLAVE_TOP (
        .clk     (clk),
        .rst     (rst),
        .slave_sw(slave_sw),
        .sclk    (sclk),
        .ss_n    (ss_n),
        .mosi    (mosi),
        .miso    (miso),
        .fnd_com (slave_fnd_com),
        .fnd_data(slave_fnd_data),
        .busy    (slave_busy),
        .done    (slave_done)
    );

endmodule

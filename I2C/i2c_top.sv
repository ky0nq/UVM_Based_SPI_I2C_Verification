`timescale 1ns / 1ps

module i2c_top (
    input  logic       clk,
    input  logic       rst,

    // Master control command
    input  logic [8:0] sw,          // sw[8] = slave address information , sw[7:0] = data
    input  logic       i_btn_write,
    input  logic       i_btn_read,

    // Slave FND display select (0 = Slave0, 1 = Slave1)
    input  logic       sw_fnd_sel,

    // Master FND
    output logic [3:0] master_fnd_com,
    output logic [7:0] master_fnd_data,

    // Slave FND
    output logic [3:0] slave_fnd_com,
    output logic [7:0] slave_fnd_data,

    // LED
    output logic       led_tx_addr_done,
    output logic       led_tx_data_done,
    output logic       led_rx_data_done,
    output logic       led_slave0_active,
    output logic       led_slave1_active,

    output wire        scl,
    inout  wire        sda
);
    pullup (sda);

    i2c_master_board U_MASTER (
        .clk             (clk),
        .rst             (rst),
        .sw              (sw),
        .i_btn_write     (i_btn_write),
        .i_btn_read      (i_btn_read),
        .fnd_com         (master_fnd_com),
        .fnd_data        (master_fnd_data),
        .led_tx_addr_done(led_tx_addr_done),
        .led_tx_data_done(led_tx_data_done),
        .led_rx_data_done(led_rx_data_done),
        .scl             (scl),
        .sda             (sda)
    );
    i2c_slave_board U_SLAVE (
        .clk              (clk),
        .rst              (rst),
        .sw_fnd_sel       (sw_fnd_sel),
        .fnd_com          (slave_fnd_com),
        .fnd_data         (slave_fnd_data),
        .led_slave0_active(led_slave0_active),
        .led_slave1_active(led_slave1_active),
        .scl              (scl),
        .sda              (sda)
    );
endmodule
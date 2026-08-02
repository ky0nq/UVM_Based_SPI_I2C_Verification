`timescale 1ns / 1ps
 
module i2c_slave_board (
    input  logic       clk,
    input  logic       rst,
    input  logic       sw_fnd_sel,     // 0 = Slave0 display | 1 = Slave1 display
    output logic [3:0] fnd_com,
    output logic [7:0] fnd_data,
    output logic       led_slave0_active,
    output logic       led_slave1_active,
 
    input  wire        scl,
    inout  wire        sda
);
 
    // ========================================
    // Slave_0 (Slave Address 7'h10)
    // ========================================
    logic [7:0] s0_rx_data;
    logic       s0_rx_valid;
    logic [7:0] s0_tx_data;
    logic [7:0] s0_rx_latch;
 
    i2c_slave_top U_SLAVE_0 (
        .clk       (clk),
        .rst       (rst),
        .slave_addr(7'h10),
        .tx_data   (s0_tx_data),
        .rx_data   (s0_rx_data),
        .rx_valid  (s0_rx_valid),
        .busy      (),
        .scl       (scl),
        .sda       (sda)
    );
 
    // write data -> read data : loopback structure
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            s0_tx_data <= 8'h00;
        end
        else if (s0_rx_valid) begin
            s0_tx_data <= s0_rx_data;
        end
    end
 
    // display rx data capture
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin 
            s0_rx_latch <= 8'h00;
        end
        else if (s0_rx_valid) begin
            s0_rx_latch <= s0_rx_data;
        end
    end
 
    // ========================================
    // Slave_1 (Slave Address 7'h20)
    // ========================================
    logic [7:0] s1_rx_data;
    logic       s1_rx_valid;
    logic [7:0] s1_tx_data;
    logic [7:0] s1_rx_latch;
 
    i2c_slave_top U_SLAVE_1 (
        .clk       (clk),
        .rst       (rst),
        .slave_addr(7'h20),
        .tx_data   (s1_tx_data),
        .rx_data   (s1_rx_data),
        .rx_valid  (s1_rx_valid),
        .busy      (),
        .scl       (scl),
        .sda       (sda)
    );
 
    // write data -> read data : loopback structure
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            s1_tx_data <= 8'h00;
        end else if (s1_rx_valid) begin
            s1_tx_data <= s1_rx_data;
        end
    end
 
    // display rx data capture
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            s1_rx_latch <= 8'h00;
        end else if (s1_rx_valid) begin
            s1_rx_latch <= s1_rx_data;
        end
    end
 
    // display data converter (slave0 or slave1)
    logic [7:0] fnd_rx_data;
    always_comb begin
        fnd_rx_data = sw_fnd_sel ? s1_rx_latch : s0_rx_latch;
    end
 
    fnd_controller U_FND_SLAVE (
        .clk     (clk),
        .rst     (rst),
        .rx_data (fnd_rx_data),
        .done    (1'b1),
        .fnd_com (fnd_com),
        .fnd_data(fnd_data)
    );
 
    // slave selection information display
    // LED 15 (slave0 select -> LED ON) | LED 14 (slave1 select -> LED ON)
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            led_slave0_active <= 1'b0;
            led_slave1_active <= 1'b0;
        end else if (s0_rx_valid) begin
            led_slave0_active <= 1'b1;
            led_slave1_active <= 1'b0;
        end else if (s1_rx_valid) begin
            led_slave0_active <= 1'b0;
            led_slave1_active <= 1'b1;
        end
    end
endmodule
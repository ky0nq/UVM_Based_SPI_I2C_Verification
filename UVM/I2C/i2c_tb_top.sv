`timescale 1ns / 1ps
import uvm_pkg::*;
import i2c_pkg::*;

module i2c_tb_top();

    logic clk, rst;
    always #5 clk = ~clk;

    initial begin
        clk = 0;
        rst = 1;
        repeat(4) @(posedge clk);
        rst = 0;
    end

    i2c_if i_if(.clk(clk), .rst(rst));
    pullup (i_if.sda);

    logic [7:0] s0_rx_data, s1_rx_data;
    logic       s0_rx_valid, s1_rx_valid;
    logic       s0_busy,     s1_busy;

    i2c_master_top #(.DIV_MAX(4)) U_MASTER (
        .clk      (clk),
        .rst      (rst),
        .cmd_start(i_if.cmd_start),
        .cmd_write(i_if.cmd_write),
        .cmd_read (i_if.cmd_read),
        .cmd_stop (i_if.cmd_stop),
        .tx_data  (i_if.m_tx_data),
        .ack_in   (i_if.ack_in),
        .rx_data  (i_if.m_rx_data),
        .ack_out  (i_if.ack_out),
        .busy     (i_if.m_busy),
        .done     (i_if.m_done),
        .tx_done  (i_if.m_tx_done),
        .rx_done  (i_if.m_rx_done),
        .scl      (i_if.scl),
        .sda      (i_if.sda)
    );

    // I2C Slave 0 (addr = 7'h10) ================================
    i2c_slave_top U_SLAVE0 (
        .clk       (clk),
        .rst       (rst),
        .slave_addr(7'h10),
        .tx_data   (i_if.s_tx_data),
        .rx_data   (s0_rx_data),
        .rx_valid  (s0_rx_valid),
        .busy      (s0_busy),
        .scl       (i_if.scl),
        .sda       (i_if.sda)
    );

    // I2C Slave 1 (addr = 7'h20) ================================
    i2c_slave_top U_SLAVE1 (
        .clk       (clk),
        .rst       (rst),
        .slave_addr(7'h20),
        .tx_data   (i_if.s_tx_data),
        .rx_data   (s1_rx_data),
        .rx_valid  (s1_rx_valid),
        .busy      (s1_busy),
        .scl       (i_if.scl),
        .sda       (i_if.sda)
    );

	logic [7:0] s_rx_data_r;
	always_ff @(posedge clk or posedge rst) begin
    	if      (rst)          s_rx_data_r <= 8'h00;
    	else if (s0_rx_valid)  s_rx_data_r <= s0_rx_data;
    	else if (s1_rx_valid)  s_rx_data_r <= s1_rx_data;
	end
	assign i_if.s_rx_data  = s_rx_data_r;
	assign i_if.s_rx_valid = s0_rx_valid | s1_rx_valid;


    initial begin
        uvm_config_db #(virtual i2c_if)::set(null, "*", "i_if", i_if);
        run_test();
    end
    
    initial begin
        $fsdbDumpfile("i2c_tb_top.fsdb");
        $fsdbDumpvars(0);
        $fsdbDumpMDA();
    end

endmodule

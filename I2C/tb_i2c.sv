`timescale 1ns / 1ps

module tb_i2c();

    logic       clk;
    logic       rst;
    logic [8:0] sw;
    logic       i_btn_write;
    logic       i_btn_read;
    logic       sw_fnd_sel;

    wire        scl;
    wire        sda;

    logic [3:0] master_fnd_com;
    logic [7:0] master_fnd_data;
    logic [3:0] slave_fnd_com;
    logic [7:0] slave_fnd_data;
    logic       led_tx_addr_done;
    logic       led_tx_data_done;
    logic       led_rx_data_done;
    logic       led_slave0_active;
    logic       led_slave1_active;

    int pass_cnt;
    int fail_cnt;

    i2c_top dut (
        .clk              (clk),
        .rst              (rst),
        .sw               (sw),
        .i_btn_write      (i_btn_write),
        .i_btn_read       (i_btn_read),
        .sw_fnd_sel       (sw_fnd_sel),
        .master_fnd_com   (master_fnd_com),
        .master_fnd_data  (master_fnd_data),
        .slave_fnd_com    (slave_fnd_com),
        .slave_fnd_data   (slave_fnd_data),
        .led_tx_addr_done (led_tx_addr_done),
        .led_tx_data_done (led_tx_data_done),
        .led_rx_data_done (led_rx_data_done),
        .led_slave0_active(led_slave0_active),
        .led_slave1_active(led_slave1_active),
        .scl              (scl),
        .sda              (sda)
    );

    initial clk = 0;
    always #5 clk = ~clk;

    task automatic press_write();  // write trigger
        i_btn_write = 1'b1;
        repeat (12_000) @(posedge clk);
        i_btn_write = 1'b0;
        repeat (100) @(posedge clk);
    endtask

    task automatic press_read();  // read trigger
        i_btn_read = 1'b1;
        repeat (12_000) @(posedge clk);
        i_btn_read = 1'b0;
        repeat (100) @(posedge clk);
    endtask

    initial begin
        rst         = 1'b1;
        i_btn_write = 1'b0;
        i_btn_read  = 1'b0;
        sw          = 9'h000;
        sw_fnd_sel  = 1'b0;
        repeat (20) @(posedge clk);
        rst = 1'b0;
        repeat (20) @(posedge clk);

        sw = {1'b0, 8'h05};
        repeat (10) @(posedge clk);
        press_write();
        repeat(100_000 * 4) @(posedge clk);

        sw = {1'b0, 8'h00};
        repeat (10) @(posedge clk);
        press_read();
        repeat(100_000 * 4) @(posedge clk);

        sw = {1'b1, 8'h0F};
        repeat (10) @(posedge clk);
        press_write();
        repeat(100_000 * 4) @(posedge clk);

        sw = {1'b1, 8'h00};
        repeat (10) @(posedge clk);
        press_read();
        repeat(100_000 * 4) @(posedge clk);

        sw = {1'b0, 8'h77};
        repeat (10) @(posedge clk);
        press_write();
        repeat(100_000 * 4) @(posedge clk);

        #100;
        $finish;
    end

endmodule
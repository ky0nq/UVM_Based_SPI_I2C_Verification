`timescale 1ns / 1ps

module tb_spi_fndsum ();

    logic clk, rst;
    always #5 clk = ~clk;

    initial begin
        clk = 0;
        rst = 1;
        #200;
        rst = 0;
    end

    // master
    logic [7:0] master_sw;
    logic       master_btn;
    logic [3:0] master_fnd_com;
    logic [7:0] master_fnd_data;
    logic       master_busy;
    logic       master_done;

    // slave
    logic [7:0] slave_sw;
    logic [3:0] slave_fnd_com;
    logic [7:0] slave_fnd_data;
    logic       slave_busy;
    logic       slave_done;

    spi_top DUT (
        .clk             (clk),
        .rst             (rst),
        .master_sw       (master_sw),
        .master_btn      (master_btn),
        .slave_sw        (slave_sw),
        .master_fnd_com  (master_fnd_com),
        .master_fnd_data (master_fnd_data),
        .master_busy     (master_busy),
        .master_done     (master_done),
        .slave_fnd_com   (slave_fnd_com),
        .slave_fnd_data  (slave_fnd_data),
        .slave_busy      (slave_busy),
        .slave_done      (slave_done)
    );

    // inner signal
    wire [7:0] master_rx = DUT.U_MASTER_TOP.rx_data;
    wire [7:0] slave_rx  = DUT.U_SLAVE_TOP.rx_data; 

    // button debounce 80us -> 1 pulse button output
    task press_btn;
        begin
            master_btn = 1'b1;
            #100000; 
            master_btn = 1'b0;
        end
    endtask

    initial begin
        master_sw  = 8'h00;
        master_btn = 1'b0;
        slave_sw   = 8'h0f;  // Decimal : 15

        @(negedge rst);
        #20; 

        // ---- case 1: 30 ----
        master_sw = 8'd30;
        press_btn;
        #5_000_000;

        // ---- case 2: master_rx ----
        // master_rx = 30 + 15 = 45 (expected)
        master_sw = 8'd50;
        press_btn;
        #5_000_000;

        // ---- case 3 ----
        // 50 + 15 = 65 (expected)
        master_sw = 8'd100;
        press_btn;
        #5_000_000;

        // slave_sw change
        slave_sw = 8'd100;
        #5_000_000;

        // 100 + 100 = 200 (expected)
        master_sw = 8'd50;
        press_btn;
        #5_000_000;
        
        #5_000_000;

        $display("Simulation Scenario DONE");
        $finish;
    end
endmodule

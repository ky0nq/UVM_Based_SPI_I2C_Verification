`timescale 1ns / 1ps

module tb_spi_fndsum ();

    logic clk, rst;
    localparam CLK_PERIOD = 10;

    always #(CLK_PERIOD/2) clk = ~clk;

    initial begin
        clk = 0;
        rst = 1;
        #200;
        rst = 0;
    end

    logic        sclk, mosi, miso, ss_n;

    // Master
    logic        start;
    logic [7:0]  master_sw;
    logic [7:0]  master_rx;
    logic        master_busy, master_done;
    logic [3:0]  master_fnd_com;
    logic [7:0]  master_fnd_data;

    // Slave
    logic [7:0]  slave_sw;
    logic [7:0]  slave_rx;
    logic        slave_done;
    logic [3:0]  slave_fnd_com;
    logic [7:0]  slave_fnd_data;

    spi_master u_master (
        .clk    (clk),
        .rst    (rst),
        .start  (start),
        .cpol   (1'b0),
        .cpha   (1'b0),
        .clk_div(8'd1),
        .tx_data(master_sw),
        .busy   (master_busy),
        .rx_data(master_rx),
        .done   (master_done),
        .sclk   (sclk),
        .mosi   (mosi),
        .miso   (miso),
        .ss_n   (ss_n)
    );

    fnd_controller #(
        .COUNT_MAX(99)
    ) u_master_fnd (
        .clk     (clk),
        .rst     (rst),
        .rx_data (master_rx),
        .done    (master_done),
        .fnd_com (master_fnd_com),
        .fnd_data(master_fnd_data)
    );

    spi_slave_top #(
        .COUNT_MAX(99)
    ) u_slave_top (
        .clk     (clk),
        .rst     (rst),
        .slave_sw(slave_sw),
        .sclk    (sclk),
        .ss_n    (ss_n),
        .mosi    (mosi),
        .miso    (miso),
        .fnd_com (slave_fnd_com),
        .fnd_data(slave_fnd_data)
    );

    assign slave_rx   = u_slave_top.rx_data;
    assign slave_done = u_slave_top.done;

    task send;
        input [7:0] tx_val;
        integer timeout_cnt;
        begin
            @(posedge clk); #1;
            master_sw = tx_val;
            start     = 1'b1;
            @(posedge clk); #1;
            start     = 1'b0;

            timeout_cnt = 0;
            while (!master_done && timeout_cnt < 5000) begin
                @(posedge clk);
                timeout_cnt = timeout_cnt + 1;
            end
            if (timeout_cnt >= 5000)
                $display("[TIMEOUT] tx=0x%02X", tx_val);

            @(posedge clk);
        end
    endtask

    initial begin
        start     = 0;
        master_sw = 8'h00;
        slave_sw  = 8'h0F;

        @(negedge rst);
        repeat(20) @(posedge clk);

        $display("============================================");
        $display(" 방향 1: Master sw + Slave sw 덧셈");
        $display(" slave_sw = 0x%02X (%0d)", slave_sw, slave_sw);
        $display("============================================");

        //master_sw=30, master_rx=0 
        $display("\n--- 전송 1: master_sw=30 ---");
        send(8'haa);
        $display("    slave_rx  = %0d (expected=30)", slave_rx);
        $display("    master_rx = %0d (expected=0)", master_rx);

        //  master_rx=45 (30+15) expected 
        $display("\n--- 전송 2: master_sw=50 | master_rx=45 예상 ---");
        send(8'h32);
        if (master_rx == 8'd45)
            $display("    [PASS] master_rx=%0d", master_rx);
        else
            $display("    [FAIL] master_rx=%0d (expected=45)", master_rx);
        $display("    slave_rx  = %0d (expected=50)", slave_rx);

        //  master_rx=65 (50+15) expected
        $display("\n--- 전송 3: master_sw=100 | master_rx=65 예상 ---");
        send(8'h64);
        if (master_rx == 8'd65)
            $display("    [PASS] master_rx=%0d", master_rx);
        else
            $display("    [FAIL] master_rx=%0d (expected=65)", master_rx);

        // slave_sw change
        slave_sw = 8'h64;
        $display("\n--- slave_sw 변경: 100 ---");

        // master_rx=200 (100+100) expected
        $display("\n--- 전송 4: master_sw=50 | master_rx=200 예상 ---");
        send(8'h32);
        if (master_rx == 8'd200)
            $display("    [PASS] master_rx=%0d", master_rx);
        else
            $display("    [FAIL] master_rx=%0d (expected=200)", master_rx);

        $display("\n=== 시뮬레이션 완료 ===");
        $finish;
    end

    always @(posedge master_done)
        $display("[EVT] master_done | master_rx=%0d (0x%02X)", master_rx, master_rx);

    always @(posedge slave_done)
        $display("[EVT] slave_done  | slave_rx=%0d tx_data=%0d", slave_rx, slave_rx + slave_sw);

endmodule

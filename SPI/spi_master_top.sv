`timescale 1ns / 1ps

module spi_master_top (
    input logic clk,
    input logic rst,

    input logic [7:0] master_sw,  // master input
    input logic       i_btn,      // start trigger input

    // SPI 
    output logic sclk,
    output logic mosi,
    input  logic miso,
    output logic ss_n,

    // master FND
    output logic [3:0] fnd_com,
    output logic [7:0] fnd_data,

    // Monitoring
    output logic busy,
    output logic done
);

    logic w_start;          // 1-cycle pulse from btn_debounce, transfer start trigger signal
    logic w_done;
    logic [7:0] rx_data;

    btn_debounce BTN_DEBOUNCE (
        .clk  (clk),
        .rst  (rst),
        .i_btn(i_btn),
        .o_btn(w_start)
    );

    spi_master U_SPI_MASTER (
        .clk    (clk),
        .rst    (rst),
        .start  (w_start),
        .cpol   (1'b0),
        .cpha   (1'b0),
        .clk_div(8'd4),
        .tx_data(master_sw),
        .busy   (busy),
        .rx_data(rx_data),
        .done   (w_done),
        .sclk   (sclk),
        .mosi   (mosi),
        .miso   (miso),
        .ss_n   (ss_n)
    );

    fnd_controller U_FND_MASTER (
        .clk     (clk),
        .rst     (rst),
        .rx_data (rx_data),
        .done    (w_done),
        .fnd_com (fnd_com),
        .fnd_data(fnd_data)
    );

    // master done signal display (toggle, for LED/monitoring)
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

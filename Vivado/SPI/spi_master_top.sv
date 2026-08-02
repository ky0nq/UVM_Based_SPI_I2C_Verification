`timescale 1ns / 1ps

module spi_master_top (
    input  logic       clk,
    input  logic       rst,

    input  logic [7:0] master_sw,   // master input
    input  logic       i_btn,       // start trigger input

    // SPI 
    output logic       sclk,
    output logic       mosi,
    input  logic       miso,
    output logic       ss_n,

    output logic [3:0] fnd_com,
    output logic [7:0] fnd_data,

    // Monitoring
    output logic       busy,
    output logic       done
);

    logic w_start;
    logic w_done;
    logic [7:0] w_rx_data;

    btn_debounce u_btn_debounce (
        .clk  (clk),
        .rst  (rst),
        .i_btn(i_btn),
        .o_btn(w_start)
    );

    spi_master u_spi_master (
        .clk    (clk),
        .rst    (rst),
        .start  (w_start),
        .cpol   (1'b0),
        .cpha   (1'b0),
        .clk_div(8'd1),
        .tx_data(master_sw),
        .busy   (busy),
        .rx_data(w_rx_data),
        .done   (w_done),
        .sclk   (sclk),
        .mosi   (mosi),
        .miso   (miso),
        .ss_n   (ss_n)
    );

    fnd_controller u_fnd_controller (
        .clk     (clk),
        .rst     (rst),
        .rx_data (w_rx_data),
        .done    (w_done),
        .fnd_com (fnd_com),
        .fnd_data(fnd_data)
    );

    // done toggle output
    always_ff @(posedge clk or posedge rst) begin
        if      (rst)    done <= 1'b0;
        else if (w_done) done <= ~done;
        else             done <= done;
    end

endmodule

`timescale 1ns / 1ps

module i2c_master_board (
    input logic clk,
    input logic rst,

    // sw[8] is 0 : slave0 , 1 : slave1
    input logic [8:0] sw,

    // master write & read
    input logic i_btn_write,  // btnR
    input logic i_btn_read,   // btnL

    // master FND
    output logic [3:0] fnd_com,
    output logic [7:0] fnd_data,

    // master to slave - address
    output logic led_tx_addr_done,
    // master to slave - data
    output logic led_tx_data_done,
    // slave to master - ack signal
    output logic led_rx_data_done,  // data take ok -> slave ack

    inout  wire sda,
    output wire scl
);

    // address 7-bit command
    logic [6:0] target_addr;
    always_comb begin
        case (sw[8])  // slave address
            1'b0: target_addr = 7'h10;
            1'b1: target_addr = 7'h20;
            default: target_addr = 7'h10;
        endcase
    end

    logic [7:0] SLA_W, SLA_R;
    assign SLA_W = {target_addr, 1'b0};  // write signal
    assign SLA_R = {target_addr, 1'b1};  // read signal

    // data 8-bit
    logic [7:0] tx_payload;
    assign tx_payload = sw[7:0];  // switch is data value

    logic w_btn_write, w_btn_read;

    // btnR
    btn_debounce U_BTN_WRITE (
        .clk  (clk),
        .rst  (rst),
        .i_btn(i_btn_write),
        .o_btn(w_btn_write)
    );
    // btnL
    btn_debounce U_BTN_READ (
        .clk  (clk),
        .rst  (rst),
        .i_btn(i_btn_read),
        .o_btn(w_btn_read)
    );

    // command signal
    logic m_cmd_start, m_cmd_write, m_cmd_read, m_cmd_stop;

    // master signal
    logic [7:0] m_tx_data;
    logic [7:0] m_rx_data;
    logic m_done, m_busy;
    logic m_tx_done, m_rx_done;

    logic is_idle, is_addr_phase, is_data_phase;

    i2c_master_top U_MASTER (
        .clk      (clk),
        .rst      (rst),
        .cmd_start(m_cmd_start),
        .cmd_write(m_cmd_write),
        .cmd_read (m_cmd_read),
        .cmd_stop (m_cmd_stop),
        .tx_data  (m_tx_data),
        .ack_in   (1'b1),
        .rx_data  (m_rx_data),
        .ack_out  (),
        .busy     (m_busy),
        .done     (m_done),
        .tx_done  (m_tx_done),
        .rx_done  (m_rx_done),
        .scl      (scl),
        .sda      (sda)
    );


    i2c_demo U_DEMO_CTRL (
        .clk          (clk),
        .rst          (rst),
        .w_btn_write  (w_btn_write),
        .w_btn_read   (w_btn_read),
        .SLA_W        (SLA_W),
        .SLA_R        (SLA_R),
        .tx_payload   (tx_payload),
        .m_done       (m_done),
        .m_busy       (m_busy),
        .m_cmd_start  (m_cmd_start),
        .m_cmd_write  (m_cmd_write),
        .m_cmd_read   (m_cmd_read),
        .m_cmd_stop   (m_cmd_stop),
        .m_tx_data    (m_tx_data),
        .is_idle      (is_idle),
        .is_addr_phase(is_addr_phase),
        .is_data_phase(is_data_phase)
    );

    logic   rx_received;
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            rx_received <= 1'b0;
        end else if (m_rx_done) begin
            rx_received <= 1'b1;
        end else if (w_btn_write || w_btn_read) begin
            rx_received <= 1'b0;
        end
    end

    logic [7:0] fnd_val;
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            fnd_val <= 8'h00;
        end else if (m_rx_done) begin
            fnd_val <= m_rx_data;
        end else if (!rx_received && is_idle) begin
            fnd_val <= {1'b0, target_addr};
        end
    end

    fnd_controller U_FND_MASTER (
        .clk     (clk),
        .rst     (rst),
        .rx_data (fnd_val),
        .done    (1'b1),
        .fnd_com (fnd_com),
        .fnd_data(fnd_data)
    );

    // LED display
    logic pulse_addr_done, pulse_data_done;
    assign pulse_addr_done = m_tx_done && is_addr_phase;
    assign pulse_data_done = m_tx_done && is_data_phase;

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            led_tx_addr_done <= 1'b0;
            led_tx_data_done <= 1'b0;
            led_rx_data_done <= 1'b0;
        end else if (w_btn_write || w_btn_read) begin
            led_tx_addr_done <= 1'b0;
            led_tx_data_done <= 1'b0;
            led_rx_data_done <= 1'b0;
        end else begin  // done signal display to LED
            if (pulse_addr_done) begin
                led_tx_addr_done <= 1'b1;
            end
            if (pulse_data_done) begin
                led_tx_data_done <= 1'b1;
            end
            if (m_rx_done) begin
                led_rx_data_done <= 1'b1;
            end
        end
    end

endmodule
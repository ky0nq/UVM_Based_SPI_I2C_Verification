`timescale 1ns / 1ps

// I2C master command 
module i2c_demo (
    input logic clk,
    input logic rst,

    input logic w_btn_write,
    input logic w_btn_read,

    input logic [7:0] SLA_W,
    input logic [7:0] SLA_R,
    input logic [7:0] tx_payload,

    input logic m_done,
    input logic m_busy,

    output logic       m_cmd_start,
    output logic       m_cmd_write,
    output logic       m_cmd_read,
    output logic       m_cmd_stop,
    output logic [7:0] m_tx_data,

    // display information by LED
    output logic is_idle,       // idle state
    output logic is_addr_phase, // send addr - slave select
    output logic is_data_phase  // send data
);

    typedef enum logic [3:0] {
        IDLE,
        W_START,
        W_ADDR,
        W_DATA,
        W_STOP,
        R_START,
        R_ADDR,
        R_DATA,
        R_STOP
    } state_e;
    state_e state;

    assign is_idle       = (state == IDLE);
    assign is_addr_phase = (state == W_ADDR) || (state == R_ADDR);
    assign is_data_phase = (state == W_DATA);

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            state       <= IDLE;
            m_cmd_start <= 1'b0;
            m_cmd_write <= 1'b0;
            m_cmd_read  <= 1'b0;
            m_cmd_stop  <= 1'b0;
            m_tx_data   <= 8'h00;
        end else begin
            m_cmd_start <= 1'b0;
            m_cmd_write <= 1'b0;
            m_cmd_read  <= 1'b0;
            m_cmd_stop  <= 1'b0;
            case (state)
                IDLE: begin
                    if (w_btn_write) begin
                        m_cmd_start <= 1'b1;
                        state       <= W_START;
                    end else if (w_btn_read) begin
                        m_cmd_start <= 1'b1;
                        state       <= R_START;
                    end
                end
                // WRITE state ====================
                W_START:
                if (m_done) begin
                    m_tx_data   <= SLA_W;
                    m_cmd_write <= 1'b1;
                    state       <= W_ADDR;
                end
                W_ADDR:
                if (m_done) begin
                    m_tx_data   <= tx_payload;
                    m_cmd_write <= 1'b1;
                    state       <= W_DATA;
                end
                W_DATA:
                if (m_done) begin
                    m_cmd_stop <= 1'b1;
                    state      <= W_STOP;
                end
                W_STOP:
                if (!m_busy) begin
                    state <= IDLE;
                end
                // ================================
                // READ state =====================
                R_START:
                if (m_done) begin
                    m_tx_data   <= SLA_R;
                    m_cmd_write <= 1'b1;
                    state       <= R_ADDR;
                end
                R_ADDR:
                if (m_done) begin
                    m_cmd_read <= 1'b1;
                    state      <= R_DATA;
                end
                R_DATA:
                if (m_done) begin
                    m_cmd_stop <= 1'b1;
                    state      <= R_STOP;
                end
                R_STOP:
                if (!m_busy) begin
                    state <= IDLE;
                end
                // ================================
                default: state <= IDLE;
            endcase
        end
    end
endmodule

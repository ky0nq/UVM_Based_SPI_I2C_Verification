`timescale 1ns / 1ps

module i2c_slave_top (
    input  logic       clk,
    input  logic       rst,
    input  logic [6:0] slave_addr,

    input  logic [7:0] tx_data,
    output logic [7:0] rx_data,
    output logic       rx_valid,
    output logic       busy,

    input  logic       scl,
    inout  wire        sda
);
    logic sda_o, sda_i;

    // open drain
    assign sda_i = sda;
    assign sda   = sda_o ? 1'bz : 1'b0;

    i2c_slave U_I2C_SLAVE (
        .*,
        .sda_o(sda_o),
        .sda_i(sda_i)
    );
endmodule


module i2c_slave (
    input  logic       clk,
    input  logic       rst,

    input  logic [6:0] slave_addr,

    input  logic [7:0] tx_data,
    output logic [7:0] rx_data,
    output logic       rx_valid,
    output logic       busy,

    input  logic       scl,
    input  logic       sda_i,
    output logic       sda_o
);

    logic [1:0] scl_sr, sda_sr;
    always_ff @(posedge clk, posedge rst) begin
        if (rst) begin
            scl_sr <= 2'b11;
            sda_sr <= 2'b11;
        end else begin
            scl_sr <= {scl_sr[0], scl};
            sda_sr <= {sda_sr[0], sda_i};
        end
    end

    logic scl_s, sda_s;
    assign scl_s = scl_sr[1];
    assign sda_s = sda_sr[1];

    // Edge Detect =================================================
    logic scl_prev, sda_prev;
    always_ff @(posedge clk, posedge rst) begin
        if (rst) begin
            scl_prev <= 1'b1;
            sda_prev <= 1'b1;
        end else begin
            scl_prev <= scl_s;
            sda_prev <= sda_s;
        end
    end

    logic scl_rise, scl_fall, start_det, stop_det;
    assign scl_rise  = ~scl_prev &  scl_s;              // SCL rising edge
    assign scl_fall  =  scl_prev & ~scl_s;              // SCL falling edge
    assign start_det =  scl_s &  sda_prev & ~sda_s;     // SCL = 1 -> SDA Low
    assign stop_det  =  scl_s & ~sda_prev &  sda_s;     // SCL = 1 -> SDA High
    // =============================================================

    typedef enum logic [2:0] {
        IDLE,
        ADDR,
        ADDR_ACK,
        DATA_WRITE,
        DATA_WRITE_ACK,
        DATA_READ,
        DATA_READ_ACK
    } state_e;
    state_e state;

    logic [7:0] shift_reg;
    logic [7:0] tx_shift;
    logic [2:0] bit_cnt;
    logic       is_read;
    logic       addr_match_r;
    logic       ack_driven;
    logic       master_nack;

    assign busy = (state != IDLE);

    always_ff @(posedge clk, posedge rst) begin
        if (rst) begin
            state        <= IDLE;
            sda_o        <= 1'b1;
            shift_reg    <= 8'h00;
            tx_shift     <= 8'h00;
            bit_cnt      <= 3'd0;
            is_read      <= 1'b0;
            rx_data      <= 8'h00;
            rx_valid     <= 1'b0;
            addr_match_r <= 1'b0;
            ack_driven   <= 1'b0;
            master_nack  <= 1'b0;
        end else begin
            rx_valid <= 1'b0; 
            // first condition = start / stop 
            if (start_det) begin
                state      <= ADDR;
                bit_cnt    <= 3'd0;
                shift_reg  <= 8'h00;
                sda_o      <= 1'b1;
                ack_driven <= 1'b0;
            end
            else if (stop_det) begin
                state <= IDLE;
                sda_o <= 1'b1;
            end
            else begin
                case (state)
                    IDLE: begin
                        sda_o <= 1'b1;
                    end
                    // Address + Read/Write information
                    ADDR: begin
                        if (scl_rise) begin
                            shift_reg <= {shift_reg[6:0], sda_s};
                            if (bit_cnt == 3'd7) begin
                                state      <= ADDR_ACK;
                                bit_cnt    <= 3'd0;
                                ack_driven <= 1'b0;
                            end else begin
                                bit_cnt <= bit_cnt + 1;
                            end
                        end
                    end

                    // Address ACK / NACK
                    ADDR_ACK: begin
                        if (scl_fall) begin
                            if (!ack_driven) begin
                                addr_match_r <= (shift_reg[7:1] == slave_addr);
                                is_read      <= shift_reg[0];
                                sda_o        <= (shift_reg[7:1] == slave_addr) ? 1'b0 : 1'b1;
                                ack_driven   <= 1'b1;
                            end else begin
                                ack_driven <= 1'b0;
                                if (!addr_match_r) begin
                                    sda_o <= 1'b1;
                                    state <= IDLE;
                                end else if (is_read) begin
                                    tx_shift <= tx_data;
                                    sda_o    <= tx_data[7];
                                    state    <= DATA_READ;
                                    bit_cnt  <= 3'd0;
                                end else begin
                                    sda_o   <= 1'b1;
                                    state   <= DATA_WRITE;
                                    bit_cnt <= 3'd0;
                                end
                            end
                        end
                    end

                    // Data Write
                    DATA_WRITE: begin
                        if (scl_rise) begin
                            shift_reg <= {shift_reg[6:0], sda_s};
                            if (bit_cnt == 3'd7) begin
                                state      <= DATA_WRITE_ACK;
                                bit_cnt    <= 3'd0;
                                ack_driven <= 1'b0;
                            end else begin
                                bit_cnt <= bit_cnt + 1;
                            end
                        end
                    end

                    // Data ACK / NACK
                    DATA_WRITE_ACK: begin
                        if (scl_fall) begin
                            if (!ack_driven) begin
                                sda_o      <= 1'b0;      // ACK
                                rx_data    <= shift_reg;
                                rx_valid   <= 1'b1;      
                                ack_driven <= 1'b1;
                            end else begin
                                sda_o      <= 1'b1;
                                ack_driven <= 1'b0;
                                state      <= DATA_WRITE;
                                bit_cnt    <= 3'd0;
                            end
                        end
                    end

                    // Data Read
                    DATA_READ: begin
                        if (scl_fall) begin
                            if (bit_cnt == 3'd7) begin
                                sda_o   <= 1'b1;  
                                state   <= DATA_READ_ACK;
                                bit_cnt <= 3'd0;
                            end else begin
                                sda_o    <= tx_shift[6];
                                tx_shift <= {tx_shift[6:0], 1'b0};
                                bit_cnt  <= bit_cnt + 1;
                            end
                        end
                    end

                    // Read ACK / NACK
                    DATA_READ_ACK: begin
                        if (scl_rise) begin
                            master_nack <= sda_s;  // NACK = 1 -> done
                        end else if (scl_fall) begin
                            if (master_nack) begin
                                sda_o <= 1'b1;
                                state <= IDLE;
                            end else begin
                                tx_shift <= tx_data;
                                sda_o    <= tx_data[7];
                                state    <= DATA_READ;
                                bit_cnt  <= 3'd0;
                            end
                        end
                    end

                    default: state <= IDLE;
                endcase
            end
        end
    end
endmodule
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
    inout  logic       sda
);
    logic sda_o, sda_i;

    assign sda_i = sda;
    assign sda   = sda_o ? 1'bz : 1'b0;
    // read state -> Hi-Z
    // write state -> sda = 0

    // inout port connect
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

    // 2-stage FF synchronizer ===========================
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
    // ===================================================

    // Edge detector =====================================
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

    logic scl_rise, scl_fall;
    assign scl_rise  = ~scl_prev & scl_s;
    assign scl_fall  =  scl_prev & ~scl_s;
    // ===================================================

    // State detector ====================================
    logic start_det, stop_det;
    assign start_det =  scl_s & sda_prev & ~sda_s;
    assign stop_det  =  scl_s & ~sda_prev & sda_s;
    // ===================================================

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
        end 
        else begin
            rx_valid <= 1'b0;
            // considering priority start > stop > other
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
                    ADDR: begin
                        if (scl_rise) begin
                            shift_reg <= {shift_reg[6:0], sda_s};       // address merge
                            if (bit_cnt == 3'd7) begin
                                state       <= ADDR_ACK;
                                bit_cnt     <= 3'd0;
                                ack_driven  <= 1'b0;                    // nack signal
                            end else begin
                                bit_cnt     <= bit_cnt + 1;
                            end
                        end
                    end
                    ADDR_ACK: begin
                        if (scl_fall) begin
                            if (!ack_driven) begin  // nack signal 
                                addr_match_r <= (shift_reg[7:1] == slave_addr); // slave address 
                                is_read      <= shift_reg[0];                   // write read signal
                                // 1'b0 = ACK (from select slave) | 1'b1 = NACK (no address detect)
                                sda_o        <= (shift_reg[7:1] == slave_addr) ? 1'b0 : 1'b1; // slave select -> sda_o = 0
                                ack_driven   <= 1'b1;                          
                            end 
                            else begin // ack signal HIGH
                                ack_driven <= 1'b0;             
                                if (!addr_match_r) begin    // not match address to current slave 
                                    sda_o <= 1'b1;          // Hi-Z bus short state
                                    state <= IDLE;
                                end else if (is_read) begin
                                    tx_shift <= tx_data;    // send data (= read data) drive
                                    sda_o    <= tx_data[7]; // data send
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
                    DATA_WRITE: begin
                        if (scl_rise) begin
                            shift_reg <= {shift_reg[6:0], sda_s};   // sync_sda data write
                            if (bit_cnt == 3'd7) begin
                                state      <= DATA_WRITE_ACK;
                                bit_cnt    <= 3'd0;
                                ack_driven <= 1'b0;                 // ACK send signal not yet      
                            end else begin
                                bit_cnt <= bit_cnt + 1;
                            end
                        end
                    end
                    DATA_WRITE_ACK: begin
                        if (scl_fall) begin
                            if (!ack_driven) begin      // ACK no send signal   
                                sda_o      <= 1'b0;     // ACK zero maintain
                                rx_data    <= shift_reg;
                                rx_valid   <= 1'b1;
                                ack_driven <= 1'b1;     // ACK driven
                            end else begin
                                sda_o      <= 1'b1;
                                ack_driven <= 1'b0;
                                state      <= DATA_WRITE;
                                bit_cnt    <= 3'd0;
                            end
                        end
                    end
                    DATA_READ: begin
                        if (scl_fall) begin
                            if (bit_cnt == 3'd7) begin
                                sda_o   <= 1'b1;
                                state   <= DATA_READ_ACK;
                                bit_cnt <= 3'd0;
                            end else begin
                                sda_o    <= tx_shift[6];
                                tx_shift <= {tx_shift[6:0], 1'b0}; // msb send data
                                bit_cnt  <= bit_cnt + 1;
                            end
                        end
                    end
                    DATA_READ_ACK: begin
                        if (scl_rise) begin
                            master_nack <= sda_s;   // master to slave ACK signal
                        end else if (scl_fall) begin
                            if (master_nack) begin 
                                sda_o <= 1'b1;      // disconnect
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
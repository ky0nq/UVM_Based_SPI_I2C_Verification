`timescale 1ns / 1ps

module spi_master (
    // global signals
    input   logic           clk,
    input   logic           rst,
    
    // internal signals
    input   logic           start,
    input   logic           cpol,    // clock polarity
    input   logic           cpha,    // clock phase
    input   logic [7:0]     clk_div, 
    input   logic [7:0]     tx_data,
    output  logic           busy,    
    output  logic [7:0]     rx_data,
    output  logic           done,

    // external signals
    output  logic           sclk,
    output  logic           mosi,
    input   logic           miso,
    output  logic           ss_n
);
    typedef enum logic [1:0] {
        IDLE  = 2'b00,
        START,
        DATA,
        STOP
    } spi_state_e;
    spi_state_e state;

    logic [7:0] div_cnt;
    logic [7:0] clk_div_r;
    logic       half_tick;
    logic [7:0] tx_shift_reg;
    logic [7:0] rx_shift_reg;
    logic [2:0] bit_cnt;
    logic       step;
    logic       cpol_r;
    logic       cpha_r;
    logic       sclk_r;

    assign sclk = sclk_r;

    // 2-stage FF synchronizer (MISO) ==============================
    logic miso_d1, miso_d2;

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            {miso_d1, miso_d2} <= 2'b00;
        end 
        else begin
            {miso_d1, miso_d2} <= {miso, miso_d1};
        end
    end
    // =============================================================

    // clock divider  ==============================================
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            div_cnt   <= 0;
            half_tick <= 1'b0;
        end else begin
            if (state == DATA) begin
                if (div_cnt == clk_div_r) begin
                    div_cnt   <= 0;
                    half_tick <= 1'b1;
                end else begin
                    div_cnt   <= div_cnt + 1;
                    half_tick <= 1'b0;
                end
            end else begin
                div_cnt   <= 0;
                half_tick <= 1'b0;
            end
        end
    end
    // =============================================================

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            state        <= IDLE;
            mosi         <= 1'b1;
            ss_n         <= 1'b1;
            busy         <= 1'b0;
            done         <= 1'b0;
            tx_shift_reg <= 0;
            rx_shift_reg <= 0;
            bit_cnt      <= 0;
            rx_data      <= 0;
            sclk_r       <= cpol;
            cpha_r       <= cpha;
            cpol_r       <= 1'b0;
            clk_div_r    <= 0;
        end else begin
            done <= 1'b0;
            case (state)
                IDLE : begin
                    mosi   <= 1'b1;
                    ss_n   <= 1'b1;
                    sclk_r <= cpol;
                    if (start) begin
                        cpol_r       <= cpol;
                        cpha_r       <= cpha;
                        tx_shift_reg <= tx_data;
                        clk_div_r    <= clk_div;
                        bit_cnt      <= 0;
                        busy         <= 1'b1;
                        step         <= 1'b0;
                        ss_n         <= 1'b0;
                        state        <= START;
                    end
                end
                START : begin
                    if (!cpha_r) begin
                        mosi         <= tx_shift_reg[7];
                        tx_shift_reg <= {tx_shift_reg[6:0], 1'b0};
                    end
                    state <= DATA;
                end
                DATA : begin
                    if (half_tick) begin
                        sclk_r <= ~sclk_r;
                        if (step == 0) begin    // first edge
                            step <= 1'b1;
                            if (!cpha_r) begin  
                                rx_shift_reg <= {rx_shift_reg[6:0], miso_d2};   // clock phase == 0 -> first edge : sampling
                            end
                            else begin          // clock phase == 1 -> first edge : shift
                                mosi         <= tx_shift_reg[7];
                                tx_shift_reg <= {tx_shift_reg[6:0], 1'b0};
                            end
                        end else begin          // second edge
                            step <= 1'b0;
                            if (cpha_r) begin
                                rx_shift_reg <= {rx_shift_reg[6:0], miso_d2};   // clock phase == 1 -> second edge : sampling
                            end

                            if (bit_cnt < 7) begin
                                if (!cpha_r) begin  // clock phase == 0 -> second edge : shift
                                    mosi         <= tx_shift_reg[7];
                                    tx_shift_reg <= {tx_shift_reg[6:0], 1'b0};
                                end
                                bit_cnt <= bit_cnt + 1;
                            end 
                            else begin              // transfer complete
                                state <= STOP;
                                if (cpha_r) begin   // clock phase == 1, last bit sampled this edge
                                    rx_data <= {rx_shift_reg[6:0], miso_d2};
                                end
                                else begin
                                    rx_data <= rx_shift_reg;
                                end
                            end
                        end
                    end
                end
                STOP : begin
                    sclk_r <= cpol_r;
                    ss_n   <= 1'b1;
                    done   <= 1'b1;
                    busy   <= 1'b0;
                    mosi   <= 1'b1;
                    state  <= IDLE;
                end
                default : state <= IDLE;
            endcase
        end
    end
endmodule
`timescale 1ns / 1ps

module spi_slave #(
    parameter CPOL = 0,
    parameter CPHA = 0
)(
     // global signals
    input   logic           clk,
    input   logic           rst,

    // internal signals
    input   logic   [7:0]   tx_data,
    output  logic   [7:0]   rx_data,
    output  logic           busy,
    output  logic           done,

    // external signals
    input   logic           sclk,
    input   logic           ss_n,
    input   logic           mosi,
    output  logic           miso
);

    typedef enum logic [1:0] {
        IDLE  = 2'b00,
        DATA,
        DONE
    } spi_state_e;
    spi_state_e state;

    logic [7:0] tx_shift_reg;
    logic [7:0] rx_shift_reg;
    logic [2:0] bit_cnt;

    // 2 stage FF synchronizer =================================================
    // Master - Slave Structure is CDC environment
    logic sclk_d1, sclk_d2;
    logic ss_n_d1, ss_n_d2;
    logic mosi_d1, mosi_d2;
    
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            {sclk_d1, sclk_d2} <= 2'b00;
            {ss_n_d1, ss_n_d2} <= 2'b11;                // ss_n idles high (Low active)
            {mosi_d1, mosi_d2} <= 2'b00;
        end else begin
            {sclk_d1, sclk_d2} <= {sclk,  sclk_d1};
            {ss_n_d1, ss_n_d2} <= {ss_n,  ss_n_d1};
            {mosi_d1, mosi_d2} <= {mosi,  mosi_d1};
        end
    end
    //===========================================================================

    // Edge Detector ============================================================
    logic sclk_rising, sclk_falling;
    assign sclk_rising  = ( sclk_d1 & ~sclk_d2);
    assign sclk_falling = (~sclk_d1 &  sclk_d2);
    // ==========================================================================

    // SPI interface MODE ==========================================================================
    logic sample_edge, shift_edge;
    assign sample_edge = (CPOL == CPHA) ? sclk_rising  : sclk_falling;  // sampling point
    assign shift_edge  = (CPOL == CPHA) ? sclk_falling : sclk_rising;   // driving (sending) point
    // =============================================================================================

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            state        <= IDLE;
            miso         <= 1'b0;
            busy         <= 1'b0;
            done         <= 1'b0;
            tx_shift_reg <= 0;
            rx_shift_reg <= 0;
            bit_cnt      <= 0;
            rx_data      <= 0;
        end else begin
            done <= 1'b0;
            case (state)
                IDLE : begin
                    busy    <= 1'b0;
                    miso    <= 1'b0;
                    bit_cnt <= 0;
                    if (!ss_n_d2) begin
                        state        <= DATA;
                        busy         <= 1'b1;
                        if (CPOL == CPHA) begin        
                            miso         <= tx_data[7];              
                            tx_shift_reg <= {tx_data[6:0], 1'b0};   
                        end else begin                  
                            miso         <= 1'b0;
                            tx_shift_reg <= tx_data;
                        end
                    end
                end     
                DATA : begin
                    if (ss_n_d2) begin               
                        busy  <= 1'b0;
                        state <= IDLE;
                    end else begin
                        if (sample_edge) begin          // MOSI data 
                            rx_shift_reg <= {rx_shift_reg[6:0], mosi_d2};  
                            bit_cnt      <= bit_cnt + 1;
                            if (bit_cnt == 3'd7) begin  // 8-bit data merge done
                                rx_data <= {rx_shift_reg[6:0], mosi_d2};  
                                state   <= DONE;
                            end
                        end
                        if (shift_edge) begin
                            miso         <= tx_shift_reg[7];
                            tx_shift_reg <= {tx_shift_reg[6:0], 1'b0};
                        end
                    end
                end
                DONE : begin
                    done      <= 1'b1;
                    busy      <= 1'b0;
                    bit_cnt   <= 3'd0;
                    state     <= IDLE;
                end
                default : state <= IDLE;
            endcase
        end
    end
endmodule
`timescale 1ns / 1ps

module btn_debounce (
    input  clk,
    input  rst,
    input  i_btn,
    output o_btn
);
    parameter F_COUNT = 100_000_000 / 100_000;
    reg [$clog2(F_COUNT)-1:0] r_counter;
    reg clk_100khz;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            r_counter  <= 0;
            clk_100khz <= 0;
        end else begin
            r_counter <= r_counter + 1;
            if (r_counter == F_COUNT - 1) begin // tick period 
                r_counter  <= 0;
                clk_100khz <= 1'b1;
            end 
            else begin
                clk_100khz <= 1'b0; 
            end
        end
    end

    reg [7:0] sync_reg, sync_next;
    wire debounce;

    always @(posedge clk_100khz or posedge rst) begin
        if (rst) sync_reg <= 8'h00;
        else     sync_reg <= sync_next;
    end

    // 80 us 
    always @(*) begin
        sync_next = {sync_reg[6:0], i_btn};
    end

    assign debounce = &sync_reg;

    // Making 1 pulse button input 
    reg edge_reg;
    always @(posedge clk or posedge rst) begin
        if (rst) edge_reg <= 1'b0;
        else     edge_reg <= debounce;
    end

    assign o_btn = debounce & ~edge_reg; // 1 pulse output
endmodule

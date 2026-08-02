`timescale 1ns / 1ps

module fnd_controller (
    input  logic       clk,
    input  logic       rst,
    input  logic [7:0] rx_data,
    input  logic       done,    // slave state done 
    output logic [3:0] fnd_com,
    output logic [7:0] fnd_data
);

    logic [7:0] fnd_val;
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            fnd_val <= 8'h00;
        end else if (done) begin
            fnd_val <= rx_data;  
        end
    end

    logic [3:0] digit_1, digit_10, digit_100, digit_1000;
    digit_split_1000 #(
        .BIT_WIDTH(8)
    ) U_DIGIT_SPLIT (
        .digit_in  (fnd_val),
        .digit_1   (digit_1),
        .digit_10  (digit_10),
        .digit_100 (digit_100),
        .digit_1000(digit_1000)
    );


    logic w_1khz;
    clk_div_1khz U_CLK_DIV (
        .clk(clk),
        .rst(rst),
        .o_1khz(w_1khz)
    );

    logic [1:0] digit_sel;
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            digit_sel <= 2'b00;
        end else if (w_1khz) begin
            digit_sel <= digit_sel + 1'b1;
        end
    end

    logic [3:0] selected_digit;
    always_comb begin
        case (digit_sel)
            2'b00:   selected_digit = digit_1;
            2'b01:   selected_digit = digit_10;
            2'b10:   selected_digit = digit_100;
            2'b11:   selected_digit = digit_1000;
            default: selected_digit = 4'hf;
        endcase
    end

    bcd U_BCD (
        .bin(selected_digit),
        .bcd_data(fnd_data)
    );

    dec_2to4 U_DEC (
        .dec_in (digit_sel),
        .fnd_com(fnd_com)
    );

endmodule

module clk_div_1khz (
    input  logic clk,
    input  logic rst,
    output logic o_1khz
);
    logic [16:0] cnt;
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            cnt    <= 17'd0;
            o_1khz <= 1'b0;
        end else begin
            if (cnt == 99_999) begin
                cnt    <= 17'd0;
                o_1khz <= 1'b1;
            end else begin
                cnt    <= cnt + 1'b1;
                o_1khz <= 1'b0;
            end
        end
    end
endmodule

module digit_split_1000 #(
    parameter BIT_WIDTH = 9
) (
    input  logic [BIT_WIDTH-1:0] digit_in,
    output logic [          3:0] digit_1,
    output logic [          3:0] digit_10,
    output logic [          3:0] digit_100,
    output logic [          3:0] digit_1000
);
    assign digit_1    = digit_in % 10;
    assign digit_10   = (digit_in / 10) % 10;
    assign digit_100  = (digit_in / 100) % 10;
    assign digit_1000 = (digit_in / 1000) % 10;
endmodule

module bcd (
    input  logic [3:0] bin,
    output logic [7:0] bcd_data
);
    always @(bin) begin
        case (bin)
            4'b0000: bcd_data = 8'hc0;  // 0
            4'b0001: bcd_data = 8'hf9;  // 1
            4'b0010: bcd_data = 8'ha4;  // 2
            4'b0011: bcd_data = 8'hb0;  // 3
            4'b0100: bcd_data = 8'h99;  // 4
            4'b0101: bcd_data = 8'h92;  // 5
            4'b0110: bcd_data = 8'h82;  // 6
            4'b0111: bcd_data = 8'hf8;  // 7    
            4'b1000: bcd_data = 8'h80;  // 8
            4'b1001: bcd_data = 8'h90;  // 9
            default: bcd_data = 8'hff;
        endcase
    end
endmodule

module dec_2to4 (
    input  logic [1:0] dec_in,
    output logic [3:0] fnd_com
);
    always @(*) begin
        case (dec_in)
            2'b00:   fnd_com = 4'b1110;
            2'b01:   fnd_com = 4'b1101;
            2'b10:   fnd_com = 4'b1011;
            2'b11:   fnd_com = 4'b0111;
            default: fnd_com = 4'b1111;
        endcase
    end
endmodule

`timescale 1ns / 1ps

module seven_seg_display (
  input clk,
  input [15:0] x,
  output [5:0] sel,
  output [7:0] seg
);

wire [6:0] seg_lut [9:0];

assign seg_lut[0] = 7'b1000000;
assign seg_lut[1] = 7'b1111001;
assign seg_lut[2] = 7'b0100100;
assign seg_lut[3] = 7'b0110000;
assign seg_lut[4] = 7'b0011001;
assign seg_lut[5] = 7'b0010010;
assign seg_lut[6] = 7'b0000010;
assign seg_lut[7] = 7'b1111000;
assign seg_lut[8] = 7'b0000000;
assign seg_lut[9] = 7'b0010000;

reg [15:0] curr_x = 32'd0;
wire [3:0] curr_digit;
wire [15:0] next_x;
last_digit_32 ld32i0(.x(curr_x), .x_mod(curr_digit), .x_div(next_x));

reg [15:0] cnt = 0;
always @(posedge clk) cnt <= cnt + 1;
wire sd_clk;
assign sd_clk = cnt[15];

reg [5:0] sel_reg = 6'b000001;
assign seg[7:0] = {1'b1, seg_lut[curr_digit]};
assign sel[5:0] = ~sel_reg;

always @(posedge cnt[15]) begin
  curr_x <= sel_reg[5] ? x : next_x;
  sel_reg <= {sel_reg[4:0], sel_reg[5]};
end

endmodule

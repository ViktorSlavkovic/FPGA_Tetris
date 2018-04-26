`timescale 1ns / 1ps

module last_digit_32(
  input [15:0] x,
  output [3:0] x_mod,
  output [15:0] x_div
);

wire [15:0] xx;
assign xx = x / 10;
assign x_div = xx;
assign x_mod = x - ((xx << 3) + (xx << 1));

endmodule

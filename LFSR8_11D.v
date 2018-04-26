`timescale 1ns / 1ps

module LFSR8_11D (
  input clk,
  input [7:0] seed,
  output [7:0] LFSR_out
);

reg [7:0] LFSR;

reg init = 1'b1;

assign LFSR_out = LFSR;

wire feedback = LFSR[7];

always @(posedge clk)
begin
  if (init) begin
    LFSR <= seed;
    init <= 1'b0;
  end
  else begin
    LFSR[0] <= feedback;
    LFSR[1] <= LFSR[0];
    LFSR[2] <= LFSR[1] ^ feedback;
    LFSR[3] <= LFSR[2] ^ feedback;
    LFSR[4] <= LFSR[3] ^ feedback;
    LFSR[5] <= LFSR[4];
    LFSR[6] <= LFSR[5];
    LFSR[7] <= LFSR[6];
  end
end

endmodule

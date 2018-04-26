`timescale 1ns / 1ps

module posedge_detector (
  input signal,
  input clk,
  output signal_rising
);

reg signal_delay;

always @(posedge clk) signal_delay <= signal;

assign signal_rising = signal & ~signal_delay;

endmodule

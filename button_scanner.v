`timescale 1ns / 1ps

module button_scanner(
  input clk,
  input button_input,
  output button_pressed,
  output button_released
);

reg button_snapshot;
reg button_snapshot_buffer;
reg [19:0] counter;

wire counter_rising;

always @(posedge clk) begin
  if (counter == 20'b1111_0100_0010_0100_0000) begin
    counter <= 0;
    button_snapshot <= button_input;
  end else counter <= counter + 1;
end

always @(posedge clk) button_snapshot_buffer <= button_snapshot;

assign button_pressed = button_snapshot & (~button_snapshot_buffer);
assign button_released = (~button_snapshot) & button_snapshot_buffer;

endmodule

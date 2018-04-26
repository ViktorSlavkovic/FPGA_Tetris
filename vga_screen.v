
`timescale 1ns / 1ps

// 1024x768 @ 60Hz
module vga_screen(
  
  // Wiring
  input        vga_clk,  // 65 MHz clock
  output       vga_hsync,
  output       vga_vsync,
  output [15:0]  vga_rgb,

  // Screen user interface
  output      on_screen,
  output [10:0]  screen_x,
  output [10:0]  screen_y,
  input  [15:0]  screen_pixel
);

`define SYNC_POLARITY 1'b0

`define H_FRONT  11'd24   
`define H_SYNC   11'd136  
`define H_BACK   11'd160 
`define H_DISP   11'd1024  
`define H_TOTAL  11'd1344 
           
`define V_FRONT  11'd3 
`define V_SYNC   11'd6    
`define V_BACK   11'd29   
`define V_DISP   11'd768
`define V_TOTAL  11'd806

////////////////////////////////////////////////////////////////////////////////
// DRIVING H_SYNC AND V_SYNC
////////////////////////////////////////////////////////////////////////////////

reg [10:0] h_cnt;
assign vga_hsync = (h_cnt <= `H_SYNC - 1'b1) ? 1'b0 : 1'b1;

reg [10:0] v_cnt;
assign vga_vsync = (v_cnt <= `V_SYNC - 1'b1) ? 1'b0 : 1'b1;

always @ (posedge vga_clk)
begin
  if(h_cnt == `H_TOTAL - 1'b1) begin
    h_cnt <= 11'd0;
    if(v_cnt < `V_TOTAL - 1'b1) begin
      v_cnt <= v_cnt + 1'b1;
    end else begin
      v_cnt <= 11'd0;
    end
  end else begin
    h_cnt <= h_cnt + 1'b1;
  end    
end

////////////////////////////////////////////////////////////////////////////////
// DRIVING RGB
////////////////////////////////////////////////////////////////////////////////

assign on_screen =
  (h_cnt >= `H_SYNC + `H_BACK - 1'b1 && h_cnt < `H_SYNC + `H_BACK + `H_DISP - 1'b1) &&
  (v_cnt >= `V_SYNC + `V_BACK && v_cnt < `V_SYNC + `V_BACK + `V_DISP) 
  ? 1'b1 : 1'b0;
            
assign screen_x = on_screen ? (h_cnt - (`H_SYNC + `H_BACK - 1'b1)) : 11'd0;
assign screen_y = on_screen ? (v_cnt - (`V_SYNC + `V_BACK - 1'b1)) : 11'd0;    

reg [15:0] vga_rgb_reg; 

always @(*) begin
  vga_rgb_reg <= screen_pixel;
end

wire vga_en;
assign vga_en =
  (h_cnt >= `H_SYNC + `H_BACK && h_cnt < `H_SYNC + `H_BACK + `H_DISP) &&
  (v_cnt >= `V_SYNC + `V_BACK && v_cnt < `V_SYNC + `V_BACK + `V_DISP) 
  ? 1'b1 : 1'b0;

assign vga_rgb = vga_en ? vga_rgb_reg : 16'd0;

endmodule


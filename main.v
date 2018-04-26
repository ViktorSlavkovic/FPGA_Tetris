`timescale 1ns / 1ps

module main(
	input CLK_50M,
	input RSTn,
  // Horizontal sync.
  output vga_hs,
  // Vertical sync.
  output vga_vs,
  // Current pixel color RGB components.
  output [4:0] vga_red,
  output [5:0] vga_green,
  output [4:0] vga_blue,
  
  input [3:0] key_in,
  output [3:0] led,
  
  output [7:0] SMG_Data,
  output [5:0] Scan_Sig
);

wire clk_sys;
wire clk_vga;

system_pll system_pll_instance (
  .CLK_IN(CLK_50M),
  .CLK_SYS(clk_sys),
  .CLK_VGA(clk_vga),
  .RESET(1'b0),
  .LOCKED()
);

reg [15:0] score = 16'd0;

seven_seg_display ssd_main(.clk(clk_sys), .x(score), .sel(Scan_Sig), .seg(SMG_Data));
//last_digit_32 asd(.x(16'd0), .x_mod(led), .x_div());
//
////assign Scan_Sig[5:0] = 6'b000000;
////assign SMG_Data[7:0] = 8'b10110110;
//
////assign led[3:0]= 4'b0011;
//
//assign vga_hs = 1'b0;
//assign vga_vs = 1'b0;
//assign vga_hs = 1'b0;
//assign vga_red = 5'd0;
//assign vga_green = 6'd0;
//assign vga_blue = 5'd0;



//////////////////////////////////

wire [7:0] prng_out;

LFSR8_11D prng_inst (
  .clk(clk_sys),
  .seed(8'b10101010),
  .LFSR_out(prng_out)
);

reg [7:0] rand_bits = 8'hFF;
always @(posedge clk_sys) rand_bits <= {rand_bits[6:0], prng_out[3]};

//////////////////////////////////

wire on_screen;
wire [10:0] screen_x;
wire [10:0] screen_y;
reg [15:0] screen_pixel;

vga_screen vga_screen_instance (
  .vga_clk(clk_vga),
  .vga_hsync(vga_hs),
  .vga_vsync(vga_vs),
  .vga_rgb({vga_red, vga_green, vga_blue}),
  
  .on_screen(on_screen),
  .screen_x(screen_x),
  .screen_y(screen_y),
  .screen_pixel(screen_pixel)
);

`define TETRIS_W 4'd10
`define TETRIS_H 6'd22
`define TETRIS_H_INVISIBLE 6'd30

`define SCREEN_W 11'd1024
`define SCREEN_H 11'd768
`define FIELD_SIZE 11'd32
`define FIELD_LD_BORDER 11'd1
`define FIELD_START_W ((`SCREEN_W - `FIELD_SIZE * `TETRIS_W) / 11'd2)
`define FIELD_END_W (`FIELD_START_W + `FIELD_SIZE * `TETRIS_W)
`define FIELD_START_H ((`SCREEN_H - `FIELD_SIZE * `TETRIS_H) / 11'd2)
`define FIELD_END_H (`FIELD_START_H + `FIELD_SIZE * `TETRIS_H)
`define OUTER_BORDER 11'd5

wire out_left;
assign out_left = screen_x < `FIELD_START_W;
wire out_right;
assign out_right = screen_x >= `FIELD_END_W;
wire out_up;
assign out_up = screen_y < `FIELD_START_H;
wire out_down;
assign out_down = screen_y >= `FIELD_END_H;

wire border_left;
assign border_left = out_left && (screen_x >= `FIELD_START_W - `OUTER_BORDER);
wire border_right;
assign border_right = out_right && (screen_x < `FIELD_END_W + `OUTER_BORDER);
wire border_up;
assign border_up = out_up && (screen_y >= `FIELD_START_H - `OUTER_BORDER);
wire border_down;
assign border_down = out_down && (screen_y < `FIELD_END_H + `OUTER_BORDER);

wire out;
assign out = out_left || out_right || out_up || out_down;
wire out_really;
assign out_really = (out_left && ~border_left) || (out_right && ~border_right) || (out_up && ~border_up) || (out_down && ~border_down);

wire[10:0] w_mod;
assign w_mod = ((screen_x - `FIELD_START_W) % `FIELD_SIZE);
wire[10:0] h_mod;
assign h_mod = ((screen_y - `FIELD_START_H) % `FIELD_SIZE);

wire[3:0] w_div;
assign w_div = ((screen_x - `FIELD_START_W) / `FIELD_SIZE);

wire[5:0] h_div;
assign h_div = `TETRIS_H - 6'd1 - ((screen_y - `FIELD_START_H) / `FIELD_SIZE);

reg [`TETRIS_W-1:0] tetris_bool [`TETRIS_H_INVISIBLE-1:0];
reg [3:0] tetris_color [`TETRIS_H_INVISIBLE-1:0][`TETRIS_W-1:0];

wire [15:0] figures_bool [7:0][4:0];
wire [3:0] figures_height[7:0][4:0];
wire [3:0] figures_color[7:0];

wire [15:0] colors[15:0];
assign colors[ 0] = 16'b00000_000000_00000; // Black    0
assign colors[ 1] = 16'b11111_000000_00000; // Red      1
assign colors[ 2] = 16'b00000_111111_00000; // Lime     2
assign colors[ 3] = 16'b00000_000000_11111; // Blue     3
assign colors[ 4] = 16'b00000_111111_11111; // Cyan     4
assign colors[ 5] = 16'b11111_000000_11111; // Magenta  5
assign colors[ 6] = 16'b11111_111111_00000; // Yellow   6
assign colors[ 7] = 16'b11111_101001_00000; // Orange   7
assign colors[ 8] = 16'b10000_000000_10000; // Purple   8
assign colors[ 9] = 16'b10000_100000_10000; // Gray     9
assign colors[10] = 16'b11000_110000_11000; // Silver   A
assign colors[11] = 16'b10000_000000_00000; // Maroon   B
assign colors[12] = 16'b10000_100000_00000; // Olive    C
assign colors[13] = 16'b00000_100000_00000; // Green    D
assign colors[14] = 16'b00000_100000_10000; // Teal     E
assign colors[15] = 16'b11111_111111_11111; // White    F

// I figure
assign figures_color[0] = 4'h4;
assign figures_bool[0][0] = 16'b1000100010001000; assign figures_height[0][0] = 4'd4;
assign figures_bool[0][1] = 16'b1111000000000000; assign figures_height[0][1] = 4'd1;
assign figures_bool[0][2] = 16'b1000100010001000; assign figures_height[0][2] = 4'd4;
assign figures_bool[0][3] = 16'b1111000000000000; assign figures_height[0][3] = 4'd1;
// O figure
assign figures_color[1] = 4'h6;
assign figures_bool[1][0] = 16'b1100110000000000; assign figures_height[1][0] = 4'd2;
assign figures_bool[1][1] = 16'b1100110000000000; assign figures_height[1][1] = 4'd2;
assign figures_bool[1][2] = 16'b1100110000000000; assign figures_height[1][2] = 4'd2;
assign figures_bool[1][3] = 16'b1100110000000000; assign figures_height[1][3] = 4'd2;
// T figure
assign figures_color[2] = 4'h8;
assign figures_bool[2][0] = 16'b1110010000000000; assign figures_height[2][0] = 4'd2;
assign figures_bool[2][1] = 16'b0100110001000000; assign figures_height[2][1] = 4'd3;
assign figures_bool[2][2] = 16'b0100111000000000; assign figures_height[2][2] = 4'd2;
assign figures_bool[2][3] = 16'b1000110010000000; assign figures_height[2][3] = 4'd3;
// Z figure
assign figures_color[3] = 4'h1;
assign figures_bool[3][0] = 16'b1100011000000000; assign figures_height[3][0] = 4'd2;
assign figures_bool[3][1] = 16'b0100110010000000; assign figures_height[3][1] = 4'd3;
assign figures_bool[3][2] = 16'b1100011000000000; assign figures_height[3][2] = 4'd2;
assign figures_bool[3][3] = 16'b0100110010000000; assign figures_height[3][3] = 4'd3;
// S figure
assign figures_color[4] = 4'hD;
assign figures_bool[4][0] = 16'b0110110000000000; assign figures_height[4][0] = 4'd2;
assign figures_bool[4][1] = 16'b1000110001000000; assign figures_height[4][1] = 4'd3;
assign figures_bool[4][2] = 16'b0110110000000000; assign figures_height[4][2] = 4'd2;
assign figures_bool[4][3] = 16'b1000110001000000; assign figures_height[4][3] = 4'd3;
// L figure
assign figures_color[5] = 4'h7;
assign figures_bool[5][0] = 16'b1000100011000000; assign figures_height[5][0] = 4'd3;
assign figures_bool[5][1] = 16'b1110100000000000; assign figures_height[5][1] = 4'd2;
assign figures_bool[5][2] = 16'b1100010001000000; assign figures_height[5][2] = 4'd3;
assign figures_bool[5][3] = 16'b0010111000000000; assign figures_height[5][3] = 4'd2;
// J figure
assign figures_color[6] = 4'h3;
assign figures_bool[6][0] = 16'b0100010011000000; assign figures_height[6][0] = 4'd3;
assign figures_bool[6][1] = 16'b1000111000000000; assign figures_height[6][1] = 4'd2;
assign figures_bool[6][2] = 16'b1100100010000000; assign figures_height[6][2] = 4'd3;
assign figures_bool[6][3] = 16'b1110001000000000; assign figures_height[6][3] = 4'd2;

reg [2:0] curr_figure = 3'd6;
reg [1:0] curr_figure_rot = 2'd2;
reg [3:0] curr_figure_w = 4'd6;
reg [5:0] curr_figure_h = 6'd13;

wire[3:0] curr_figure_hh;
assign curr_figure_hh = figures_height[curr_figure][curr_figure_rot];

wire[3:0] curr_figure_ww;
assign curr_figure_ww = figures_height[curr_figure][curr_figure_rot + 2'b01];

wire[3:0] rot_figure_hh;
assign rot_figure_hh = curr_figure_ww;

wire[3:0] rot_figure_ww;
assign rot_figure_ww = curr_figure_hh;

wire curr_figure_h_min_ok;
assign curr_figure_h_min_ok = 1'b1; //curr_figure_h >= curr_figure_hh + 6'd5; // nebitno sad skroz kad ima 5 punih dole

wire curr_figure_w_max_ok;
assign curr_figure_w_max_ok = curr_figure_w + curr_figure_ww < `TETRIS_W;

wire[3:0] rot_figure_w_max_ok;
assign rot_figure_w_max_ok = curr_figure_w + rot_figure_ww <= `TETRIS_W;

wire [3:0] curr_figure_w_cmp_l;
assign curr_figure_w_cmp_l = ((`TETRIS_W-4'd1)-curr_figure_w);

wire [3:0] rot_figure_w_cmp_l;
assign rot_figure_w_cmp_l = curr_figure_w_cmp_l;

wire [3:0] mol_figure_w_cmp_l;
assign mol_figure_w_cmp_l = curr_figure_w_cmp_l+4'd1;

wire [3:0] mor_figure_w_cmp_l;
assign mor_figure_w_cmp_l = curr_figure_w_cmp_l-4'd1;

wire [1:0] rol_figure_rot;
assign rol_figure_rot = curr_figure_rot + 2'b11;

wire [1:0] ror_figure_rot;
assign ror_figure_rot = curr_figure_rot + 2'b01;

wire [5:0] merge_curr_figure_h_m0;
assign merge_curr_figure_h_m0 = curr_figure_h;

wire [5:0] merge_curr_figure_h_m1;
assign merge_curr_figure_h_m1 = merge_curr_figure_h_m0 - 6'd1;

wire [5:0] merge_curr_figure_h_m2;
assign merge_curr_figure_h_m2 = merge_curr_figure_h_m1 - 6'd1;

wire [5:0] merge_curr_figure_h_m3;
assign merge_curr_figure_h_m3 = merge_curr_figure_h_m2 - 6'd1;

wire can_down;
assign can_down = curr_figure_h_min_ok &&
                  ({6'b000000, figures_bool[curr_figure][curr_figure_rot][15:12]} & ((({tetris_bool[curr_figure_h-1], 3'b000}) >> curr_figure_w_cmp_l)) ) == 4'b0000 &&
                  ({6'b000000, figures_bool[curr_figure][curr_figure_rot][11: 8]} & ((({tetris_bool[curr_figure_h-2], 3'b000}) >> curr_figure_w_cmp_l)) ) == 4'b0000 &&
                  ({6'b000000, figures_bool[curr_figure][curr_figure_rot][ 7: 4]} & ((({tetris_bool[curr_figure_h-3], 3'b000}) >> curr_figure_w_cmp_l)) ) == 4'b0000 &&
                  ({6'b000000, figures_bool[curr_figure][curr_figure_rot][ 3: 0]} & ((({tetris_bool[curr_figure_h-4], 3'b000}) >> curr_figure_w_cmp_l)) ) == 4'b0000;

wire can_down_rol;
assign can_down_rol = curr_figure_h_min_ok && rot_figure_w_max_ok &&
                      ({6'b000000, figures_bool[curr_figure][rol_figure_rot][15:12]} & (({tetris_bool[merge_curr_figure_h_m0], 3'b000} >> rot_figure_w_cmp_l))) == 4'b0000 &&
                      ({6'b000000, figures_bool[curr_figure][rol_figure_rot][11: 8]} & (({tetris_bool[merge_curr_figure_h_m1], 3'b000} >> rot_figure_w_cmp_l))) == 4'b0000 &&
                      ({6'b000000, figures_bool[curr_figure][rol_figure_rot][ 7: 4]} & (({tetris_bool[merge_curr_figure_h_m2], 3'b000} >> rot_figure_w_cmp_l))) == 4'b0000 &&
                      ({6'b000000, figures_bool[curr_figure][rol_figure_rot][ 3: 0]} & (({tetris_bool[merge_curr_figure_h_m3], 3'b000} >> rot_figure_w_cmp_l))) == 4'b0000;

wire can_down_ror;
assign can_down_ror = curr_figure_h_min_ok && rot_figure_w_max_ok &&
                      ({6'b000000, figures_bool[curr_figure][ror_figure_rot][15:12]} & (({tetris_bool[merge_curr_figure_h_m0], 3'b000} >> rot_figure_w_cmp_l)))  == 4'b0000 &&
                      ({6'b000000, figures_bool[curr_figure][ror_figure_rot][11: 8]} & (({tetris_bool[merge_curr_figure_h_m1], 3'b000} >> rot_figure_w_cmp_l)))  == 4'b0000 &&
                      ({6'b000000, figures_bool[curr_figure][ror_figure_rot][ 7: 4]} & (({tetris_bool[merge_curr_figure_h_m2], 3'b000} >> rot_figure_w_cmp_l)))  == 4'b0000 &&
                      ({6'b000000, figures_bool[curr_figure][ror_figure_rot][ 3: 0]} & (({tetris_bool[merge_curr_figure_h_m3], 3'b000} >> rot_figure_w_cmp_l)))  == 4'b0000;

wire can_down_mol;
assign can_down_mol = curr_figure_h_min_ok && (curr_figure_w > 0) &&
                      ({6'b000000, figures_bool[curr_figure][curr_figure_rot][15:12]} & (({tetris_bool[merge_curr_figure_h_m0], 3'b000} >> mol_figure_w_cmp_l)))  == 4'b0000 &&
                      ({6'b000000, figures_bool[curr_figure][curr_figure_rot][11: 8]} & (({tetris_bool[merge_curr_figure_h_m1], 3'b000} >> mol_figure_w_cmp_l)))  == 4'b0000 &&
                      ({6'b000000, figures_bool[curr_figure][curr_figure_rot][ 7: 4]} & (({tetris_bool[merge_curr_figure_h_m2], 3'b000} >> mol_figure_w_cmp_l)))  == 4'b0000 &&
                      ({6'b000000, figures_bool[curr_figure][curr_figure_rot][ 3: 0]} & (({tetris_bool[merge_curr_figure_h_m3], 3'b000} >> mol_figure_w_cmp_l)))  == 4'b0000;

wire can_down_mor;
assign can_down_mor = curr_figure_h_min_ok && curr_figure_w_max_ok &&
                      ({6'b000000, figures_bool[curr_figure][curr_figure_rot][15:12]} & (({tetris_bool[merge_curr_figure_h_m0], 3'b000} >> mor_figure_w_cmp_l)))  == 4'b0000 &&
                      ({6'b000000, figures_bool[curr_figure][curr_figure_rot][11: 8]} & (({tetris_bool[merge_curr_figure_h_m1], 3'b000} >> mor_figure_w_cmp_l)))  == 4'b0000 &&
                      ({6'b000000, figures_bool[curr_figure][curr_figure_rot][ 7: 4]} & (({tetris_bool[merge_curr_figure_h_m2], 3'b000} >> mor_figure_w_cmp_l)))  == 4'b0000 &&
                      ({6'b000000, figures_bool[curr_figure][curr_figure_rot][ 3: 0]} & (({tetris_bool[merge_curr_figure_h_m3], 3'b000} >> mor_figure_w_cmp_l)))  == 4'b0000;

reg [25:0] move_counter = 0;
always @(posedge clk_sys) begin
  move_counter <= move_counter + 26'd1;
end

wire cnt_23_rising;
posedge_detector pdi0 (
  .signal(move_counter[23]),
  .clk(clk_sys),
  .signal_rising(cnt_23_rising)
);

wire cnt_20_rising;
posedge_detector pdi1 (
  .signal(move_counter[20]),
  .clk(clk_sys),
  .signal_rising(cnt_20_rising)
);

reg is_game_over = 1'b1;
reg merging = 1'b0;
reg [3:0] w_merge;

wire [3:0] merge_tetris_bool_w;
assign merge_tetris_bool_w = (`TETRIS_W-4'd1) - w_merge;

wire [3:0] merge_figures_bool_w_3;
assign merge_figures_bool_w_3 = (4'd3 - (w_merge - curr_figure_w));

wire [3:0] merge_figures_bool_w_2;
assign merge_figures_bool_w_2 = merge_figures_bool_w_3 + 4'd4;

wire [3:0] merge_figures_bool_w_1;
assign merge_figures_bool_w_1 = merge_figures_bool_w_2 + 4'd4;

wire [3:0] merge_figures_bool_w_0;
assign merge_figures_bool_w_0 = merge_figures_bool_w_1 + 4'd4;

wire [4:0] key_pressed;
wire [4:0] key_released;

button_scanner bsi0 (
  .clk(clk_sys),
  .button_input(~key_in[0]),
  .button_pressed(key_pressed[0]),
  .button_released(key_released[0])
);

button_scanner bsi1 (
  .clk(clk_sys),
  .button_input(~key_in[1]),
  .button_pressed(key_pressed[1]),
  .button_released(key_released[1])
);

button_scanner bsi2 (
  .clk(clk_sys),
  .button_input(~key_in[2]),
  .button_pressed(key_pressed[2]),
  .button_released(key_released[2])
);

button_scanner bsi3 (
  .clk(clk_sys),
  .button_input(~key_in[3]),
  .button_pressed(key_pressed[3]),
  .button_released(key_released[3])
);

button_scanner bsi4 (
  .clk(clk_sys),
  .button_input(~RSTn),
  .button_pressed(key_pressed[4]),
  .button_released(key_released[4])
);

wire [2:0] next_figure;
wire [1:0] next_rot;

assign next_figure = (rand_bits[2:0] == 3'b111) ? rand_bits[2:0] - 3'b001 : rand_bits[2:0];
assign next_rot = rand_bits[4:3];

assign led[3:0] = {next_figure[2:0], 1'b0};

reg contracting = 1'b0;
reg [5:0] contracting_h;
reg [5:0] contracting_add;
reg fast_down = 6'd0;

reg resetting = 1'b0;
reg [5:0] res_h;

wire [5:0] merge_color_idx_helper;
assign merge_color_idx_helper = {merge_tetris_bool_w, 2'b00};

wire [5:0] merge_color_idx_l;
assign merge_color_idx_l = {merge_tetris_bool_w, 2'b00};

integer i;
always @(posedge clk_sys) begin
  if (~resetting) begin
    if (key_pressed[2]) fast_down <= 1'b1;
    else if (key_released[2]) fast_down <= 1'b0;
  end
  
  if (key_pressed[4]) begin
    resetting <= 1'b1;
    tetris_bool[0] <= 10'b1111111111;
    tetris_bool[1] <= 10'b1111111111;
    tetris_bool[2] <= 10'b1111111111;
    tetris_bool[3] <= 10'b1111111111;
    tetris_bool[4] <= 10'b1111111111;
    res_h <= 6'd5;
  end
  else if (resetting) begin
    if (res_h == `TETRIS_H_INVISIBLE) begin
      resetting <= 1'b0;
      fast_down <= 1'b0;
      curr_figure <= next_figure;
      curr_figure_rot <= next_rot;
      curr_figure_h <= `TETRIS_H_INVISIBLE - 6'd1;
      curr_figure_w <= 4'd3;
      is_game_over <= 1'b0;
      score <= 16'd0;
    end
    else begin
      tetris_bool[res_h] <= 10'b0000000000;
      for (i = 0; i < 10; i = i + 1) tetris_color[res_h][i] <= 4'b0000;
      res_h <= res_h + 1;
    end
  end
  else if (((~fast_down & cnt_23_rising) | (fast_down & cnt_20_rising)) & ~merging & ~contracting) begin
    if (can_down) curr_figure_h <= curr_figure_h - 6'd1;
    else if (curr_figure_h > 6'd25) is_game_over <= 1'b1;
    else begin
      merging <= 1'b1;
      w_merge <= curr_figure_w;
    end
  end
  else if (merging) begin
    if (figures_bool[curr_figure][curr_figure_rot][merge_figures_bool_w_0]) begin
      tetris_bool[merge_curr_figure_h_m0][merge_tetris_bool_w] <= 1'b1;
      tetris_color[merge_curr_figure_h_m0][merge_tetris_bool_w] <= figures_color[curr_figure];
    end
    if (figures_bool[curr_figure][curr_figure_rot][merge_figures_bool_w_1]) begin
      tetris_bool[merge_curr_figure_h_m1][merge_tetris_bool_w] <= 1'b1;
      tetris_color[merge_curr_figure_h_m1][merge_tetris_bool_w] <= figures_color[curr_figure];
    end
    if (figures_bool[curr_figure][curr_figure_rot][merge_figures_bool_w_2]) begin
      tetris_bool[merge_curr_figure_h_m2][merge_tetris_bool_w] <= 1'b1;
      tetris_color[merge_curr_figure_h_m2][merge_tetris_bool_w] <= figures_color[curr_figure];
    end
    if (figures_bool[curr_figure][curr_figure_rot][merge_figures_bool_w_3]) begin
      tetris_bool[merge_curr_figure_h_m3][merge_tetris_bool_w] <= 1'b1;
      tetris_color[merge_curr_figure_h_m3][merge_tetris_bool_w] <= figures_color[curr_figure];
    end

    if (w_merge == curr_figure_w + 4'd3) begin
      merging <= 1'b0;
      curr_figure <= next_figure;
      curr_figure_rot <= next_rot;
      curr_figure_h <= `TETRIS_H_INVISIBLE - 6'd1;
      curr_figure_w <= 4'd3;
      contracting <= 1'b1;
      contracting_h <= 6'd5;
      contracting_add <= 6'd0;
    end
    else w_merge <= w_merge + 4'd1;
  end
  else if (contracting) begin
      if (tetris_bool[contracting_h] == 10'b0000000000) begin
        contracting <= 1'b0;
        if (contracting_add[0] | contracting_add[1] | contracting_add[2]) begin
          if (contracting_add[2]) score <= score + 16'd800;
          else if (~contracting_add[0]) score <= score + 16'd300;
          else score <= (contracting_add[1]) ? score + 16'd500 : score + 16'd100;
        end
      end
      else if (tetris_bool[contracting_h + contracting_add] == 10'b1111111111) begin
        contracting_add <= contracting_add + 1;
      end
      else begin
        contracting_h <= contracting_h + 10'd1;
        tetris_bool[contracting_h] <= tetris_bool[contracting_h + contracting_add];
        for (i = 0; i < 10; i = i+1) begin
          tetris_color[contracting_h][i] <= tetris_color[contracting_h + contracting_add][i];
        end
      end
  end
  else if (key_pressed[0]) begin
    curr_figure_rot <= can_down_rol ? curr_figure_rot + 2'b11 : curr_figure_rot;
  end
  else if (key_pressed[1]) begin
    curr_figure_w <= can_down_mol ? curr_figure_w - 4'b0001 : curr_figure_w;
  end
  else if (key_pressed[3]) begin
    curr_figure_w <= can_down_mor ? curr_figure_w + 4'b0001 : curr_figure_w;
  end
end

always @(posedge clk_sys) begin
  if (on_screen) begin
    if (is_game_over) begin
      screen_pixel <= 16'b1111100000000000;
    end
    else if (out_really) begin
//      if (screen_x == 11'd100 || screen_x == 11'd200 || screen_x == 11'd300 || screen_x == 11'd400) screen_pixel <= 16'b1111100000000000;
//      else if (screen_x < 100) screen_pixel <= can_down ? 16'hFFFF : 16'd0;
//      else if (screen_x < 200) screen_pixel <= can_down_rol ? 16'hFFFF : 16'd0;
//      else if (screen_x < 300) screen_pixel <= can_down_ror ? 16'hFFFF : 16'd0;
//      else if (screen_x < 400) screen_pixel <= can_down_mol ? 16'hFFFF : 16'd0;
//      else if (screen_x < 500) screen_pixel <= can_down_mor ? 16'hFFFF : 16'd0;
//      else
      screen_pixel <= 16'b11000_110000_11000;  // Silver
    end
    else if (out) screen_pixel <= 16'b10000_000000_00000; // Maroon
    else if ( (w_mod == 0 || w_mod == (`FIELD_SIZE - 11'd1)) || (h_mod == 11'd0 || h_mod == (`FIELD_SIZE - 11'd1)) ) begin
      screen_pixel <= 16'b00000_100000_10000; // Teal
    end
    else if (w_div >= curr_figure_w && w_div < curr_figure_w + 4'd4 && h_div + 6'd5 <= curr_figure_h && h_div + 6'd5 > curr_figure_h - 6'd4 &&
             (figures_bool[curr_figure][curr_figure_rot][((6'd3 - (curr_figure_h - h_div - 6'd5)) << 2) + (6'd3 - (w_div - curr_figure_w))])) begin
      screen_pixel <= colors[figures_color[curr_figure]];
    end
    else if (tetris_bool[h_div + 6'd5][(`TETRIS_W-4'd1) - w_div]) begin
      screen_pixel <= colors[tetris_color[h_div + 6'd5][(`TETRIS_W-4'd1) - w_div]];
    end
    else begin
      screen_pixel <= 16'b11111_111111_11111; // White
    end
  end
end

endmodule

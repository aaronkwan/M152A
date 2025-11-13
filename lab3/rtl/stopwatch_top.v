`timescale 1ns / 1ps

module stopwatch_top(
  input  wire clk_100mhz,
  input  wire reset_btn,
  input  wire pause_btn,
  input  wire sel_sw,
  input  wire adj_sw,
  output wire [7:0] seg,
  output wire [3:0] an
);

  // Clock enables
  wire en_1hz, en_2hz, en_fast, en_blink;

  // Debounced controls
  wire rst_level;
  wire pause_rise;
  wire sel_level;
  wire adj_level;

  // Time digits and blink mask
  wire [3:0] hex3, hex2, hex1, hex0;
  wire [3:0] blink_mask;

  // Clock generator
  clk_gen u_clk_gen(
    .clk_100mhz(clk_100mhz),
    .en_1hz    (en_1hz),
    .en_2hz    (en_2hz),
    .en_fast   (en_fast),
    .en_blink  (en_blink)
  );

  // Input conditioning for reset (use level for synchronous reset)
  input_sync_debounce u_db_reset(
    .clk      (clk_100mhz),
    .en_sample(en_fast),
    .din_async(reset_btn),
    .level    (rst_level),
    .rise     ()
  );

  // Pause: use rising edge to toggle run
  input_sync_debounce u_db_pause(
    .clk      (clk_100mhz),
    .en_sample(en_fast),
    .din_async(pause_btn),
    .level    (),
    .rise     (pause_rise)
  );

  // Switches (debounced levels)
  input_sync_debounce u_db_sel(
    .clk      (clk_100mhz),
    .en_sample(en_fast),
    .din_async(sel_sw),
    .level    (sel_level),
    .rise     ()
  );
  input_sync_debounce u_db_adj(
    .clk      (clk_100mhz),
    .en_sample(en_fast),
    .din_async(adj_sw),
    .level    (adj_level),
    .rise     ()
  );

  // Time core
  time_core u_time(
    .clk        (clk_100mhz),
    .rst        (rst_level),
    .en_1hz     (en_1hz),
    .en_2hz     (en_2hz),
    .adj        (adj_level),
    .sel        (sel_level),
    .pause_edge (pause_rise),
    .hex3       (hex3),
    .hex2       (hex2),
    .hex1       (hex1),
    .hex0       (hex0),
    .blink_mask (blink_mask)
  );

  // Display driver
  display_driver u_disp(
    .clk       (clk_100mhz),
    .adj       (adj_level),
    .blink_mask(blink_mask),
    .en_blink  (en_blink),
    .hex3      (hex3),
    .hex2      (hex2),
    .hex1      (hex1),
    .hex0      (hex0),
    .an        (an),
    .seg       (seg)
  );

endmodule

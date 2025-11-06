`timescale 1ns / 1ps

module input_sync_debounce(
  input  wire clk,        // 100 MHz
  input  wire en_sample,  // ~381 Hz pulse
  input  wire din_async,  // raw async input
  output reg  level,      // debounced level
  output reg  rise        // 1-cycle pulse on rising edge of level
);

  // 2-FF synchronizer
  reg sync_0, sync_1;
  always @(posedge clk) begin
    sync_0 <= din_async;
    sync_1 <= sync_0;
  end

  // Debounce via 4-sample unanimity window at en_sample rate (~10ms window)
  reg [3:0] sr;
  reg       level_nxt;
  reg       level_d;

  always @(posedge clk) begin
    // Under-sample on en_sample
    if (en_sample) begin
      sr <= {sr[2:0], sync_1};
      // All ones → 1, all zeros → 0, else hold
      if (&sr)       level_nxt <= 1'b1;
      else if (~|sr) level_nxt <= 1'b0;
      // else retain level_nxt
    end

    // Commit debounced level synchronously
    level   <= level_nxt;
    // Rising edge detect
    level_d <= level_nxt;
    rise    <= level_nxt & ~level_d;
  end

  initial begin
    sr        = 4'b0000;
    level     = 1'b0;
    level_nxt = 1'b0;
    level_d   = 1'b0;
    rise      = 1'b0;
  end

endmodule


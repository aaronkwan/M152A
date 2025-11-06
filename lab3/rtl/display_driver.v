`timescale 1ns / 1ps

module display_driver(
  input  wire clk,                // 100 MHz
  input  wire adj,
  input  wire [3:0] blink_mask,   // 1s indicate digits to blink
  input  wire en_blink,           // pulse to toggle blink state
  input  wire [3:0] hex3, hex2, hex1, hex0,
  output reg  [3:0] an,           // active-low anodes
  output reg  [7:0] seg           // active-low segments [6:0] + dp
);

  // Refresh counter for multiplexing (≈381 Hz per digit)
  localparam N = 18;
  reg [N-1:0] refresh;

  // Blink state toggles on en_blink pulses
  reg blink_state;

  // Selected digit and value
  reg [1:0] idx;
  reg [3:0] hex_in;
  reg [6:0] seg7; // active-low 7-bit

  always @(posedge clk) begin
    refresh <= refresh + 1'b1;
    if (en_blink) blink_state <= ~blink_state;
  end

  // Select digit based on MSBs of refresh
  always @* begin
    case (refresh[N-1:N-2])
      // Map left->right to indices 0,1,2,3 (hex0..hex3)
      2'b00: begin an = 4'b0111; idx = 2'd0; hex_in = hex0; end // leftmost
      2'b01: begin an = 4'b1011; idx = 2'd1; hex_in = hex1; end
      2'b10: begin an = 4'b1101; idx = 2'd2; hex_in = hex2; end
      2'b11: begin an = 4'b1110; idx = 2'd3; hex_in = hex3; end // rightmost
      default: begin an = 4'b1111; idx = 2'd0; hex_in = 4'd0; end
    endcase
  end

  // BCD to 7-seg (active-low)
  always @* begin
    case (hex_in)
      4'h0: seg7 = 7'b0000001;
      4'h1: seg7 = 7'b1001111;
      4'h2: seg7 = 7'b0010010;
      4'h3: seg7 = 7'b0000110;
      4'h4: seg7 = 7'b1001100;
      4'h5: seg7 = 7'b0100100;
      4'h6: seg7 = 7'b0100000;
      4'h7: seg7 = 7'b0001111;
      4'h8: seg7 = 7'b0000000;
      4'h9: seg7 = 7'b0000100;
      default: seg7 = 7'b1111110; // dash/minus
    endcase
  end

  // Compose segments with blink gating
  always @* begin
    // default: dp off (1), segments according to decode (active-low)
    seg = {1'b1, seg7[0], seg7[1], seg7[2], seg7[3], seg7[4], seg7[5], seg7[6]};
    // Blink only in adjust mode for selected digits
    if (adj) begin
      if (blink_mask[idx] && (blink_state == 1'b0)) begin
        seg = 8'b1111_1111; // all off during blink off phase
      end
    end
  end

  initial begin
    refresh     = {N{1'b0}};
    blink_state = 1'b0;
  end

endmodule

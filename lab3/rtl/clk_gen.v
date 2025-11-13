`timescale 1ns / 1ps

module clk_gen(
  input  wire clk_100mhz,
  output reg  en_1hz,
  output reg  en_2hz,
  output reg  en_fast,
  output reg  en_blink
);

  // 100 MHz base clock
  // Generate one-cycle enable pulses for required rates.

  // 1 Hz: 100,000,000 cycles
  localparam integer DIV_1HZ   = 100_000_000;
  // 2 Hz: 50,000,000 cycles
  localparam integer DIV_2HZ   = 50_000_000;
  // fast (≈381 Hz): pulse on 2^18 wrap
  localparam integer CW_FAST   = 18; // counter width
  // blink 1.5 Hz = 66,666,666 cycles
  localparam integer DIV_BLINK = 66_666_666; 

  reg [26:0] cnt_1hz;
  reg [25:0] cnt_2hz; // 26 bits enough for 50e6
  reg [CW_FAST-1:0] cnt_fast;
  reg [24:0] cnt_blink; // 25 bits enough for 25e6

  always @(posedge clk_100mhz) begin
    // 1 Hz
    if (cnt_1hz == 0) begin
      cnt_1hz <= DIV_1HZ-1;
      en_1hz  <= 1'b1;
    end else begin
      cnt_1hz <= cnt_1hz - 1;
      en_1hz  <= 1'b0;
    end

    // 2 Hz
    if (cnt_2hz == 0) begin
      cnt_2hz <= DIV_2HZ-1;
      en_2hz  <= 1'b1;
    end else begin
      cnt_2hz <= cnt_2hz - 1;
      en_2hz  <= 1'b0;
    end

    // fast: pulse on wrap of 18-bit counter (~381 Hz)
    cnt_fast <= cnt_fast + 1'b1;
    en_fast  <= (cnt_fast == {CW_FAST{1'b1}});

    // blink 4 Hz
    if (cnt_blink == 0) begin
      cnt_blink <= DIV_BLINK-1;
      en_blink  <= 1'b1;
    end else begin
      cnt_blink <= cnt_blink - 1;
      en_blink  <= 1'b0;
    end
  end

  initial begin
    cnt_1hz   = DIV_1HZ-1;
    cnt_2hz   = DIV_2HZ-1;
    cnt_fast  = {CW_FAST{1'b0}};
    cnt_blink = DIV_BLINK-1;
    en_1hz    = 1'b0;
    en_2hz    = 1'b0;
    en_fast   = 1'b0;
    en_blink  = 1'b0;
  end

endmodule

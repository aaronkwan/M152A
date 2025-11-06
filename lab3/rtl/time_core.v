`timescale 1ns / 1ps

module time_core(
  input  wire clk,
  input  wire rst,
  input  wire en_1hz,
  input  wire en_2hz,
  input  wire adj,
  input  wire sel,          // 0=minutes, 1=seconds
  input  wire pause_edge,   // toggle run on rising edge
  output reg  [3:0] hex3,   // M10
  output reg  [3:0] hex2,   // M1
  output reg  [3:0] hex1,   // S10
  output reg  [3:0] hex0,   // S1
  output reg  [3:0] blink_mask // which digits blink in adjust mode
);

  reg run; // 1 = counting in normal mode

  // Increment helpers
  task inc_seconds;
  begin
    if (hex0 < 4'd9) begin
      hex0 <= hex0 + 1'b1;
    end else begin
      hex0 <= 4'd0;
      if (hex1 < 4'd5) begin
        hex1 <= hex1 + 1'b1;
      end else begin
        hex1 <= 4'd0;
        // minutes cascade
        if (hex2 < 4'd9) begin
          hex2 <= hex2 + 1'b1;
        end else begin
          hex2 <= 4'd0;
          if (hex3 < 4'd9) begin
            hex3 <= hex3 + 1'b1;
          end else begin
            hex3 <= 4'd0; // 99:59 → 00:00
          end
        end
      end
    end
  end
  endtask

  task inc_minutes;
  begin
    if (hex2 < 4'd9) begin
      hex2 <= hex2 + 1'b1;
    end else begin
      hex2 <= 4'd0;
      if (hex3 < 4'd9) begin
        hex3 <= hex3 + 1'b1;
      end else begin
        hex3 <= 4'd0; // 99 → 00
      end
    end
  end
  endtask

  task inc_seconds_only;
  begin
    if (hex0 < 4'd9) begin
      hex0 <= hex0 + 1'b1;
    end else begin
      hex0 <= 4'd0;
      if (hex1 < 4'd5) begin
        hex1 <= hex1 + 1'b1;
      end else begin
        hex1 <= 4'd0; // 59 → 00, minutes frozen in adjust seconds
      end
    end
  end
  endtask

  // Blink mask based on selection
  always @* begin
    blink_mask = adj ? (sel ? 4'b0011 : 4'b1100) : 4'b0000;
  end

  always @(posedge clk) begin
    if (rst) begin
      hex3 <= 4'd0; hex2 <= 4'd0; hex1 <= 4'd0; hex0 <= 4'd0;
      run  <= 1'b1; // start running after reset
    end else begin
      // Pause toggle
      if (pause_edge) run <= ~run;

      if (!adj) begin
        // Normal mode: increment seconds at 1 Hz if running
        if (run && en_1hz) begin
          inc_seconds();
        end
      end else begin
        // Adjust mode: halt normal increments, increment selected field at 2 Hz
        if (en_2hz) begin
          if (sel == 1'b0) begin
            inc_minutes();
          end else begin
            inc_seconds_only();
          end
        end
      end
    end
  end

endmodule


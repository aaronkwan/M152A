# Lab 3 Stopwatch — Detailed Implementation Plan

This plan references context.md and fulfills the requirements in PRD.md. It breaks the work into clear modules, clocking, I/O handling, constraints, verification, and delivery steps suitable for a Basys 3 (Artix‑7) Vivado project.

## 1) System Architecture

- Top module `stopwatch_top` integrates:
  - `clk_gen` — derives 1 Hz, 2 Hz, fast mux clock (50–700 Hz), and blink clock (>1 Hz, ≠ 2 Hz) from 100 MHz.
  - `input_sync_debounce` — per button/switch: 2‑FF synchronizer + debouncer sampled by fast clock.
  - `time_core` — BCD counters for MM:SS with normal and adjust modes.
  - `display_driver` — 7‑segment BCD decode + 4‑digit multiplexing with blink masking.
  - Edge/hold logic — “pause” toggling and “reset” handling.

Inputs/Outputs
- Inputs: `clk_100mhz`, `reset_btn`, `pause_btn`, `sel_sw`, `adj_sw`.
- Outputs: `seg[7:0]` (active‑low segments incl. dp), `an[3:0]` (active‑low anodes).

Notes
- Basys 3 master clock pin is W5 per Basys-3 Master XDC (see context.md E. XDC). PRD mentions V10; verify board file and use W5.
- All external async inputs must be synchronized before use (TR 2.2).

## 2) Clocking Strategy (TR 1)

`clk_gen` divides 100 MHz into four enables or divided clocks:
- 1 Hz clock enable for normal seconds increment.
- 2 Hz clock enable for adjust mode increments.
- Fast clock for display mux and debouncer under‑sampling: select ~381 Hz via power‑of‑two divider (N=18 as in context.md displayDriver).
- Blink clock for adjustment blink, >1 Hz and not 2 Hz. Use ~4 Hz enable.

Implementation details
- Prefer single always @(posedge clk_100mhz) with free‑running counters creating one‑cycle enable pulses for each target rate to avoid clock domain complexity.
- Example divisors (100 MHz):
  - 1 Hz: 100_000_000 cycles
  - 2 Hz: 50_000_000 cycles
  - Fast mux: 2^18 ≈ 381 Hz
  - Blink: 25_000_000 cycles (4 Hz) or 12_500_000 (8 Hz)
- Export as `en_1hz`, `en_2hz`, `en_fast`, `en_blink` (one‑cycle pulses), and optionally `clk_fast` for mux counter convenience.

## 3) Input Integrity (TR 2)

For each async input (`reset_btn`, `pause_btn`, `sel_sw`, `adj_sw`):
- 2‑FF synchronizer clocked by `clk_100mhz`.
- Debouncer sampled/updated at fast rate (50–700 Hz) using `en_fast` under‑sampling:
  - Option A (counter): on state change intent, count N consecutive samples equal before committing. N≈3–5 yields ~8–13 ms at 381 Hz.
  - Option B (shift register): require all bits equal over window.
- Produce clean, single‑cycle edges where needed:
  - `reset_pulse` — synchronous one‑cycle pulse for state machines.
  - `pause_edge` — rising‑edge detect to toggle run/stop.
  - `sel_level`, `adj_level` — stable levels for mode selection.

## 4) Time Core (FR 1, FR 2, FR 3)

Module `time_core` manages BCD digits and modes.

State/Registers
- `hex0` S1 (0–9), `hex1` S10 (0–5), `hex2` M1 (0–9), `hex3` M10 (0–9).
- `run` flag toggled by `pause_edge` (start true after reset release).

Normal Mode (ADJ=0)
- On `en_1hz` when `run=1`, increment seconds. Cascade to minutes at 59→00 and 99:59→00:00 rollover.

Adjust Mode (ADJ=1)
- Halt normal increments.
- On `en_2hz`, increment only selected field by SEL:
  - SEL=0 → adjust minutes: increment `{hex3,hex2}` with cascade 09→10 etc., seconds `{hex1,hex0}` frozen.
  - SEL=1 → adjust seconds: increment `{hex1,hex0}` with 59→00, minutes frozen.
- Provide outputs `blink_mask[3:0]` indicating which digit(s) are selected for blinking:
  - Minutes selected: mask digits 3 and 2.
  - Seconds selected: mask digits 1 and 0.

Reset Behavior (FR 3.1)
- Synchronous clear to 00:00. Optionally handle async press by synchronizing then treating as sync pulse.

Pause Toggle (FR 3.2)
- Rising edge on `pause_btn` toggles `run` regardless of mode. While ADJ=1, increments still come from 2 Hz path only.

## 5) Seven‑Segment Display (TR 3)

Module `display_driver` handles:
- Fast refresh counter at `clk_100mhz` with N=18 (per context.md) to meet 50–700 Hz multiplexing.
- 4:1 mux of current BCD digit based on counter MSBs to drive `an[3:0]` (active‑low) and a `hex_in` nibble.
- BCD→7seg decode for 0–9 (implement all digits). Optionally map A–F if desired.
- Blink overlay: if `adj=1` and the currently selected digit is in `blink_mask`, gate segments with `en_blink` off phase (e.g., hide segments when blink=0). Do not blink at 2 Hz (choose 4 Hz), per TR 1.

Outputs
- `seg[6:0]` active‑low segments and `seg[7]` dp (usually kept off).
- `an[3:0]` active‑low anode enables per Basys 3.

## 6) Top‑Level Integration

`stopwatch_top` wiring outline
- Instantiate `clk_gen` → `en_1hz`, `en_2hz`, `en_fast`, `en_blink` (and optional `clk_fast`).
- Sync+debounce raw inputs → `reset_pulse`, `pause_edge`, `sel_level`, `adj_level`.
- Instantiate `time_core` with the enables and controls → digits `hex3..hex0`, `blink_mask`.
- Instantiate `display_driver` with digits, `adj_level`, `blink_mask`, and blink enable.
- Export to physical pins (`seg`, `an`).

## 7) XDC Constraints (IC 1)

Create `StopWatch.xdc` using Basys‑3 Master XDC as source of truth (context.md shows examples):
- Clock: map 100 MHz to `clk_100mhz` at pin W5 with PERIOD 10.00 ns.
- Buttons: map `reset_btn` and `pause_btn` (e.g., U18 and T18 shown in context.md). Verify exact pinout.
- Switches: map `sel_sw`, `adj_sw` to two slider switch pins from the Master XDC.
- 7‑segment: map `seg[7:0]` and `an[3:0]` to correct pins with LVCMOS33 IOSTANDARD.
- Keep LOC and PERIOD constraints; avoid generated clocks—use enable pulses to keep single clock domain.

Validation of constraints
- After synth/impl, review timing summary; ensure no unconstrained paths; PERIOD 10 ns met.

## 8) Module Stubs and Interfaces

clk_gen (enable pulses)
```verilog
module clk_gen(
  input  wire clk_100mhz,
  input  wire rst,
  output wire en_1hz,
  output wire en_2hz,
  output wire en_fast,
  output wire en_blink
);
// Free‑running counters → one‑cycle enables
endmodule
```

input_sync_debounce
```verilog
module input_sync_debounce(
  input  wire clk,
  input  wire en_sample, // en_fast
  input  wire din_async,
  output wire level,
  output wire rise
);
// 2‑FF sync + debounce + edge detect
endmodule
```

time_core
```verilog
module time_core(
  input  wire clk,
  input  wire rst,
  input  wire en_1hz,
  input  wire en_2hz,
  input  wire adj,
  input  wire sel,
  input  wire pause_edge,
  output reg  [3:0] hex3, hex2, hex1, hex0,
  output reg  [3:0] blink_mask
);
endmodule
```

display_driver
```verilog
module display_driver(
  input  wire clk,
  input  wire adj,
  input  wire [3:0] blink_mask,
  input  wire en_blink,
  input  wire [3:0] hex3, hex2, hex1, hex0,
  output reg  [3:0] an,
  output reg  [7:0] seg
);
endmodule
```

stopwatch_top
```verilog
module stopwatch_top(
  input  wire clk_100mhz,
  input  wire reset_btn,
  input  wire pause_btn,
  input  wire sel_sw,
  input  wire adj_sw,
  output wire [7:0] seg,
  output wire [3:0] an
);
endmodule
```

## 9) Step‑by‑Step Execution Plan

1. Vivado project setup
   - Create new RTL project targeting Basys 3 (xc7a35tcpg236‑1).
   - Add HDL files: `stopwatch_top.v`, `clk_gen.v`, `input_sync_debounce.v`, `time_core.v`, `display_driver.v`.
   - Add `StopWatch.xdc` copied/adapted from Basys‑3 Master XDC; wire pins per board manual.

2. Implement `clk_gen`
   - Use counters for 1/2/fast/blink enables. Simulate divider behavior quickly by reducing divisors in sim if needed.

3. Implement `input_sync_debounce`
   - 2‑FF synchronizer, debouncer sampled on `en_fast`, rising‑edge detection for pause and reset.

4. Implement `time_core`
   - BCD counters and cascades for MM:SS. Integrate `run` toggling on `pause_edge` and mode control (adj/sel) per PRD.
   - Expose `blink_mask` per selected field during ADJ.

5. Implement `display_driver`
   - Refresh counter (N=18). 4‑way mux to select digit and active‑low anodes. BCD→7seg decode for 0–9. Blink gating using `en_blink` and `blink_mask` only when `adj=1`.

6. Top‑level wiring `stopwatch_top`
   - Instantiate modules and connect signals. Route to top‑level ports mapped in XDC.

7. Simulation (unit tests)
   - `clk_gen` division correctness (using scaled divisors in sim).
   - `input_sync_debounce` rejects short pulses and creates clean edge.
   - `time_core` increments at 1 Hz, cascades 59→00 seconds and 99:59→00:00, pauses/resumes, and adjusts minutes/seconds at 2 Hz.
   - Blink logic toggles only selected digits and frequency ≠ 2 Hz.

8. Synthesis & Implementation
   - Run Synthesis/Implementation. Check timing; PERIOD 10 ns met.
   - Fix any XDC mapping or timing issues.

9. Hardware bring‑up
   - Program Basys 3. Verify: reset to 00:00, pause toggle, normal counting, ADJ with SEL, blink of selected field, proper multiplexing brightness with no ghosting.

10. Polish & deliverables
   - Clean hierarchy and signal names. Comment modules minimally for clarity.
   - Zip Vivado project folder. Prepare demo and lab report per PRD.

## 10) PRD Compliance Checklist

Functional Requirements
- FR 1.1 Time Format MM:SS — implemented in `time_core` with four BCD digits.
- FR 1.2 Display Mapping — `display_driver` maps hex3..hex0 to left→right digits.
- FR 1.3 Counter Behavior — 1 Hz increments, 59 sec cascades to minutes, cascade implemented.
- FR 2.1/2.2 SEL/ADJ — `time_core` adjusts selected portion at 2 Hz; non‑selected frozen; normal increments halted; `display_driver` blinks selected portion.
- FR 3.1 RESET — `reset_btn` clears to 00:00.
- FR 3.2 PAUSE — `pause_btn` rising‑edge toggles run/pause.

Technical Requirements
- TR 1 Clocking — `clk_gen` provides 1 Hz, 2 Hz, fast mux, and >1 Hz blink (≠ 2 Hz).
- TR 2 Debounce/Sync — `input_sync_debounce` under‑samples at fast clock; 2‑FF sync after async inputs.
- TR 3 Display — multiplexing at 50–700 Hz; BCD decode; Basys 3 manual consulted.

Implementation & Constraints
- IC 1 XDC — LOC and PERIOD constraints from Basys‑3 Master XDC with proper mappings.

Deliverables
- D 1 Demo — on‑board behavior verified per checklist.
- D 2 Zip Vivado project — folder zipped and uploaded.
- D 3 Lab report — architecture, design choices, waveforms, and test evidence documented.

## 11) Risks, Notes, and Tips

- Ensure blink frequency is not 2 Hz; prefer 4–8 Hz so it is visually distinct from 2 Hz adjust ticks.
- Keep single clock domain; use enable pulses to simplify timing and CDC.
- Debounce windows too short cause bounce; too long frustrates UX. ~8–15 ms is a good target.
- Confirm anodes/segments are active‑low on Basys 3. Invert appropriately in HDL.
- For simulation, scale divisors (e.g., treat 1000 cycles as 1 “second”) with `ifdef SIM` guards.
- If minutes should cap at 59 instead of 99 (not specified in PRD), confirm with TA; plan currently implements 00–99 minutes.


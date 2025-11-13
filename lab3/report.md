# Lab 3 Stopwatch Report

## 1. Introduction and Requirements
This lab targets the Basys 3 (Artix-7) FPGA and implements a stopwatch that counts minutes and seconds on the on-board seven-segment display. The Product Requirements Document (PRD) specifies:
- **FR1**: Display MM:SS using cascading decade counters; seconds roll over at 59 and drive minutes.
- **FR2**: Slider switches implement adjust mode. `SEL` chooses minutes vs. seconds, `ADJ` enters adjust mode where the chosen field increments at 2 Hz, blinks, and the other field freezes.
- **FR3**: Push buttons provide `RESET` (synchronous clear to 00:00) and `PAUSE` (toggle run/pause).
- **TR1–TR3**: Generate 1 Hz, 2 Hz, 50–700 Hz, and >1 Hz blink enables from the 100 MHz master clock; debounce all async inputs; multiplex the four seven-seg digits; supply XDC timing and I/O constraints.

The implementation follows the planned architecture in `IMPLEMENTATION_PLAN_LAB3.md` and the broader background captured in `context.md`.

## 2. Design Description
### 2.1 System Overview
The 100 MHz board clock fans into `clk_gen`, which emits one-cycle enables at 1 Hz, 2 Hz, ~381 Hz, and ~4 Hz. The fast enable drives four `input_sync_debounce` blocks that clean the reset button, pause button, and the two adjustment switches, producing a synchronous reset level, a pause edge pulse, and stable mode-select levels. Those cleaned controls plus the 1 Hz/2 Hz enables feed `time_core`, which holds the MM:SS digits, handles adjust mode, and generates a blink mask for whichever digits are being edited. The digit values and blink mask go to `display_driver`, which uses the fast enable for multiplexing and the blink enable to hide selected digits while adjusting before driving `an[3:0]` and `seg[7:0]`.

### 2.2 Modules and Interfaces
- **`clk_gen`** (`lab3/rtl/clk_gen.v`): Free-running dividers produce one-cycle enable pulses:
  - `en_1hz` (100 M / 100 M cycles) for normal seconds.
  - `en_2hz` (100 M / 50 M cycles) for adjust mode.
  - `en_fast` (2¹⁸ wrap ≈381 Hz) for debouncing and digit scanning.
  - `en_blink` (~4 Hz) for adjust-mode blinking.
  Counters initialize via `initial` statements so the enables start pulsing immediately after configuration.

- **`input_sync_debounce`** (`lab3/rtl/input_sync_debounce.v`):
  - Two flip-flop synchronizer to tame metastability.
  - 4-sample shift register sampled on `en_fast`; all-ones/all-zeros consensus updates the debounced `level`.
  - Rising edge detector emits `rise` pulses where needed (`pause`).

- **`time_core`** (`lab3/rtl/time_core.v`):
  - Holds BCD digits `hex3:hex0` and a `run` flag.
  - Normal mode (`adj = 0`): increment seconds when `run` is true and `en_1hz` fires; cascade to minutes up through 99:59.
  - Adjust mode (`adj = 1`): halt normal counting; use `sel` + `en_2hz` to bump either minutes (`hex3:hex2`) or seconds (`hex1:hex0`), leaving the other field frozen. Generates `blink_mask` bits so the UI can blink the selected digits.
  - `pause_edge` toggles `run`; synchronous reset plus an `initial` block ensure digits clear to 00:00 and the stopwatch starts running automatically after configuration.

- **`display_driver`** (`lab3/rtl/display_driver.v`):
  - Uses the fast clock to multiplex four digits; MSBs of a refresh counter select the active anode.
  - BCD-to-7seg decode drives active-low segments (`seg[7:0]`), keeping the decimal point off.
  - Blanking logic uses `blink_mask`, `adj`, and `en_blink` to hide the selected digits during adjust mode without affecting others.

- **`stopwatch_top`** (`lab3/rtl/stopwatch_top.v`):
  - Instantiates the modules, routes clean control signals, and feeds digit/blink data to the display logic.

- **Constraints** (`lab3/constrs/StopWatch.xdc`):
  - Map clock, buttons, switches, anodes, and segments to Basys 3 pins.
  - Declare the 100 MHz clock period (10 ns) for timing closure.

### 2.3 Behavioral Notes
- Reset chain: `reset_btn` → debounce → `rst_level` drives `time_core` and other modules while `clk_gen` keeps running, preventing the system from getting stuck after reset.
- Pause handling: each rising edge of the debounced pause button toggles `run`, allowing a single button to alternate start/stop.
- Adjust interlock: while `adj=1`, seconds/minutes normal increments are inhibited, ensuring deterministic adjustments.

## 3. Testing Documentation
Because the focus was on hardware bring-up rather than simulation, verification relied on manual tests on the Basys 3 board:
1. **Power-on behavior** – Confirmed digits initialize to `00 00` and immediately begin counting.
2. **Reset** – Press RESET; digits clear to zero and resume counting without additional input.
3. **Pause toggle** – Tap PAUSE to halt; tap again to resume. Checked that multiple taps do not miss or double-trigger.
4. **Adjust mode** – Slide `ADJ` high, use `SEL` to pick minutes vs. seconds, and observe 2 Hz bumping plus blinking on the selected digits; ensured the non-selected field remains frozen.
5. **Rollover** – Let seconds roll from 59 → 00 and minutes advance; confirmed 99:59 wraps to 00:00.

These tests collectively exercise the primary functional requirements even without a simulation testbench.

## 4. Conclusion
The stopwatch meets the PRD requirements by combining cleanly separated modules for clock division, input conditioning, timekeeping, and display control. Key challenges included:
- **Reset/run interaction**: Initially, holding `clk_gen` in reset starved the debouncer of the fast sampling pulse, freezing the system after a reset. Free-running the clock divider resolved the circular dependency.
- **Power-on auto-run**: Ensuring the stopwatch starts counting immediately required initializing the `run` flag (and digits) via both synchronous reset and an `initial` block for post-configuration behavior.

Future improvements could add simulation coverage for edge cases (e.g., pause during adjust mode) and automated hardware tests, but the current design satisfies the lab objectives and behaves correctly under manual validation on the Basys 3.

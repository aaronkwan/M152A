# Stopwatch Reset Recovery Plan

## Goal
Ensure the stopwatch resumes counting after a reset by keeping the clock-enable generator (`clk_gen`) free-running so that the debouncer continues sampling even while the rest of the system is held in reset.

## Implementation Steps
1. **Audit current reset wiring**
   - Review `lab3/rtl/stopwatch_top.v` to confirm `rst_level` (debounced reset) fans out to both `clk_gen` and `time_core`.
   - Verify that `clk_gen` is the sole producer of `en_fast`, which the reset debouncer depends on.
2. **Update `clk_gen` interface**
   - Remove the `rst` input and related reset logic from `lab3/rtl/clk_gen.v`, allowing its counters to run continuously after power-on.
   - Initialize counters/enables to known values using Verilog initial blocks so simulation and hardware start in a valid state.
3. **Adjust top-level instantiation**
   - Modify `lab3/rtl/stopwatch_top.v` to instantiate `clk_gen` without a reset port (or tie it permanently low if the port is kept for future use).
   - Leave `rst_level` connected to `time_core` so the digits still clear when the button is pressed.
4. **Regression sanity checks**
   - Re-run any available simulations or on-board tests to verify that:  
     a. Reset zeroes the digits,  
     b. The stopwatch resumes counting automatically after reset,  
     c. Adjust/pause features still behave as before.
   - Document test results in the lab notebook or `context.md` if required.

Following this plan removes the circular dependency between the reset debouncer and the clock-enable pulses, allowing the system to exit reset cleanly.

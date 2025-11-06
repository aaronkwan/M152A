# Lab 3 Stopwatch – Full Context, Specifications, XDC, and Sample Implementation (Verilog-2001)

## I. Project Overview: Lab 3 Stopwatch

The goal of Lab 3 is to design a **stopwatch circuit** and implement it on the **Basys 3 board** (Artix-7 FPGA). The design involves implementing counters, clock generation, display multiplexing, and input debouncing.

### Functionality Summary

The stopwatch counts minutes and seconds, displayed on the four on-board seven-segment displays (left two digits for minutes, right two for seconds).

| Input Type | Signal | Functionality |
| :--- | :--- | :--- |
| Switch (SEL) | 0 | Selects Minutes for adjustment mode |
| Switch (SEL) | 1 | Selects Seconds for adjustment mode |
| Switch (ADJ) | 0 | Stopwatch behaves normally |
| Switch (ADJ) | 1 | Adjustment mode: Clock halts, selected portion increments at **2 Hz** and blinks |
| Push Button | RESET | Forces all counters to the initial state **00:00** |
| Push Button | PAUSE | Toggles the counter between running and paused states |

### Implementation Components

1. **Counter:**  
   Uses cascading decade (mod-10) counters. Seconds increment every second; when reaching 59, minutes increment.

2. **Clock Module:**  
   Takes the **100 MHz master clock** (pin V10 internally) and outputs four clocks:
   - **2 Hz** – for incrementing minutes/seconds in adjust mode
   - **1 Hz** – for normal second increments
   - **50–700 Hz** – for 7-segment display multiplexing and debouncer under-sampling
   - **Blink clock (>1 Hz)** – to blink the selected digit during adjustment mode (must not be 2 Hz)

3. **Seven-Segment Display:**  
   Requires multiplexing and BCD decoding. Must read the Basys-3 Reference Manual.

4. **Debouncers:**  
   Required due to mechanical button noise (“bouncing”).
   - **Noise filtering:** Use under-sampling of inputs (50–700 Hz)
   - **Metastability protection:** Use 2 flip-flops to synchronize asynchronous inputs

5. **Xilinx Design Constraints (XDC):**  
   Must specify LOC (pin placement) and PERIOD (timing) constraints.


### A. Sample Project Structure

A sample implementation provides a structured approach to the stopwatch design, separating concerns into individual modules (files).

| File Name | Function | Source |
| :--- | :--- | :--- |
| `stopWatch.v` | Top-level module: instantiates all sub-modules (Timer, Debouncer, Display Driver). | `sources_1/new/` |
| `timer.v` | Contains clock division logic (1 Hz generation) and the counting/cascading logic (Minutes/Seconds). | `sources_1/new/` |
| `debounce.v` | Handles asynchronous button inputs to produce clean, synchronous output signals. | `sources_1/new/` |
| `displayDriver.v` | Implements 7-segment decoding and multiplexing across four digits. | `sources_1/new/` |
| `StopWatch.xdc` | Defines physical pin constraints (LOC) and timing requirements (PERIOD) for the Basys 3 board. | `constrs_1/new/` |
| `timer_test.v` | Simulation testbench for testing the core `timer` module. | `sim_1/new/` |

## II. Verilog-2001 Standard (IEEE Std 1364-2001)

**(Pre-existing content defining Verilog-2001 features, lexical conventions, and assignment rules.)**

### F. Sample Implementation Standards

The provided solution demonstrates several standard practices:

*   **Timescale Directive:** Specifies the time unit and precision for simulation, e.g., ``timescale 1ns / 1ps`.
*   **Sequential Logic:** Uses **non-blocking assignments (`<=`)** within `always @(posedge clk)` blocks, which is the standard practice for modeling synchronous registers and counters.
*   **Combinational Logic:** Uses the Verilog-2001 **`always @*`** wildcard sensitivity list for combinational logic blocks, such as display decoding and next-state logic.

## III. Hardware Design Fundamentals & Standards

### E. Xilinx Design Constraints (XDC)

The constraints file (`StopWatch.xdc`) provides necessary physical mapping (LOC) and timing (PERIOD) constraints for the Basys 3 Artix-7 FPGA.

**Key Clock and I/O Constraints (Basys 3)**

The master clock input is located on pin **W5**.

```verilog
# Clock signal
set_property PACKAGE_PIN W5 [get_ports clk]
set_property IOSTANDARD LVCMOS33 [get_ports clk]
create_clock -add -name sys_clk_pin -period 10.00 -waveform {0 5} [get_ports clk]

# Buttons (Reset and Pause)
set_property PACKAGE_PIN U18 [get_ports reset]
set_property IOSTANDARD LVCMOS33 [get_ports reset]
set_property PACKAGE_PIN T18 [get_ports pause]
set_property IOSTANDARD LVCMOS33 [get_ports pause]
```

**Seven-Segment Display Constraints**

The 8-bit segment drive signal (`seven_seg[7:0]`) and the 4-bit anode selection signal (`anode_select[3:0]`) are mapped to the following pins:

| Signal | Pin Location | Standard | Source |
| :--- | :--- | :--- | :--- |
| `seven_seg` | W7 | LVCMOS33 | |
| `seven_seg` | W6 | LVCMOS33 | |
| `seven_seg` | U8 | LVCMOS33 | |
| `seven_seg` | V8 | LVCMOS33 | |
| `seven_seg` | U5 | LVCMOS33 | |
| `seven_seg` | V5 | LVCMOS33 | |
| `seven_seg` | U7 | LVCMOS33 | |
| `seven_seg` (Decimal Point) | V7 | LVCMOS33 | |
| `anode_select` | U2 | LVCMOS33 | |
| `anode_select` | U4 | LVCMOS33 | |
| `anode_select` | V4 | LVCMOS33 | |
| `anode_select` | W4 | LVCMOS33 | |

---

## IV. Sample Solution and Code Implementation

### A. Top-Level Module (`stopWatch.v`)

The top-level module is responsible for connecting the asynchronous inputs (buttons) to the debouncers, passing the synchronized signals to the timer, and routing the timer output to the display driver.

```verilog
module stopWatch(
    input clk,
    input reset,
    input pause,
    output [3:0] anode_select,
    output [7:0] seven_seg
);

wire [3:0] hex3,hex2,hex1,hex0; // Timer output digits
wire d_pause,d_reset;          // Debounced inputs

// 1. Instantiate the Timer Core (t)
timer t (
    .clk(clk),
    .reset(d_reset),
    .pause(d_pause),
    .hex3(hex3), // Minutes (Most Significant Digits)
    .hex2(hex2),
    .hex1(hex1), // Seconds (Least Significant Digits)
    .hex0(hex0)
);

// 2. Instantiate the Display Driver (dD)
displayDriver dD(
    .clk(clk),
    .hex3(hex3), .hex2(hex2), .hex1(hex1), .hex0(hex0),
    .anode_select(anode_select),
    .seven_seg(seven_seg)
);

// 3. Instantiate Debouncer for PAUSE button
debounce pausebtn(
    .clk(clk),
    .n_reset(1),
    .button_in(pause),
    .DB_out(d_pause)
);

// 4. Instantiate Debouncer for RESET button
debounce resetbtn(
    .clk(clk),
    .n_reset(1), // Active high system reset is permanently high (1'b1)
    .button_in(reset),
    .DB_out(d_reset)
);

endmodule
```

### B. Input Debouncer Module (`debounce.v`)

The `debounce` module converts noisy asynchronous button inputs into clean, single-edge synchronous outputs (`DB_out`) using a shift register approach and a counter.

**Key Concepts:**
1.  **Metastability Synchronization:** Uses two cascaded flip-flops (`DFF1`, `DFF2`) to synchronize the asynchronous input (`button_in`) to the system clock (`clk`).
2.  **Noise Filtering (Timing):** A parameter `N = 11` is used for the timing register width (`q_reg`). The calculation suggests this corresponds to a **32 ms debounce time** at an unspecified system frequency (likely based on the clock frequency).
3.  **Level Change Detection:** The control signal `q_reset` is assigned using an XOR gate on the two flip-flop outputs (`DFF1 ^ DFF2`). This detects a *level change* which should immediately reset the counter, thus ignoring the initial rapid bounces.
4.  **Output Generation:** The output `DB_out` is updated only when the counter reaches its maximum value (when `q_reg[N-1]` is '1'), confirming the input has been stable for the debounce period.

```verilog
module debounce(
    input clk,
    input n_reset,
    input button_in,
    output reg DB_out
);

parameter N = 11 ; // (2^ (21-1) )/ 38 MHz = 32 ms debounce time

reg [N-1 : 0] q_reg; // timing regs
reg [N-1 : 0] q_next;
reg DFF1, DFF2; // input flip-flops

wire q_add;     // control flags
wire q_reset;

// Combinational logic to detect level change (to reset counter)
assign q_reset = (DFF1 ^ DFF2);

// Combinational logic to enable count (when counter hasn't overflowed)
assign q_add = ~(q_reg[N-1]);

// Next State Logic for Counter (Combinational Block, Verilog-2001 style)
always @ ( q_reset, q_add, q_reg)
begin
    case( {q_reset , q_add})
        // Case 00: Input is stable (q_reset=0) AND counter overflowed (q_add=0). Keep the max count.
        2'b00 : q_next <= q_reg;
        // Case 01: Input is stable (q_reset=0) AND counter not overflowed (q_add=1). Increment counter.
        2'b01 : q_next <= q_reg + 1;
        // Default: If input changes (q_reset=1), reset counter to zero.
        default : q_next <= { N {1'b0} };
    endcase
end

// Synchronous Logic Block 1: Shift Register and Counter Update
always @ ( posedge clk )
begin
    if(n_reset == 1'b0) // Asynchronous reset
    begin
        DFF1 <= 1'b0;
        DFF2 <= 1'b0;
        q_reg <= { N {1'b0} };
    end
    else
    begin
        DFF1 <= button_in; // First stage synchronization
        DFF2 <= DFF1;      // Second stage synchronization
        q_reg <= q_next;   // Update counter
    end
end

// Synchronous Logic Block 2: Output Generation
always @ ( posedge clk )
begin
    // Output changes only when counter overflows (q_reg[N-1] is high)
    if(q_reg[N-1] == 1'b1)
        DB_out <= DFF2;
    else
        DB_out <= DB_out; // Hold previous state
end

endmodule
```

### C. Timer Module (`timer.v`)

The `timer` module performs two critical functions: clock division and cascaded decade counting. Note that this specific implementation only handles simple counting/reset/pause, and *does not* include the **SEL/ADJ/blinking** logic required by Lab 3.

**Key Concepts:**
1.  **1 Hz Clock Generation:** The clock signal is derived from the constant `oneHz_constant` which is set to **`28'd100000000`**. This value is the number of clock cycles needed to count 1 second, confirming the system uses a **100 MHz master clock** ($100 \text{ MHz} \times 1 \text{ second} = 100,000,000$ cycles).
2.  **Pause/Run Logic:** The `pause` input controls a flag `count`. When `pause` is asserted, `count` toggles its state (run/stop).
3.  **Cascaded Counters:** The module implements four cascading counters (`hex0`, `hex1`, `hex2`, `hex3`).
    *   `hex0` (seconds unit digit) counts 0 to 9.
    *   `hex1` (seconds ten digit) counts 0 to 5, enabled when `hex0` rolls over from 9.
    *   `hex2` (minutes unit digit) counts 0 to 9, enabled when `hex1` rolls over from 5.
    *   `hex3` (minutes ten digit) counts 0 to 9, enabled when `hex2` rolls over from 9.

```verilog
module timer(
    input clk,
    input reset,
    input pause,
    output reg [3:0] hex3, // M10
    output reg [3:0] hex2, // M1
    output reg [3:0] hex1, // S10
    output reg [3:0] hex0  // S1
);

// 100 MHz input clock generates 1 Hz
localparam [28:0] oneHz_constant = 28'd100000000;

reg oneHz_enable;
reg [28:0] oneHz_counter = oneHz_constant;
reg count; // Toggle variable for pause functionality

// Sequential Block 1: 1 Hz Clock Division and Pause Logic
always@(posedge clk) begin
    if (reset) begin // Synchronous reset logic
        oneHz_counter=oneHz_constant;
        count = 1; // Start counting upon reset release
    end
    else begin
        if (pause) begin // Toggle pause state
            if (count) count = 0;
            else count = 1;
        end
        
        if (count) begin // Counting mode enabled
            oneHz_counter = oneHz_counter - 1;
            oneHz_enable = (oneHz_counter == 0);
            if (!oneHz_counter) oneHz_counter = oneHz_constant;
        end
    end
end

// Sequential Block 2: Counter Chain (Triggered by 1 Hz Enable pulse)
always@(posedge oneHz_enable, posedge reset) begin
    if (reset) begin
        // Reset all hex outputs to 00:00
        hex3 = 4'd0; hex2 = 4'd0;
        hex1 = 4'd0; hex0 = 4'd0;
    end
    else begin
        // Standard Cascading Counter Logic (S1, S10, M1, M10)
        if (hex0<4'd9) hex0 = hex0 + 1; // S1 increments (0-9)
        else begin
            if (hex1<4'd5) begin        // Check S10 limit (0-5)
                hex1 = hex1 + 1;
                hex0 = 0;
            end
            else begin
                if (hex2<4'd9) begin    // Check M1 limit (0-9)
                    hex2 = hex2 + 1;
                    hex1 = 0;
                end
                else begin
                    if (hex3<4'd9) begin // Check M10 limit (0-9)
                        hex3 = hex3 + 1;
                        hex2 = 0;
                    end
                    else hex3 = 0;      // Roll over from 99:59 to 00:00
                end
            end
        end
    end
end
endmodule
```

### D. Seven-Segment Display Driver Module (`displayDriver.v`)

The `displayDriver` module implements both the high-frequency multiplexing logic and the BCD-to-7-segment decoder.

**Key Concepts:**
1.  **Multiplexing Clock:** A local parameter `N = 18` is defined for the refresh rate counter (`refresh_rate`). This counter cycles quickly to select which of the four digits (`hex0` through `hex3`) is currently active. Assuming a 100 MHz clock, this division results in a refresh rate of approximately 381 Hz ($100,000,000 / 2^{18}$), which falls within the required 50–700 Hz range for multiplexing.
2.  **Digit Selection:** The two MSBs of the counter (`refresh_rate[N-1:N-2]`) are used in an `always @* case` statement to drive the **active-low** anode signals (`anode_select`). For example, `2'b00` selects the rightmost digit (`anode_select = 4'b1110`), displays `hex0`, and sets the decimal point state (`sseg_dot = dot`).
3.  **BCD-to-7-Segment Decoding:** A second `always @* case` block decodes the currently selected BCD value (`hex_in`) into the 7-segment output patterns (`seven_seg[6:0]`).

```verilog
module displayDriver(
    input clk,
    input [3:0] hex3, input [3:0] hex2,
    input [3:0] hex1, input [3:0] hex0,
    output reg [3:0] anode_select,
    output reg [7:0] seven_seg
);

// Refresh rate: (100 Mhz / 2^18) approx 381 Hz
localparam N = 18;
localparam dot = 4'b1011; // Dot pattern for decimal points (unused here, but defined)

reg [N-1:0] refresh_rate;
wire [N-1:0] refresh_next;
reg [3:0] hex_in;
reg sseg_dot;

// Sequential Block 1: Refresh Rate Counter
always @(posedge clk)
    refresh_rate <= refresh_next;

// Combinational Block 1: Counter Next State Logic
assign refresh_next = refresh_rate + 1;

// Combinational Block 2: 4-to-1 Multiplexing (Anode Selection and Digit Input)
always @*
case (refresh_rate[N-1:N-2])
    // Select rightmost digit (hex0)
    2'b00: begin
        anode_select = 4'b1110; // Active low selection
        hex_in = hex0;
        sseg_dot = dot;
    end

    // Select second digit (hex1)
    2'b01: begin
        anode_select = 4'b1101;
        hex_in = hex1;
        sseg_dot = dot;
    end

    // Select third digit (hex2)
    2'b10: begin
        anode_select = 4'b1011;
        hex_in = hex2;
        sseg_dot = dot;
    end

    // Select leftmost digit (hex3)
    2'b11: begin
        anode_select = 4'b0111;
        hex_in = hex3;
        sseg_dot = dot;
    end
    default: begin
        anode_select = 4'b1111; // Turn off all anodes
        sseg_dot = 1'b1;
    end
endcase

// Combinational Block 3: BCD to 7-Segment Decoding
always @*
begin
    case(hex_in)
        4'h0: seven_seg[6:0] = 7'b0000001; // 0
        4'h1: seven_seg[6:0] = 7'b1001111; // 1
        // ... (remaining digits 2 through F)
        4'h8: seven_seg[6:0] = 7'b0000000; // 8
        4'h9: seven_seg[6:0] = 7'b0000100; // 9
        default: seven_seg[6:0] = 7'b0111000; // F
    endcase
    
    // Assign decimal point (segment 7)
    seven_seg = sseg_dot;
end
endmodule
```

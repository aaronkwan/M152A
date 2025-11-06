
## Product Requirements Document (PRD) for Lab 3: Stopwatch

### I. Introduction and Project Goal

**Project Name:** CS M152A Lab 3: Stopwatch
**Target Hardware:** **Basys 3 board** based on the **Artix-7 FPGA**.
**Goal:** Design and implement a fully functional, adjustable stopwatch circuit using the complete FPGA design flow, displaying output on the on-board seven-segment display.

### II. Functional Requirements (FR)

#### FR 1. Basic Counting and Display

*   **FR 1.1 Time Format:** The stopwatch must count minutes and seconds.
*   **FR 1.2 Display Mapping:** The output must be displayed on the four on-board seven-segment displays.
    *   The **left two digits** must display **minutes**.
    *   The **right two digits** must display **seconds**.
    *   *Example:* 1 minute and 43 seconds is displayed as "0143".
*   **FR 1.3 Counter Behavior:**
    *   The basic counting unit is the **decade (modulo 10) counter**.
    *   The seconds counter must increment every second.
    *   Upon reaching 59, the seconds counter must **enable the minutes counter**, which increments on the next rising edge of the clock.

#### FR 2. Input Control (Switches)

The design must utilize two slider switches for time adjustment: SEL and ADJ.

*   **FR 2.1 SEL (Select Switch) Functionality:** SEL chooses the portion of the clock to be adjusted.
    *   SEL = **0**: Selects **Minutes**.
    *   SEL = **1**: Selects **Seconds**.
*   **FR 2.2 ADJ (Adjust Switch) Functionality:** ADJ controls the adjustment mode.
    *   ADJ = **0**: Stopwatch behaves **normally** (running or paused based on PAUSE status).
    *   ADJ = **1** (Adjustment Mode):
        *   **Normal increments are halted**.
        *   The portion of the clock selected by SEL increments at a rate of **2 ticks per second (2 Hz)**.
        *   The unselected portion of the clock is **frozen**.
        *   The selected, incrementing portion must **blink**.

#### FR 3. Input Control (Push Buttons)

The design must utilize two push buttons to control timer behavior.

*   **FR 3.1 RESET Button:** When pressed, RESET must **force all counters to the initial state 00:00**.
*   **FR 3.2 PAUSE Button:** PAUSE must **toggle** the counter: pause the counter when pressed, and continue the counter if pressed again.

### III. Technical Requirements (TR)

#### TR 1. Clock Generation and Management

The design must incorporate a Clock Module that takes the **100 MHz master clock** (internally connected to pin **V10** of the FPGA board) as input and generates four different clock signals.

| Clock Signal | Purpose | Required Frequency / Rate | Source |
| :--- | :--- | :--- | :--- |
| **1 Hz Clock** | Normal second increments. | 1 Hz. | |
| **2 Hz Clock** | Adjustment mode increment rate. | 2 Hz. | |
| **Faster Clock** | Seven-segment display multiplexing and debouncer undersampling. | **50 – 700 Hz**. | |
| **Blinking Clock** | Blinking the selected digit in adjustment mode. | **> 1 Hz** (cannot be 2 Hz). |

#### TR 2. Input Integrity (Debouncing and Synchronization)

The design must handle physical contact instability and the asynchronous nature of button and switch inputs.

*   **TR 2.1 Noise Filtering:** Noise must be filtered out by **sampling at a frequency lower than that of the noise**. The **faster clock (50–700 Hz)** must serve as the **under sampling clock** for the debouncer circuit.
*   **TR 2.2 Metastability Solution:** To address asynchronous input and ensure consistent outputs to modules, a **flip-flop** must be used **after the asynchronous input**.

#### TR 3. Display Implementation

*   **TR 3.1 Documentation Requirement:** Developers are **required to read the Basys 3 Reference Manual** to understand the seven-segment display operation and implementation.
*   **TR 3.2 Multiplexing:** Circuitry must be implemented to **cycle through the four digits** using the **faster clock (50–700 Hz)** to ensure the human eye perceives four distinct digits.

### IV. Implementation and Constraints (IC)

*   **IC 1. Xilinx Design Constraints (XDC):** An XDC file must be created to provide implementation constraints to the FPGA tools.
    *   Constraints must include **LOC (placement)** constraints.
    *   Constraints must include **PERIOD (timing)** constraints.
    *   Reference materials (Basys-3-Master.xdc and Basys3 reference manual) should be used.

### V. Deliverables (D)

1.  **D 1. Design Demo:** The design must be demonstrated to the TA.
2.  **D 2. Project Submission:** The **Xilinx Vivado project folder** must be zipped and uploaded.
3.  **D 3. Lab Report:** A **lab report** must be uploaded.
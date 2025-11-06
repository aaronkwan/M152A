# Basys 3 Stopwatch Constraints (Starter)

# Clock (100 MHz) — Basys 3 W5
set_property PACKAGE_PIN W5 [get_ports {clk_100mhz}]
set_property IOSTANDARD LVCMOS33 [get_ports {clk_100mhz}]
create_clock -add -name sys_clk_pin -period 10.000 -waveform {0 5} [get_ports {clk_100mhz}]

# Buttons (verify exact pins in Basys-3 Master XDC)
set_property PACKAGE_PIN U18 [get_ports {reset_btn}]
set_property IOSTANDARD LVCMOS33 [get_ports {reset_btn}]

set_property PACKAGE_PIN T17 [get_ports {pause_btn}]
set_property IOSTANDARD LVCMOS33 [get_ports {pause_btn}]

# Switches (example pins; verify against Master XDC)
# Update these two mappings to the correct SW pins
set_property PACKAGE_PIN V17 [get_ports {sel_sw}]
set_property IOSTANDARD LVCMOS33 [get_ports {sel_sw}]

set_property PACKAGE_PIN V16 [get_ports {adj_sw}]
set_property IOSTANDARD LVCMOS33 [get_ports {adj_sw}]

# Seven-Segment Display (active-low anodes and segments) — verify all pins
# an[3:0]
set_property PACKAGE_PIN U2  [get_ports {an[3]}]
set_property PACKAGE_PIN U4  [get_ports {an[2]}]
set_property PACKAGE_PIN V4  [get_ports {an[1]}]
set_property PACKAGE_PIN W4  [get_ports {an[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {an[3] an[2] an[1] an[0]}]

# seg[7:0] (dp is seg[7])
set_property PACKAGE_PIN W7 [get_ports {seg[0]}]
set_property PACKAGE_PIN W6 [get_ports {seg[1]}]
set_property PACKAGE_PIN U8 [get_ports {seg[2]}]
set_property PACKAGE_PIN V8 [get_ports {seg[3]}]
set_property PACKAGE_PIN U5 [get_ports {seg[4]}]
set_property PACKAGE_PIN V5 [get_ports {seg[5]}]
set_property PACKAGE_PIN U7 [get_ports {seg[6]}]
set_property PACKAGE_PIN V7 [get_ports {seg[7]}]
set_property IOSTANDARD LVCMOS33 [get_ports {seg[7] seg[6] seg[5] seg[4] seg[3] seg[2] seg[1] seg[0]}]

# NOTE: Pin locations above follow common Basys-3 mappings; verify against the
# official Basys-3 Master XDC for your board revision.

# Recommended global configuration (from Basys-3 master XDC)
set_property CONFIG_VOLTAGE 3.3 [current_design]
set_property CFGBVS VCCO [current_design]

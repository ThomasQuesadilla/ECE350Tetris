// Clock on E3
set_property PACKAGE_PIN E3 [get_ports clk]
set_property IOSTANDARD LVCMOS33 [get_ports clk]

// Rest Signal
set_property PACKAGE_PIN N17 [get_ports reset]
set_property IOSTANDARD LVCMOS33 [get_ports reset]

// VGA Port
set_property PACKAGE_PIN D8 [get_ports {VGA_B[3]}]
set_property PACKAGE_PIN D7 [get_ports {VGA_B[2]}]
set_property PACKAGE_PIN C7 [get_ports {VGA_B[1]}]
set_property PACKAGE_PIN B7 [get_ports {VGA_B[0]}]
set_property PACKAGE_PIN A6 [get_ports {VGA_G[3]}]
set_property PACKAGE_PIN B6 [get_ports {VGA_G[2]}]
set_property PACKAGE_PIN A5 [get_ports {VGA_G[1]}]
set_property PACKAGE_PIN C6 [get_ports {VGA_G[0]}]
set_property PACKAGE_PIN A4 [get_ports {VGA_R[3]}]
set_property PACKAGE_PIN C5 [get_ports {VGA_R[2]}]
set_property PACKAGE_PIN B4 [get_ports {VGA_R[1]}]
set_property PACKAGE_PIN A3 [get_ports {VGA_R[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {VGA_B[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {VGA_B[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {VGA_B[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {VGA_B[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {VGA_G[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {VGA_G[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {VGA_G[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {VGA_G[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {VGA_R[3]}]
set_property IOSTANDARD LVCMOS33 [get_ports {VGA_R[2]}]
set_property IOSTANDARD LVCMOS33 [get_ports {VGA_R[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {VGA_R[0]}]

// Sync Ports
set_property PACKAGE_PIN B11 [get_ports hSync]
set_property PACKAGE_PIN B12 [get_ports vSync]
set_property IOSTANDARD LVCMOS33 [get_ports hSync]
set_property IOSTANDARD LVCMOS33 [get_ports vSync]

// PS2 Stuff
set_property PACKAGE_PIN F4 [get_ports ps2_clk]
set_property PACKAGE_PIN B2 [get_ports ps2_data]
set_property IOSTANDARD LVCMOS33 [get_ports ps2_clk]
set_property IOSTANDARD LVCMOS33 [get_ports ps2_data]

set_property IOSTANDARD LVCMOS33 [get_ports down]
set_property IOSTANDARD LVCMOS33 [get_ports left]
set_property IOSTANDARD LVCMOS33 [get_ports right]
set_property IOSTANDARD LVCMOS33 [get_ports up]
set_property PACKAGE_PIN P18 [get_ports down]
set_property PACKAGE_PIN P17 [get_ports left]
set_property PACKAGE_PIN M17 [get_ports right]
set_property PACKAGE_PIN M18 [get_ports up]

set_property IOSTANDARD LVCMOS33 [get_ports clock]
set_property PACKAGE_PIN E3 [get_ports clock]

set_property IOSTANDARD LVCMOS33 [get_ports {random_block[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {random_block[0]}]

set_property PACKAGE_PIN V10 [get_ports {random_block[1]}]
set_property PACKAGE_PIN V11 [get_ports {random_block[0]}]

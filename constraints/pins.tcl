# clock and reset
set_location_assignment PIN_AF14 -to clk; # CLOCK_50 (50 MHz)
set_location_assignment PIN_AA14 -to reset; # KEY[0], active-low

# DCMI outputs through GPIO pins
# data[0] to data[13]
set data_pins {AC18 Y17 AD17 Y18 AK16 AK18 AK19 AJ19 AJ17 AJ16 AH18 AH17 AG16 AE16}
for {set i 0} {$i < 14} {incr i} {
    set_location_assignment PIN_[lindex $data_pins $i] -to "data\[$i\]"
}

set_location_assignment PIN_AF16 -to VSYNC; # GPIO_0[14]
set_location_assignment PIN_AG17 -to HSYNC; # GPIO_0[15]
set_location_assignment PIN_AA18 -to PIXCLK; # GPIO_0[16]

# 3V3 for all pins
foreach p {clk reset VSYNC HSYNC PIXCLK data[*]} {
    set_instance_assignment -name IO_STANDARD "3.3-V LVTTL" -to $p
}

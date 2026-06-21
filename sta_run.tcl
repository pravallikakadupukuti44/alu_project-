read_liberty sky130.lib
read_verilog netlist_timing.v
link_design alu_8bit
read_sdc constraints.sdc
report_checks -path_delay max -format full_clock_expanded
report_checks -path_delay min -format full_clock_expanded
report_tns
report_wns

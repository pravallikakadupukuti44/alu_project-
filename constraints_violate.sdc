create_clock -name virt_clk -period 4
set_input_delay -clock virt_clk 1 [all_inputs]
set_output_delay -clock virt_clk 1 [all_outputs]

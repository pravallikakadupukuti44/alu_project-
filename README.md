# 8-bit ALU — RTL Design & Functional Simulation
A synthesizable 8-bit Arithmetic Logic Unit (ALU) written in Verilog, verified using a self-checking testbench in Icarus Verilog.
## Features
- 12 operations: ADD, SUB, AND, OR, XOR, NOR, SLL, SRL, SRA, SLT, SLTU, NOT
- Status flags: zero, negative, carry, overflow
- Self-checking testbench with 21 directed edge-case tests + 200 randomized tests
- Verified against an independent reference model
## Results
- 221/221 checks passed
- 12/12 opcodes covered
## Files
- `alu_8bit.v` — ALU RTL source
- `tb_alu_8bit.v` — testbench
- `Task1_RTL_ALU_Submission.docx` — full write-up with code, commands, waveform screenshot, and coverage explanation
## How to run
\`\`\`
iverilog -g2012 -o sim alu_8bit.v tb_alu_8bit.v
vvp sim
\`\`\`
---
# Task 2 — Synthesis & Gate-Level Simulation
RTL was synthesized into a gate-level netlist using Yosys (open-source), then re-simulated and checked for equivalence against the original RTL.
## Tools
- Synthesis: Yosys 0.52
- Simulation: Icarus Verilog 12.0
## Results
- Synthesized to 468 gates — 190 AND, 194 OR, 62 NOT, 22 XOR
- Gate-level simulation: 221/221 checks passed, 12/12 opcodes covered
- RTL vs gate-level diff: identical, 0 differences
## Files
- `synth.ys` — Yosys synthesis script
- `netlist.v` — generated gate-level netlist
- `rtl_output.log` — RTL simulation log
- `gls_output.log` — gate-level simulation log
- `Task2.docx` — full write-up with synthesis script, gate counts, and equivalence proof
## How to run
\`\`\`
yosys synth.ys
iverilog -o gls_sim netlist.v tb_alu_8bit.v /usr/share/yosys/simlib.v
vvp gls_sim > gls_output.log
diff rtl_output.log gls_output.log
\`\`\`

# KAIST EE312 RISC-V simulator with Verilog
This is a RISC-V simulator from KAIST EE312 Computer Architecture course by Prof. John Kim.

The codes are written in Verilog, and evaluated with ModelSim-Intel® on Windows and iVerilog on macOS.


Each directory contains a short report that briefly explains the implementation and the evaluation results.

On the main file (`RISCV_TOP.v`), the `always @ (posedge CLK) begin` and `always @ (*) begin` loops only have few lines of code, since the code for the other parts are all implemented in separate modules :D 

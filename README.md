o7sim
=====

A ModelSim simulation script inspired by the students of HSSE07 at the Upper Austrian University of Applied Sciences Hagenberg and published under the GPLv3.

As many other EDA tools, ModelSim from Mentor Graphics supports scripting. This provides the abbility to automate simulation workflows using TCL scripts. By adjusting the configuration parameters, all simulation steps are done automatically. If you have any patches, feel free to submit them.

Available features:
* Mixed-language support: VHDL, Verilog, SystemVerilog
* Custom compile order
* UVM support
* Automatic waveform generation
* Only modified files are recompiled
* etc.

Usage
-----

To use it, just modify the configuration parameters at the beginning of the file and start the script from the ModelSim command line with the following command: *source o7sim.tcl*

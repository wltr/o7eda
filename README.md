o7sim
=====

A ModelSim simulation script inspired by the people of HSSE07 at the Upper Austrian University of Applied Sciences Hagenberg.

As many other EDA tools, ModelSim from Mentor Graphics supports scripting. This provides the abbility to automate simulation workflows using TCL scripts. By adjusting the configuration parameters, all simulation steps are done automatically. If you have any patches, feel free to submit them.

Available features:
* Mixed-language support: VHDL, Verilog, SystemVerilog, SystemC
* Custom compile order
* SystemC module generation
* UVM support
* Automatic waveform generation
* Only modified files are recompiled
* etc.

Usage
-----

To use it, just modify the configuration parameters at the beginning of the file and start the script from the ModelSim command line with the following command: *source sim.tcl*
# o7sim

This is a [Mentor Graphics ModelSim](http://www.mentor.com/) simulation script inspired by the students of HSSE07 at the [Upper Austrian University of Applied Sciences Hagenberg](http://www.fh-ooe.at/hsd) and published under the MIT License.

The majority of EDA tools supports Tcl scripting. This provides the ability to automate simulation workflows. By adjusting the configuration parameters, all simulation steps are done automatically.

Currently available features:
- Mixed-language support: VHDL, Verilog, SystemVerilog
- Custom compile order
- UVM support
- Automatic waveform generation
- Only modified files are recompiled
- And many more...

If you have any patches, feel free to submit them.

## Usage

In order to use this script modify the configuration parameters at the beginning of the file and start the script from the ModelSim command line with the following command:

    source o7sim.tcl

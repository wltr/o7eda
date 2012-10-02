#!/usr/bin/tclsh

# --------------------------------------------------
# ModelSim simulation script
#
# 2012 by Johannes Walter 
# <contact@johanneswalter.net>
#
# Special thanks to:
#   Marko Prskalo    (Automatic waveform generation)
#   Martin Klepatsch (Compile only modified files)
# --------------------------------------------------

# Source directory
set src_dir "../src"

# Source files in compilation order
# {File SCGenMod SCModName}
set src {
    {"module.cpp" 1 "module"}
    {"top.vhd" 0}
}

# Source file extensions
set vhdl_ext "*.vhd"
set verilog_ext "*.v"
set systemverilog_ext "*.sv"
set systemc_ext "*.cpp"

# Simulation parameters
set lib "work"
set run_time "-all"
set design "top"
set enable_coverage 0

# Custom UVM library parameters
set enable_custom_uvm 0
set custom_uvm_home "/path/to/uvm-1.1"
set custom_uvm_dpi "/path/to/uvm-1.1/lib/uvm_dpi64"

# Command parameters
set vhdl_param ""
set verilog_param ""
set systemverilog_param ""
set systemc_param "-g -DSC_INCLUDE_DYNAMIC_PROCESSES"
set scgenmod_param ""
set vsim_param "-novopt -noglitch +notimingchecks -t ns"

# GUI parameters
set show_gui 1
set show_wave 1

# Waveform parameters
# {Path Recursive}
set wave_patterns {
    {"/*" 0}
    {"/top/dut/*" 1}
}
set wave_ignores {
    "/top/clk"
}
set wave_radix "hex"
set wave_time_unit "ns"
set wave_input_pattern "*_i"
set wave_output_pattern "*_o"
set wave_inout_pattern "*_io"

# Additional VHDL simulation libraries
# {Name Path}
set vhdl_sim_libs {}
#   {"xilinxcorelib" "/opt/xilinxcorelib"} 
#}

# Additional Verilog/SystemVerilog simulation libraries
# {Name Path}
set verilog_sim_libs {}
#   {"xilinxcorelib_ver" "/opt/xilinxcorelib_ver"}
#}

# Additional SystemC include paths
set systemc_inc_paths {}
#   "/path/to/include"
#}

# Additional SystemC library paths
set systemc_lib_paths {}
#   "/path/to/lib"
#}

# Additional SystemC libraries
set systemc_lib_names {}
#   "name"
#}

# TCL script parameters
set compile_time_file ".compile_time.txt"

# --------------------------------------------------
# DO NOT EDIT BELOW THIS LINE
# --------------------------------------------------

puts "\n--------------------------------------------------------"
puts [format "Started simulation script, %s" [clock format [clock seconds] -format {%d. %B %Y %H:%M:%S}]]
puts "--------------------------------------------------------"

# Map work library
puts [format "Mapping library: %s" $lib]
eval vlib $lib
eval vmap  $lib $lib

# Map VHDL libraries
foreach vhdl_sim_lib_entry $vhdl_sim_libs {
    set vhdl_sim_lib_name [lindex $vhdl_sim_lib_entry 0]
    set vhdl_sim_lib_path [lindex $vhdl_sim_lib_entry 1]

    puts [format "Mapping VHDL library: %s" $vhdl_sim_lib_name]
    eval vmap $vhdl_sim_lib_name $vhdl_sim_lib_path
}

# Map Verilog/SystemVerilog libraries
foreach verilog_sim_lib_entry $verilog_sim_libs {
    set verilog_sim_lib_name [lindex $verilog_sim_lib_entry 0]
    set verilog_sim_lib_path [lindex $verilog_sim_lib_entry 1]

    puts [format "Mapping Verilog/SystemVerilog library: %s" $verilog_sim_lib_name]
    eval vmap $verilog_sim_lib_name $verilog_sim_lib_path
}

# Compile UVM library
if {$enable_custom_uvm == 1} {
    puts "Compiling UVM library"
    eval vlog +incdir+$custom_uvm_home/src -work $lib $custom_uvm_home/src/uvm.sv
    append vsim_param [format " -sv_lib %s" $custom_uvm_dpi]
}

# Set coverage parameters
if {$enable_coverage == 1} {
    puts "Coverage enabled"
    append vhdl_param " +cover"
    append verilog_param " +cover"
    append systemverilog_param " +cover"
    append systemc_param " +cover"
    append vsim_param " -coverage"
}

# Additional SystemC include paths
set systemc_inc_param ""
foreach systemc_inc_path $systemc_inc_paths {
    append systemc_inc_param [format "-I%s " $systemc_inc_path]
}

# Additional SystemC library paths
set systemc_lib_path_param ""
foreach systemc_lib_path $systemc_lib_paths {
    append systemc_lib_path_param [format "-L%s " $systemc_lib_path]
}

# Additional SystemC libraries
set systemc_lib_name_param ""
foreach systemc_lib_name $systemc_lib_names {
    append systemc_lib_name_param [format "-l%s " $systemc_lib_name]
}

# Read compile times
if {[info exists last_compile_time]} { unset last_compile_time }
if {[info exists new_compile_time]} { unset new_compile_time }
if {[file isfile $compile_time_file] == 1} {
    set fp [open $compile_time_file r]
    while {[gets $fp line] >= 0 } {
        scan $line "%s %u" file_name compile_time
        set last_compile_time($file_name) $compile_time
    }
    close $fp
}

# Compile sources
set sysc_src_changed 0
foreach src_entry $src {
    set src_file [lindex $src_entry 0]
    set file_name [format "%s/%s" $src_dir $src_file]
    # Check if source has changed
    if {[info exists last_compile_time($file_name)] == 1 && [file mtime $file_name] <= $last_compile_time($file_name)} {
        puts [format "Source has not changed: %s" $src_file]
        set new_compile_time($file_name) $last_compile_time($file_name)
    } else {
        if {[string match $systemc_ext $src_file] == 1} {
            # Compile SystemC source
            puts [format "Compiling SystemC source: %s" $src_file]
            eval sccom $systemc_inc_param $systemc_param -work $lib -scv -scms $file_name
            set sysc_src_changed 1
        } elseif {[string match $vhdl_ext $src_file] == 1} {
            # Compile VHDL source
            puts [format "Compiling VHDL source: %s" $src_file]
            eval vcom $vhdl_param -work $lib $file_name
            # Generate SystemC module
            if {[lindex $src_entry 1] == 1} {
                set scgenmod_name [lindex $src_entry 2]
                set cpp_name [format "%s.cpp" $scgenmod_name]
                puts [format "Generating SystemC module: %s" $cpp_name]
                eval scgenmod -lib $lib $scgenmod_param $scgenmod_name > $src_dir/$cpp_name
            }
        } elseif {[string match $verilog_ext $src_file] == 1} {
            # Compile Verilog source
            puts [format "Compiling Verilog source: %s" $src_file]
            eval vlog $verilog_param +incdir+$src_dir -work $lib $file_name
            # Generate SystemC module
            if {[lindex $src_entry 1] == 1} {
                set scgenmod_name [lindex $src_entry 2]
                set cpp_name [format "%s.cpp" $scgenmod_name]
                puts [format "Generating SystemC module: %s" $cpp_name]
                eval scgenmod -lib $lib $scgenmod_param $scgenmod_name > $src_dir/$cpp_name
            }
        } elseif {[string match $systemverilog_ext $src_file] == 1} {
            # Compile SystemVerilog source
            puts [format "Compiling SystemVerilog source: %s" $src_file]
            if {$enable_custom_uvm == 0} {
                eval vlog $systemverilog_param +incdir+$src_dir -work $lib $file_name
            } else {
                eval vlog $systemverilog_param +incdir+$custom_uvm_home/src+$src_dir -work $lib $file_name
            }
            # Generate SystemC module
            if {[lindex $src_entry 1] == 1} {
                set scgenmod_name [lindex $src_entry 2]
                set cpp_name [format "%s.cpp" $scgenmod_name]
                puts [format "Generating SystemC module: %s" $cpp_name]
                eval scgenmod -lib $lib $scgenmod_param $scgenmod_name > $src_dir/$cpp_name
            }
        }
        set new_compile_time($file_name) [clock seconds]
    }
}

# Write compile times
set fp [open $compile_time_file w]
foreach entry [array names new_compile_time] {
    puts $fp [format "%s %u" $entry $new_compile_time($entry)]
}
close $fp

# Link SystemC source
if {$sysc_src_changed == 1} {
    puts "Linking SystemC source"
    eval sccom -link -work $lib -scv -scms $systemc_lib_path_param $systemc_lib_name_param
}

# Simulate
puts "Starting simulation"

if {$show_gui == 0} {
    append vsim_param " -c"
}

set vsim_lib_param ""
foreach vhdl_sim_lib $vhdl_sim_libs {
    append vsim_lib_param [format " -L %s" [lindex $vhdl_sim_lib 0]]
}
foreach verilog_sim_lib $verilog_sim_libs {
    append vsim_lib_param [format " -L %s" [lindex $verilog_sim_lib 0]]
}

set runtime [time [format "vsim %s %s %s" $vsim_lib_param $vsim_param $design]]
regexp {\d+} $runtime ct_microsecs
set ct_secs [expr {$ct_microsecs / 1000000.0}]
puts [format "Runtime: %6.4f sec" $ct_secs]

# Generate wave form
if {$show_wave == 1} {
    foreach wave_pattern $wave_patterns {
        set find_param ""
        if {[lindex $wave_pattern 1] == 1} {
            set find_param "-r"
        }
        set sig_list [eval find signals $find_param [lindex $wave_pattern 0]]
        set sig_list [lsort -dictionary $sig_list]
        foreach sig $sig_list {
            set ignore 0
            foreach ignore_pattern $wave_ignores {
                if {[string match $ignore_pattern $sig] == 1} {
                    set ignore 1
                }
            }
            if {$ignore == 0} {
                set path [split $sig "/"]
                set wave_param ""
                for {set x 1} {$x < [expr [llength $path] - 1]} {incr x} {
                    append wave_param [format "-group %s " [lindex $path $x]]
                }
                set label [lindex $path [expr [llength $path] - 1]]
                if {[string match $wave_input_pattern $label] == 1} {
                    append wave_param "-group Ports -group In"
                } elseif {[string match $wave_output_pattern $label] == 1} {
                    append wave_param "-group Ports -group Out"
                } elseif {[string match $wave_inout_pattern $label] == 1} {
                    append wave_param "-group Ports -group InOut"
                } else {
                    append wave_param "-group Internals"
                }
                append wave_param [format " -label %s" $label]
                eval add wave -radix $wave_radix $wave_param $sig
            }
        }
    }
    eval configure wave -timelineunits $wave_time_unit
}

# Run
eval run $run_time

# Zoom
if {$show_wave == 1} {
    eval wave zoomfull -windows wave
}


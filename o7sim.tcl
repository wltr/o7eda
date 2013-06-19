#!/usr/bin/tclsh

# --------------------------------------------------
# o7sim - ModelSim Simulation Script
# Version:
  set version 0.2
#
# Copyright (C) 2013  Johannes Walter
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
# For further information see <http://github.com/wltr/o7sim>.
# --------------------------------------------------

# Source directory
set src_dir "../src"

# Source files in compilation order
set src {
    "component.vhd"
    "testbench.sv"
}

# Source file extensions
set vhdl_ext "*.vhd"
set verilog_ext "*.v"
set systemverilog_ext "*.sv"

# Simulation parameters
set work_lib "work"
set run_time "-all"
set time_unit "ns"
set design "testbench"

# Coverage parameters
set enable_coverage 0
set save_coverage 0
set coverage_db_filename "o7sim_coverage.ucdb"

# Assertion thread viewing parameters
set enable_atv 0
set atv_log_patterns {
    "/*"
}

# Custom UVM library parameters
set enable_custom_uvm 0
set custom_uvm_home "/path/to/uvm-1.1"
set custom_uvm_dpi "/path/to/uvm-1.1/lib/uvm_dpi64"

# Command parameters
set vhdl_param ""
set verilog_param ""
set systemverilog_param ""
set vsim_param "-onfinish final -novopt"

# Program parameters
set show_gui 1
set show_wave 1
set quit_at_end 0

# Waveform parameters
# {Path Recursive}
set wave_patterns {
    {"/*" 0}
    {"/testbench/duv/*" 1}
}
set wave_ignores {
    "/testbench/clk"
    "/testbench/rst_n"
}
set wave_radix "hex"
set wave_time_unit "ns"
set wave_expand 1

# Additional simulation libraries
# {Name Path}
set sim_libs {}
#   {"xilinxcorelib" "/opt/xilinxcorelib"}
#}

# Additional Verilog include paths
set verilog_inc_paths {}
#   "/path/to/include"
#}

# Additional SystemVerilog include paths
set systemverilog_inc_paths {}
#   "/path/to/include"
#}

# TCL script parameters
set save_compile_times 1
set compile_time_file ".o7sim_compile_times.txt"

#------------------------------------------------------------------------------
# DO NOT EDIT BELOW THIS LINE
#------------------------------------------------------------------------------

set now [clock format [clock seconds] -format {%d. %B %Y %H:%M:%S}]
puts "\n-------------------------------------------------------------------"
puts [format "Started o7sim v%s Simulation Script, %s" $version $now]
puts "-------------------------------------------------------------------"

# Clean-up
if {$save_compile_times == 0 && [file exists $work_lib] == 1} {
    puts "Clean-up"
    eval vdel -all
}

# Map work library
puts [format "Mapping library: %s" $work_lib]
eval vlib $work_lib
eval vmap  $work_lib $work_lib

# Map additional simulation libraries
foreach sim_lib $sim_libs {
    set sim_lib_name [lindex $sim_lib 0]
    set sim_lib_path [lindex $sim_lib 1]
    puts [format "Mapping simulation library: %s" $sim_lib_name]
    eval vmap $sim_lib_name $sim_lib_path
}

# Compile UVM library
if {$enable_custom_uvm == 1} {
    puts "Compiling UVM library"
    eval vlog +incdir+$custom_uvm_home/src -work $work_lib $custom_uvm_home/src/uvm.sv
    append vsim_param [format " -sv_lib %s" $custom_uvm_dpi]
    lappend systemverilog_inc_paths [format "%s/src" $custom_uvm_home]
}

# Set coverage parameters
if {$enable_coverage == 1} {
    puts "Coverage enabled"
    append vhdl_param " +cover"
    append verilog_param " +cover"
    append systemverilog_param " +cover"
    append vsim_param " -coverage"
}

# Set assertion thread viewing parameters
if {$enable_atv == 1} {
    puts "Assertion thread viewing enabled"
    append vsim_param " -assertdebug"
}

# Additional Verilog include paths
set verilog_inc_param ""
foreach verilog_inc_path $verilog_inc_paths {
    append verilog_inc_param [format " +incdir+%s" $verilog_inc_path]
}

# Additional SystemVerilog include paths
set systemverilog_inc_param ""
foreach systemverilog_inc_path $systemverilog_inc_paths {
    append systemverilog_inc_param [format " +incdir+%s" $systemverilog_inc_path]
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
foreach src_file $src {
    set file_name [format "%s/%s" $src_dir $src_file]
    # Check if source has changed
    if {$save_compile_times == 1 && [info exists last_compile_time($file_name)] == 1 && [file mtime $file_name] <= $last_compile_time($file_name)} {
        puts [format "Source has not changed: %s" $src_file]
        set new_compile_time($file_name) $last_compile_time($file_name)
    } else {
        if {[string match $vhdl_ext $src_file] == 1} {
            # Compile VHDL source
            puts [format "Compiling VHDL source: %s" $src_file]
            eval vcom $vhdl_param -work $work_lib $file_name
        } elseif {[string match $verilog_ext $src_file] == 1} {
            # Compile Verilog source
            puts [format "Compiling Verilog source: %s" $src_file]
            eval vlog $verilog_param $verilog_inc_param +incdir+$src_dir -work $work_lib $file_name
        } elseif {[string match $systemverilog_ext $src_file] == 1} {
            # Compile SystemVerilog source
            puts [format "Compiling SystemVerilog source: %s" $src_file]
            eval vlog $systemverilog_param $systemverilog_inc_param +incdir+$src_dir -work $work_lib $file_name
        }
        set new_compile_time($file_name) [clock seconds]
    }
}

# Write compile times
if {$save_compile_times == 1} {
    set fp [open $compile_time_file w]
    foreach entry [array names new_compile_time] {
        puts $fp [format "%s %u" $entry $new_compile_time($entry)]
    }
    close $fp
}

# Simulate
puts "Starting simulation"

if {$show_gui == 0} {
    eval onbreak resume
}

set vsim_lib_param ""
foreach sim_lib $sim_libs {
    append vsim_lib_param [format " -L %s" [lindex $sim_lib 0]]
}

append vsim_param [format " -t %s" $time_unit]
set runtime [time [format "vsim %s %s %s" $vsim_lib_param $vsim_param $design]]
regexp {\d+} $runtime ct_microsecs
set ct_secs [expr {$ct_microsecs / 1000000.0}]
puts [format "Elaboration time: %6.4f sec" $ct_secs]

# Enable assertion thread view logging
if {$enable_atv == 1} {
    foreach atv_log_pattern $atv_log_patterns {
        eval atv log -enable -recursive $atv_log_pattern
    }
}

# Generate wave form
if {$show_gui == 1 && $show_wave == 1} {
    set wave_expand_param ""
    if {$wave_expand == 1} {
        append wave_expand_param "-expand"
    }
    set sig_list {}
    foreach wave_pattern $wave_patterns {
        set find_param ""
        if {[lindex $wave_pattern 1] == 1} {
            set find_param "-recursive"
        }
        set int_list [eval find signals -internal $find_param [lindex $wave_pattern 0]]
        set in_list [eval find signals -in $find_param [lindex $wave_pattern 0]]
        set out_list [eval find signals -out $find_param [lindex $wave_pattern 0]]
        set inout_list [eval find signals -inout $find_param [lindex $wave_pattern 0]]
        set blk_list [eval find block $find_param [lindex $wave_pattern 0]]
        foreach int_list_item $int_list {
            lappend sig_list [list $int_list_item 0]
        }
        foreach in_list_item $in_list {
            lappend sig_list [list $in_list_item 1]
        }
        foreach out_list_item $out_list {
            lappend sig_list [list $out_list_item 2]
        }
        foreach inout_list_item $inout_list {
            lappend sig_list [list $inout_list_item 3]
        }
        foreach blk_list_item $blk_list {
            lappend sig_list [list [lindex [split $blk_list_item "("] 0] 4]
        }
    }
    set sig_list [lsort -unique -dictionary -index 0 $sig_list]
    foreach sig $sig_list {
        set name [lindex $sig 0]
        set type [lindex $sig 1]
        set ignore 0
        foreach ignore_pattern $wave_ignores {
            if {[string match $ignore_pattern $name] == 1} {
                set ignore 1
            }
        }
        if {$ignore == 0} {
            set path [split $name "/"]
            set wave_param ""
            for {set x 1} {$x < [expr [llength $path] - 1]} {incr x} {
                append wave_param [format "%s -group %s " $wave_expand_param [lindex $path $x]]
            }
            if {$type == 0} {
                append wave_param [format "%s -group Internal" $wave_expand_param]
            } elseif {$type == 1} {
                append wave_param [format "%s -group Ports %s -group In" $wave_expand_param $wave_expand_param]
            } elseif {$type == 2} {
                append wave_param [format "%s -group Ports %s -group Out" $wave_expand_param $wave_expand_param]
            } elseif {$type == 3} {
                append wave_param [format "%s -group Ports %s -group InOut" $wave_expand_param $wave_expand_param]
            } elseif {$type == 4} {
                append wave_param [format "%s -group Assertions" $wave_expand_param]
            }
            set label [lindex $path [expr [llength $path] - 1]]
            append wave_param [format " -label %s" $label]
            eval add wave -radix $wave_radix $wave_param $name
        }
    }
    eval configure wave -timelineunits $wave_time_unit
} elseif {$show_gui == 0 && $show_wave == 1} {
    foreach wave_pattern $wave_patterns {
        set find_param ""
        if {[lindex $wave_pattern 1] == 1} {
            set find_param "-recursive"
        }
        eval log $find_param [lindex $wave_pattern 0]
    }
}

# Run
set runtime [time [format "run %s" $run_time]]
regexp {\d+} $runtime ct_microsecs
set ct_secs [expr {$ct_microsecs / 1000000.0}]
puts [format "Simulation time: %6.4f sec" $ct_secs]

# Save coverage database
if {$enable_coverage == 1 && $save_coverage == 1} {
    eval coverage save $coverage_db_filename
}

# Zoom
if {$show_gui == 1 && $show_wave == 1} {
    eval wave zoomfull -windows wave
}

# Quit
if {$quit_at_end == 1} {
    eval quit -f
}

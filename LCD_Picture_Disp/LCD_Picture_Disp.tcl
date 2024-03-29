# Copyright (C) 1991-2009 Altera Corporation
# Your use of Altera Corporation's design tools, logic functions 
# and other software and tools, and its AMPP partner logic 
# functions, and any output files from any of the foregoing 
# (including device programming or simulation files), and any 
# associated documentation or information are expressly subject 
# to the terms and conditions of the Altera Program License 
# Subscription Agreement, Altera MegaCore Function License 
# Agreement, or other applicable license agreement, including, 
# without limitation, that your use is for the sole purpose of 
# programming logic devices manufactured by Altera and sold by 
# Altera or its authorized distributors.  Please refer to the 
# applicable agreement for further details.

# Quartus II: Generate Tcl File for Project
# File: LCD_Picture_Disp.tcl
# Generated on: Thu May 04 21:13:14 2017

# Load Quartus II Tcl Project package
package require ::quartus::project

set need_to_close_project 0
set make_assignments 1

# Check that the right project is open
if {[is_project_open]} {
	if {[string compare $quartus(project) "LCD_Picture_Disp"]} {
		puts "Project LCD_Picture_Disp is not open"
		set make_assignments 0
	}
} else {
	# Only open if not already open
	if {[project_exists LCD_Picture_Disp]} {
		project_open -revision LCD_Picture_Disp LCD_Picture_Disp
	} else {
		project_new -revision LCD_Picture_Disp LCD_Picture_Disp
	}
	set need_to_close_project 1
}

# Make assignments
if {$make_assignments} {
	set_global_assignment -name FAMILY Cyclone
	set_global_assignment -name DEVICE EP1C6Q240C8
	set_global_assignment -name ORIGINAL_QUARTUS_VERSION 9.1
	set_global_assignment -name PROJECT_CREATION_TIME_DATE "23:32:28  MAY 03, 2017"
	set_global_assignment -name LAST_QUARTUS_VERSION 9.1
	set_global_assignment -name USE_GENERATED_PHYSICAL_CONSTRAINTS OFF -section_id eda_blast_fpga
	set_global_assignment -name MIN_CORE_JUNCTION_TEMP 0
	set_global_assignment -name MAX_CORE_JUNCTION_TEMP 85
	set_global_assignment -name PARTITION_NETLIST_TYPE SOURCE -section_id Top
	set_global_assignment -name PARTITION_COLOR 16764057 -section_id Top
	set_global_assignment -name LL_ROOT_REGION ON -section_id "Root Region"
	set_global_assignment -name LL_MEMBER_STATE LOCKED -section_id "Root Region"
	set_global_assignment -name QIP_FILE lpm_rom0.qip
	set_global_assignment -name VERILOG_FILE LCD_Picture_Disp.v
	set_instance_assignment -name PARTITION_HIERARCHY root_partition -to | -section_id Top
	set_location_assignment PIN_61 -to rst_n
	set_location_assignment PIN_28 -to clock
	set_location_assignment PIN_176 -to rw
	set_location_assignment PIN_177 -to rs
	set_location_assignment PIN_175 -to en
	set_location_assignment PIN_174 -to data[0]
	set_location_assignment PIN_173 -to data[1]
	set_location_assignment PIN_170 -to data[2] 	
	set_location_assignment PIN_169 -to data[3]
	set_location_assignment PIN_168 -to data[4]
	set_location_assignment PIN_167 -to data[5]
	set_location_assignment PIN_166 -to data[6]
	set_location_assignment PIN_165 -to data[7]

	# Commit assignments
	export_assignments

	# Close project
	if {$need_to_close_project} {
		project_close
	}
}

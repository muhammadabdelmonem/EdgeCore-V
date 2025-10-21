# set_project_properties.tcl

set vivado_version [version -short]
set vivado_year [string range $vivado_version 0 3]

puts "Setting project properties for Vivado $vivado_version"

# Basic project settings (common across versions)
set_property target_language VHDL [current_project]
set_property default_lib work [current_project]

# Version-specific settings
if {$vivado_year >= 2025} {
    # Vivado 2025.1 specific settings
    set_property board_part_repo_paths {./board_files} [current_project]
    set_property source_mgmt_mode All [current_project]
    
} elseif {$vivado_year >= 2023} {
    # Vivado 2023.1 specific settings  
    set_property source_mgmt_mode All [current_project]
    
} elseif {$vivado_year >= 2021} {
    # Vivado 2021.1 specific settings
    set_property source_mgmt_mode DisplayOnly [current_project]
    
} else {
    # Vivado 2019.1 specific settings
    set_property source_mgmt_mode DisplayOnly [current_project]
}

# Set common simulation properties
if {$vivado_year >= 2021} {
    set_property target_simulator XSim [current_project]
    set_property -name {xsim.simulate.runtime} -value {1000ns} -objects [get_filesets sim_1]
}
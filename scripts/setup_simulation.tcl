# setup_simulation.tcl

set vivado_version [version -short]
set vivado_year [string range $vivado_version 0 3]

puts "Setting up simulation for Vivado $vivado_version"

# Add simulation sources if they exist
if {[file exists "./src/sim"]} {
    add_files -fileset sim_1 -norecurse ./src/sim
    puts "Added simulation sources from ./src/sim"
}

# Set simulation properties based on version
if {$vivado_year >= 2023} {
    # Vivado 2023.1+ simulation settings
    set_property -name {xsim.elaborate.debug_level} -value {all} -objects [get_filesets sim_1]
    
} elseif {$vivado_year >= 2021} {
    # Vivado 2021.1 simulation settings  
    set_property -name {xsim.elaborate.debug_level} -value {all} -objects [get_filesets sim_1]
    
} else {
    # Vivado 2019.1 simulation settings
    set_property -name {xsim.simulate.log_all_signals} -value {true} -objects [get_filesets sim_1]
}

puts "Simulation setup completed"
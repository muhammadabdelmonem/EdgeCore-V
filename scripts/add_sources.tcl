# add_sources.tcl

set vivado_version [version -short]
set vivado_year [string range $vivado_version 0 3]

puts "Adding source files for Vivado $vivado_version"

# Add HDL sources
if {[file exists "./src/hdl"]} {
    add_files -norecurse ./src/hdl
    puts "Added HDL sources from ./src/design"
}

# Add constraints with version-specific handling
if {[file exists "./src/constraints"]} {
    add_files -fileset constrs_1 -norecurse ./src/constraints
    puts "Added constraints from ./src/constraints"
}

# Update compile order with version-appropriate method
if {$vivado_year >= 2021} {
    update_compile_order -fileset sources_1
} else {
    # 2019.1 uses different method
    update_compile_order
}

puts "Source file addition completed"
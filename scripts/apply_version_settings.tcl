# apply_version_settings.tcl

set vivado_version [version -short]
set vivado_year [string range $vivado_version 0 3]

puts "Applying version-specific settings for Vivado $vivado_version"

# Implementation strategy settings
if {$vivado_year >= 2025} {
    # Vivado 2025.1 strategies
    set_property strategy Performance_RefinePlacement [get_runs impl_1]
    set_property steps.phys_opt_design.is_enabled true [get_runs impl_1]
    
} elseif {$vivado_year >= 2023} {
    # Vivado 2023.1 strategies  
    set_property strategy Performance_Explore [get_runs impl_1]
    set_property steps.phys_opt_design.is_enabled true [get_runs impl_1]
    
} elseif {$vivado_year >= 2021} {
    # Vivado 2021.1 strategies
    set_property strategy Performance_Explore [get_runs impl_1]
    set_property steps.phys_opt_design.is_enabled true [get_runs impl_1]
    
} else {
    # Vivado 2019.1 strategies
    set_property strategy Performance_Explore [get_runs impl_1]
    set_property steps.phys_opt_design.is_enabled true [get_runs impl_1]
}

# Version-specific constraint management
if {[file exists "./src/constraints"]} {
    if {$vivado_year >= 2023} {
        # Newer constraint management
        import_files -fileset constrs_1 ./src/constraints
    } else {
        # Legacy constraint management
        add_files -fileset constrs_1 ./src/constraints
    }
}

puts "Version-specific settings applied"
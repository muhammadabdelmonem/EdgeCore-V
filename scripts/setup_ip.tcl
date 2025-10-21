# setup_ip.tcl

set vivado_version [version -short]
set vivado_year [string range $vivado_version 0 3]

puts "Setting up IP cores for Vivado $vivado_version"

# Check if IP directory exists
if {[file exists "./ip"]} {
    
    if {$vivado_year >= 2023} {
        # Vivado 2023.1+ - Use modern IP management
        set_property coreContainer.enable true [current_project]
        
        # Add IP from IP directory
        if {[file exists "./ip/ip_repo"]} {
            set_property ip_repo_paths ./ip/ip_repo [current_project]
            update_ip_catalog -rebuild
        }
        
    } elseif {$vivado_year >= 2021} {
        # Vivado 2021.1 - Transitional IP management
        set_property coreContainer.enable false [current_project]
        
        # Add individual IP files
        set ip_files [glob -nocomplain "./ip/*.xci"]
        if {[llength $ip_files] > 0} {
            add_files -norecurse $ip_files
            puts "Added IP files: $ip_files"
        }
        
    } else {
        # Vivado 2019.1 - Legacy IP management
        set_property coreContainer.enable false [current_project]
        
        # Add individual IP files with legacy method
        set ip_files [glob -nocomplain "./ip/*.xci"] 
        if {[llength $ip_files] > 0} {
            add_files -norecurse $ip_files
            puts "Added IP files: $ip_files"
        }
    }
    
    # Report IP status
    if {$vivado_year >= 2020} {
        report_ip_status
    }
}

puts "IP setup completed"
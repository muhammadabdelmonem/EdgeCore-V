{\rtf1\ansi\ansicpg1252\cocoartf2865
\cocoatextscaling0\cocoaplatform0{\fonttbl\f0\fswiss\fcharset0 Helvetica;}
{\colortbl;\red255\green255\blue255;}
{\*\expandedcolortbl;;}
\paperw11900\paperh16840\margl1440\margr1440\vieww11520\viewh8400\viewkind0
\pard\tx720\tx1440\tx2160\tx2880\tx3600\tx4320\tx5040\tx5760\tx6480\tx7200\tx7920\tx8640\pardirnatural\partightenfactor0

\f0\fs24 \cf0 # create_project_adaptive.tcl\
#\
# Usage: vivado -source create_project_adaptive.tcl -tclargs <project_name> <part_name>\
#\
# Example: vivado -source create_project_adaptive.tcl -tclargs my_design xc7z020clg400-1\
\
# Parse command line arguments\
if \{[llength $argv] >= 2\} \{\
    set project_name [lindex $argv 0]\
    set part_name [lindex $argv 1]\
\} else \{\
    puts "ERROR: Please provide project name and part name as arguments"\
    puts "Usage: vivado -source create_project_adaptive.tcl -tclargs <project_name> <part_name>"\
    exit 1\
\}\
\
# Get Vivado version and detect major version\
set vivado_version [version -short]\
set vivado_year [string range $vivado_version 0 3]\
\
puts "================================================"\
puts "Creating project '$project_name' for Vivado $vivado_version"\
puts "Target device: $part_name"\
puts "================================================"\
\
# Create version-specific project directory\
set project_dir "./project_$\{vivado_version\}"\
file mkdir $project_dir\
\
# Create project with version-appropriate method\
if \{$vivado_year >= 2023\} \{\
    # Vivado 2023.1 and newer (including 2025.1)\
    create_project -force $project_name $project_dir -part $part_name\
\} else \{\
    # Vivado 2022.1 and older (2019.1, 2021.1)\
    create_project -force $project_name $project_dir -part $part_name\
\}\
\
# Set project properties based on version\
source scripts/set_project_properties.tcl\
\
# Add source files\
source scripts/add_sources.tcl\
\
# Setup IP cores based on version\
source scripts/setup_ip.tcl\
\
# Setup simulation if needed\
source scripts/setup_simulation.tcl\
\
# Apply version-specific constraints and settings\
source scripts/apply_version_settings.tcl\
\
puts "================================================"\
puts "Project creation completed successfully!"\
puts "Project location: $project_dir"\
puts "Vivado version: $vivado_version"\
puts "================================================"}
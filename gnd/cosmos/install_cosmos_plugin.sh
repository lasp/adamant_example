#!/bin/sh

#
# Copy COSMOS plugin configuration to argument directory
# This will likely be moved to the Adamant repository
# COSMOS install directory argument should be relative to the Linux example path
# Ex. `./install_cosmos_plugin.sh ../../src/assembly/linux/linux_example.assembly.yaml ../../../cosmos-project` if COSMOS is adjacent to adamant_example

adamant_assembly_dir=$1 # relative path to assembly yaml file
cosmos_install_dir=$2 # relative path to COSMOS installation
if [[ $1 == "" ]]
 then
 echo "Adamant assembly name argument not provided."
 echo "Usage: \"./install_cosmos_plugin.sh ../../src/assembly/linux/linux_example.assembly.yaml ../../../cosmos-project\""
 echo "Exiting."
 exit 1
elif [[ $2 == "" ]]
 then
 echo "COSMOS installation location argument not provided."
 echo "Usage: \"./install_cosmos_plugin.sh ../../src/assembly/linux/linux_example.assembly.yaml ../../../cosmos-project\""
 echo "Exiting."
 exit 1
fi
adamant_assembly_name=${adamant_assembly_dir%.assembly.yaml}
adamant_assembly_name=${adamant_assembly_name##*/}
cosmos_plugin_dir=`realpath $cosmos_install_dir/openc3-cosmos-${adamant_assembly_name//_/-}`
# Get build directory:
adamant_assembly_name_short=(${adamant_assembly_name//_/ })
adamant_example_plugin_dir=`realpath ../../src/assembly/${adamant_assembly_name_short[0]}/build/cosmos/plugin`
adamant_example_template_dir=`realpath ../../src/assembly/${adamant_assembly_name_short[0]}/build/cosmos/template`
adamant_protocol_dir=`realpath ../../../adamant/gnd/cosmos`
# Copy all protocol files (plugins compile with only needed protocols):
cp -a $adamant_protocol_dir/*.rb $cosmos_plugin_dir/targets/${adamant_assembly_name^^}/lib/
# Copy plugin configuration files with error checking:
if [[ -f "$adamant_example_plugin_dir/${adamant_assembly_name}_ccsds_cosmos_commands.txt" ]]; then
 cp $adamant_example_plugin_dir/${adamant_assembly_name}_ccsds_cosmos_commands.txt $cosmos_plugin_dir/targets/${adamant_assembly_name^^}/cmd_tlm/cmd.txt
else
 echo "\"${adamant_assembly_name}_ccsds_cosmos_commands.txt\" does not exist, run \"redo cosmos_config\" from the Adamant assembly."
 exit 1
fi
if [[ -f "$adamant_example_plugin_dir/${adamant_assembly_name}_ccsds_cosmos_telemetry.txt" ]]; then
 cp $adamant_example_plugin_dir/${adamant_assembly_name}_ccsds_cosmos_telemetry.txt $cosmos_plugin_dir/targets/${adamant_assembly_name^^}/cmd_tlm/tlm.txt
else
 echo "\"${adamant_assembly_name}_ccsds_cosmos_telemetry.txt\" does not exist, run \"redo cosmos_config\" from the Adamant assembly."
 exit 1
fi
if [[ -f "$adamant_example_template_dir/${adamant_assembly_name}_ccsds_cosmos_plugin.txt" ]]; then
 cp $adamant_example_template_dir/${adamant_assembly_name}_ccsds_cosmos_plugin.txt $cosmos_plugin_dir/plugin.txt
else
 echo "\"${adamant_assembly_name}_ccsds_cosmos_plugin.txt\" does not exist, run \"redo cosmos_config\" from the Adamant assembly."
 exit 1
fi

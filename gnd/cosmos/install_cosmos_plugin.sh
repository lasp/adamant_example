#!/bin/sh

#
# Copy COSMOS plugin configuration to argument directory
# This will likely be moved to the Adamant repository
# COSMOS install directory argument should be relative to the Linux example path
# Ex. `./install_cosmos_plugin.sh linux_example cosmos-project` if COSMOS is adjacent to adamant_example

adamant_assembly_name=$1
cosmos_install_name=$2
if [[ $1 == "" ]]
 then
 echo "Adamant assembly name argument not provided."
 echo "Usage: \"./install_cosmos_plugin.sh Adamant_assembly_name path_to_COSMOS_directory\""
 echo "Exiting."
 exit 1
elif [[ $2 == "" ]]
 then
 echo "COSMOS installation location argument not provided."
 echo "Usage: \"./install_cosmos_plugin.sh Adamant_assembly_name path_to_COSMOS_directory\""
 echo "Exiting."
 exit 1
fi
cosmos_install_dir=`realpath ../../../$cosmos_install_name`
cosmos_plugin_dir=`realpath $cosmos_install_dir/openc3-cosmos-${adamant_assembly_name//_/-}`
# Get build directory:
adamant_assembly_name_short=(${adamant_assembly_name//_/ })
adamant_example_plugin_dir=`realpath ../../src/assembly/${adamant_assembly_name_short[0]}/build/cosmos/plugin`
adamant_protocol_dir=`realpath ../../../adamant/gnd/cosmos`
# Get requested protocols in plugin.txt:
requested_protocol_array=($(grep \"*.rb "${adamant_example_plugin_dir}/${adamant_assembly_name}_ccsds_cosmos_plugin.txt" | cut -d' ' -f5))
cp $adamant_example_plugin_dir/${adamant_assembly_name}_ccsds_cosmos_commands.txt $cosmos_plugin_dir/targets/${adamant_assembly_name^^}/cmd_tlm/cmd.txt
cp $adamant_example_plugin_dir/${adamant_assembly_name}_ccsds_cosmos_telemetry.txt $cosmos_plugin_dir/targets/${adamant_assembly_name^^}/cmd_tlm/tlm.txt
cp $adamant_example_plugin_dir/${adamant_assembly_name}_ccsds_cosmos_plugin.txt $cosmos_plugin_dir/plugin.txt
# Check requested protocols against those available from Adamant:
for i in "${requested_protocol_array[@]}"; do
    if [ -f $adamant_protocol_dir/$i ]
    then cp $adamant_protocol_dir/$i $cosmos_plugin_dir/targets/${adamant_assembly_name^^}/lib/$i
    fi
done

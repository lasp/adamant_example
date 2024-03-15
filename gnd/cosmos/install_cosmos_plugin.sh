#!/bin/sh

#
# Copy COSMOS plugin configuration to argument directory
# This will likely be moved to the Adamant repository
# COSMOS install directory argument should be relative to the Linux example path
# Ex. `./install_cosmos_plugin.sh linux_example cosmos-project` if COSMOS is adjacent to adamant_example

adamant_assembly_name=$1
cosmos_install_name=$2
cosmos_install_dir=`realpath ../../../$cosmos_install_name`
cosmos_plugin_dir=`realpath $cosmos_install_dir/openc3-cosmos-${adamant_assembly_name//_/-}`
adamant_example_plugin_dir=`realpath ../../src/assembly/linux/build/cosmos/plugin`
adamant_protocol_dir=`realpath ../../../adamant/gnd/cosmos`
echo cp $adamant_example_plugin_dir/${adamant_assembly_name}_ccsds_cosmos_commands.txt $cosmos_plugin_dir/targets/${adamant_assembly_name^^}/cmd_tlm/cmd.txt
echo cp $adamant_example_plugin_dir/${adamant_assembly_name}_ccsds_cosmos_telemetry.txt $cosmos_plugin_dir/targets/${adamant_assembly_name^^}/cmd_tlm/tlm.txt
echo cp $adamant_example_plugin_dir/${adamant_assembly_name}_ccsds_cosmos_plugin.txt $cosmos_plugin_dir/plugin.txt
echo cp $adamant_protocol_dir/cmd_checksum.rb $cosmos_plugin_dir/targets/${adamant_assembly_name^^}/lib/cmd_checksum.rb

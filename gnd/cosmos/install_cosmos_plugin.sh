#!/bin/sh

#
# Copy COSMOS plugin configuration to argument directory
# This will likely be moved to the Adamant repository
# COSMOS install directory argument should be relative to the Linux example path
# Ex. `./install_cosmos_plugin.sh cosmos-project` if COSMOS is adjacent to adamant_example

cosmos_install_name=$1
cosmos_install_dir=`realpath ../../../$cosmos_install_name`
cosmos_plugin_dir=`realpath $cosmos_install_dir/openc3-cosmos-linux-example`
adamant_example_plugin_dir=`realpath ../../src/assembly/linux/build/cosmos/plugin`
adamant_protocol_dir=`realpath ../../../adamant/gnd/cosmos`
echo cp $adamant_example_plugin_dir/linux_example_ccsds_cosmos_commands.txt $cosmos_plugin_dir/targets/LINUX_EXAMPLE/cmd_tlm/cmd.txt
echo cp $adamant_example_plugin_dir/linux_example_ccsds_cosmos_telemetry.txt $cosmos_plugin_dir/targets/LINUX_EXAMPLE/cmd_tlm/tlm.txt
echo cp $adamant_example_plugin_dir/linux_example_ccsds_cosmos_plugin.txt $cosmos_plugin_dir/plugin.txt
echo cp $adamant_protocol_dir/cmd_checksum.rb $plugin_dir/targets/LINUX_EXAMPLE/lib/cmd_checksum.rb

#!/bin/bash

#
# Copy COSMOS plugin configuration from Adamant into COSMOS plugin directory
# Ex. `./install_cosmos_plugin.sh ../../src/assembly/linux/linux_example.assembly.yaml ../../../cosmos-project` if COSMOS is adjacent to adamant_example

adamant_assembly_model=$1 # path to assembly yaml file
cosmos_plugin_dir=$2 # path to COSMOS plugin within the COSMOS installation

if [[ $1 == "" ]]
then
  echo "Adamant assembly model argument not provided."
  echo "Usage: \"./install_cosmos_plugin.sh ../../src/assembly/linux/linux_example.assembly.yaml ../../../cosmos-project/openc3-cosmos-plugin-dir\""
  echo "Exiting."
  exit 1
elif [[ $2 == "" ]]
  then
  echo "COSMOS plugin directory argument not provided."
  echo "Usage: \"./install_cosmos_plugin.sh ../../src/assembly/linux/linux_example.assembly.yaml ../../../cosmos-project/openc3-cosmos-plugin-dir\""
  echo "Exiting."
  exit 1
fi

this_dir=`readlink -f "${BASH_SOURCE[0]}" | xargs dirname`
adamant_assembly_name=${adamant_assembly_model%.assembly.yaml}
adamant_assembly_name=${adamant_assembly_name##*/}
adamant_assembly_dir=`dirname $adamant_assembly_model`
cosmos_plugin_dir=`realpath $cosmos_plugin_dir`

# Get build directory:
adamant_assembly_name_short=(${adamant_assembly_name//_/ })
adamant_assembly_name_upper=$(tr [:lower:] [:upper:] <<< "$adamant_assembly_name")
adamant_assembly_cmdtlm_dir=`realpath $adamant_assembly_dir/build/cosmos/plugin`
adamant_assembly_plugin_dir=`realpath $adamant_assembly_dir/main/cosmos/plugin`
adamant_protocol_dir=`realpath $this_dir/../../../adamant/gnd/cosmos`

# Copy all protocol files (plugins compile with only needed protocols):
echo "Copying over plugin files..."
cp -vfa $adamant_protocol_dir/*.rb $cosmos_plugin_dir/targets/$adamant_assembly_name_upper/lib/

do_copy() {
  src=$1
  dest=$2
  if [[ -f "$src" ]]; then
      cp -vf "$src" "$dest"
  else
      echo "\"$src\" does not exist, run \"redo cosmos_config\" from the Adamant assembly, or make sure the required source is present."
      exit 1
  fi
}

# Copy plugin configuration files with error checking:
do_copy "$adamant_assembly_cmdtlm_dir/${adamant_assembly_name}_ccsds_cosmos_commands.txt" $cosmos_plugin_dir/targets/$adamant_assembly_name_upper/cmd_tlm/cmd.txt
do_copy "$adamant_assembly_cmdtlm_dir/${adamant_assembly_name}_ccsds_cosmos_telemetry.txt" $cosmos_plugin_dir/targets/$adamant_assembly_name_upper/cmd_tlm/tlm.txt
do_copy "$adamant_assembly_plugin_dir/plugin.txt" $cosmos_plugin_dir/plugin.txt
echo "Success."
echo "Plugin files copied to $cosmos_plugin_dir."

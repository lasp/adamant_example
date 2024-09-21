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
adamant_script_dir=`realpath $adamant_assembly_dir/../../../test/scripts`
cosmos_script_dir=`realpath $cosmos_plugin_dir/../plugins/DEFAULT/targets_modified`

# Get build directory:
adamant_assembly_name_short=(${adamant_assembly_name//_/ })
adamant_assembly_name_upper=$(tr [:lower:] [:upper:] <<< "$adamant_assembly_name")
adamant_assembly_cmdtlm_dir=`realpath $adamant_assembly_dir/build/cosmos/plugin`
adamant_assembly_plugin_dir=`realpath $adamant_assembly_dir/main/cosmos/plugin`
adamant_protocol_dir=`realpath $this_dir/../../../adamant/gnd/cosmos`
adamant_dir=`realpath $this_dir/../../../adamant`

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
do_copy "$adamant_script_dir/update-param-sys.py" $cosmos_script_dir/update-param-sys.py
do_copy "$adamant_script_dir/validate-param-sys.py" $cosmos_script_dir/validate-param-sys.py
do_copy "$adamant_script_dir/test_setup.py" $cosmos_script_dir/test_setup.py
do_copy "$adamant_script_dir/crc_16.py" $cosmos_script_dir/crc_16.py
do_copy "$adamant_assembly_dir/build/py/${adamant_assembly_name}_parameter_table_record.py" $cosmos_script_dir/${adamant_assembly_name}_parameter_table_record.py
mkdir -p $cosmos_script_dir/base_classes
do_copy "$adamant_dir/src/types/parameter/build/py/parameter_table_header.py" $cosmos_script_dir/parameter_table_header.py
do_copy "$adamant_dir/src/types/packed_types/build/py/packed_f32.py" $cosmos_script_dir/packed_f32.py
do_copy "$adamant_dir/gnd/base_classes/packed_type_base.py" $cosmos_script_dir/base_classes/packed_type_base.py
echo "Success."
echo "Plugin files copied to $cosmos_plugin_dir."
echo "Script files copied to $cosmos_script_dir."

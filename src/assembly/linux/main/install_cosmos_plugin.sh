#!/bin/sh

#
# This is a convenience script that calls a script of the same name in gnd/cosmos with the correct first argument for this assembly
# The second argument should be the relative path from the top directory of the example assembly to the COSMOS directory.
# Ex. `./install_cosmos_plugin.sh cosmos-project` if COSMOS is adjacent to adamant_example

cosmos_dir=$1
assembly_yaml='linux_example.assembly.yaml'
cd ../../../../gnd/cosmos
./install_cosmos_plugin.sh ../../src/assembly/linux/$assembly_yaml ../../../$cosmos_dir
cd - >/dev/null

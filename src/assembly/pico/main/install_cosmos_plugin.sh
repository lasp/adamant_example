#!/bin/bash

if [[ $1 == "" ]]
 then
 echo "COSMOS plugin directory path not provided."
 echo "Usage: \"./install_cosmos_plugin.sh ../../../../../cosmos-project/openc3-cosmos-pico-example/\""
 echo "Exiting."
 exit 1
fi

cosmos_dir=$1
this_dir=`readlink -f "${BASH_SOURCE[0]}" | xargs dirname`
assembly_yaml=`ls -1 $this_dir/../*.assembly.yaml`
$this_dir/../../../../gnd/cosmos/install_cosmos_plugin.sh $assembly_yaml $cosmos_dir

# Create Cosmos plugin configuration files:
export TARGET=
this_dir=`dirname "$0"`
cosmos_dir=`realpath $this_dir/../../../../gnd/cosmos`
assembly_dir=`realpath $this_dir/..`
$cosmos_dir/build_cosmos_plugin.sh $assembly_dir >/dev/null

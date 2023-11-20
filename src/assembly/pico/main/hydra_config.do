# Start Hydra:
export TARGET=Pico
this_dir=`dirname "$0"`
hydra_dir=`realpath $this_dir/../../../../gnd/hydra`
config_file=$this_dir/hydra/hydra_config.xml
assembly_dir=`realpath $this_dir/..`
assembly_file=`ls $assembly_dir'/'*'.assembly.yaml' | head -1`
$hydra_dir/build_hydra_config.sh $assembly_file $config_file >/dev/null

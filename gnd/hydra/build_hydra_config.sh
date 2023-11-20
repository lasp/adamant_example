#!/bin/sh

#
# Configure hydra for a particular assembly and then
# start hydra in the background.
#

assembly_file=$1
config_file=$2
background=$3

# Check commandline arguments:
if test -z "$assembly_file" || test -z "$config_file"
then
  echo "Usage: build_hydra_config.sh /path/to/assembly_file.assembly.yaml /path/to/hydra/hydra_config.xml" >&2
  exit 1
fi

# Set some other vars:
assembly_name=`basename $assembly_file .assembly.yaml`
config_dir=`dirname $config_file`
assembly_dir=`dirname $assembly_file`

# Build all hydra scripts and pages:
cd $assembly_dir
scripts=`redo what 2>&1 | grep "hydra/Scripts" | awk '{ print $2 }'`
pages=`redo what 2>&1 | grep "hydra/Pages" | awk '{ print $2 }'`
{
  echo $scripts
  echo $pages
} | xargs redo-ifchange
cd - >/dev/null

# Dirty work around to get autocoded pages into hydra. Eventually hydra will be
# updated and we won't have to do this copy.
pages_dir=$config_dir/Pages/$assembly_name
mkdir -p $pages_dir
for page in $pages
do
  cp $assembly_dir/$page $pages_dir
done

# Depend on all hydra dependencies specified in the config file:
$ADAMANT_DIR/redo/bin/redo_hydra_deps.py $config_file

#!/bin/sh

#
# Configure cosmos plugin
#

assembly_dir=$1
# Build all cosmos plugin command and telemetry files:
cd $assembly_dir
plugin=`redo what 2>&1 | grep "cosmos" | awk '{ print $2 }'`
echo $plugin | xargs redo-ifchange
cd - >/dev/null

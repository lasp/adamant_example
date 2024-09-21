#!/bin/sh

#
# Configure cosmos plugin
#

assembly_dir=$1
# Build all cosmos plugin command and telemetry files:
cd $assembly_dir
plugin=`redo what 2>&1 | grep "cosmos" | awk '{ print $2 }'`
echo $plugin | xargs redo-ifchange
record_type=`redo what 2>&1 | grep "parameter_table_record.py" | awk '{ print $2 }'`
echo $record_type | xargs redo-ifchange
cd '../../../../adamant/src/types/parameter'
record_type=`redo what 2>&1 | grep "parameter_table_header.py" | awk '{ print $2 }'`
echo $record_type | xargs redo-ifchange
cd '../packed_types'
record_type=`redo what 2>&1 | grep "packed_f32.py" | awk '{ print $2 }'`
echo $record_type | xargs redo-ifchange
cd - >/dev/null

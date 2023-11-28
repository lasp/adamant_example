#!/bin/sh

# This script sets up the environment for the example project.

# Only set the environment once:
if test -n "$EXAMPLE_ENVIRONMENT_SET"
then
  return
fi

if test -z "$EXAMPLE_DIR" # ie. /home/user/adamant_example
then
  echo "EXAMPLE_DIR not set in environment." >&2
  exit 1
fi

# Source the setenv script from the adamant repository:
. $ADAMANT_DIR/env/setenv.sh

# Add local python packages to the python path:
. $ADAMANT_DIR/env/set_python_path.sh $EXAMPLE_DIR

# Set the path to our Adamant configuration file for example:
export ADAMANT_CONFIGURATION_YAML=$EXAMPLE_DIR/config/example.configuration.yaml

# This runs "export GPR_PROJECT_PATH=etc" which sets the GPR_PROJECT_PATH
# to whatever alr thinks it should be for the Adamant example project crate.
# This allows the Adamant build system to then use gprbuild in the same way
# that alr would.
#
# Also update PATH. Alire will include the current PATH set by the Adamant
# environment plus some alire specific paths.
#
cd $EXAMPLE_DIR
eval `alr printenv | grep PATH`
cd - &> /dev/null

# Signify the environment it set up:
export EXAMPLE_ENVIRONMENT_SET="yes"

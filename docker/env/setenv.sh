#!/bin/sh

# This script sets up the environment for the example project.
echo "Setting up environment..."

# Source the setenv script from the adamant repository:
INSTALL_DIR=$HOME/env
ADAMANT_DIR=$HOME/adamant
EXAMPLE_DIR=$HOME/adamant_example
export EXAMPLE_DIR
export INSTALL_DIR
export ADAMANT_DIR

# Set the environment for docker:
. $EXAMPLE_DIR/docker/env/_setenv.sh

# Make sure unison is started:
sh $EXAMPLE_DIR/docker/env/start_unison.sh
echo "Done."

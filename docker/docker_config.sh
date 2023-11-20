#!/bin/sh

DOCKER_CONTAINER_NAME="adamant_example_container"
DOCKER_IMAGE_NAME="dinkelk/adamant:example-latest"
export DOCKER_CONTAINER_NAME
export DOCKER_IMAGE_NAME

case "$OSTYPE" in
  cygwin|msys|win32)
    ON_WINDOWS="yes"
    export ON_WINDOWS
    ;;
esac

# Helper function to print out command as executed:
execute () {
  echo "$ $@"
  eval "$@"
}

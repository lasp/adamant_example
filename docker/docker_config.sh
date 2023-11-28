#!/bin/sh

DOCKER_CONTAINER_NAME="adamant_example_container"
DOCKER_IMAGE_NAME="ghcr.io/lasp/adamant:example-latest"
export DOCKER_CONTAINER_NAME
export DOCKER_IMAGE_NAME

# Helper function to print out command as executed:
execute () {
  echo "$ $@"
  eval "$@"
}

#!/bin/sh

. ./docker_config.sh
execute "docker push ghcr.io/$DOCKER_IMAGE_NAME"

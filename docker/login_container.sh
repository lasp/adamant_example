#!/bin/sh

. ./docker_config.sh

if [ -n "$ON_WINDOWS" ]; then
  execute "winpty docker exec -it -u user $DOCKER_CONTAINER_NAME //bin//bash"
else
  execute "docker exec -it -u user $DOCKER_CONTAINER_NAME /bin/bash"
fi

#!/bin/sh

. ./docker_config.sh
execute "docker start $DOCKER_CONTAINER_NAME"
if [ -n "$ON_WINDOWS" ]; then
  execute "winpty docker exec -u user $DOCKER_CONTAINER_NAME //share//adamant_example//docker//env//start_unison.sh &"
else
  execute "docker exec -u user $DOCKER_CONTAINER_NAME /share/adamant_example/docker/env/start_unison.sh &"
fi
execute "docker ps -a"

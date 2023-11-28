#!/bin/sh

. ./docker_config.sh
execute "docker start $DOCKER_CONTAINER_NAME"
execute "docker exec -u user $DOCKER_CONTAINER_NAME //share//adamant_example//docker//env//start_unison.sh &"
execute "docker ps -a"

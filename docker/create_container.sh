#!/bin/sh

# Create the docker container with a bind mount:
echo "Creating container..."
. ./docker_config.sh
execute "docker run -d \
  --name $DOCKER_CONTAINER_NAME \
  --mount type=bind,source=\"$(pwd)\"/../..,target=/share \
  $DOCKER_IMAGE_NAME \
  sleep infinity"

# Run docker provision script inside of container to get things set up:
echo "Provisioning container..."
if [ -n "$ON_WINDOWS" ]; then
  execute "winpty docker exec -u user $DOCKER_CONTAINER_NAME //share//example//docker//env//provision//provision_container.sh"
else
  execute "docker exec -u user $DOCKER_CONTAINER_NAME /share/example/docker/env/provision/provision_container.sh"
fi

echo "Finished creating container \"$DOCKER_CONTAINER_NAME\"."
execute "docker ps -a"

echo ""
echo "Run ./login_container.sh to log in."

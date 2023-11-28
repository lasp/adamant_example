#!/bin/sh

# Create the docker container with a bind mount:
echo "Creating container..."
. ./docker_config.sh
if [ -n "ON_LINUX" ]; then
  execute "docker run -d \
    --name $DOCKER_CONTAINER_NAME \
    --mount type=bind,source=\"$(pwd)\"/../..,target=/share \
    --add-host=host.docker.internal:host-gateway \
    $DOCKER_IMAGE_NAME \
    sleep infinity"
else
  execute "docker run -d \
    --name $DOCKER_CONTAINER_NAME \
    --mount type=bind,source=\"$(pwd)\"/../..,target=/share \
    $DOCKER_IMAGE_NAME \
    sleep infinity"
fi

# Run docker provision script inside of container to get things set up:
echo "Provisioning container..."
execute "docker exec -u user $DOCKER_CONTAINER_NAME //share//adamant_example//docker//env//provision//provision_container.sh"

echo "Finished creating container \"$DOCKER_CONTAINER_NAME\"."
execute "docker ps -a"

echo ""
echo "Run ./login_container.sh to log in."

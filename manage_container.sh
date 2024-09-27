#!/bin/bash

USERNAME=$1
ACTION=$2

CONTAINER_NAME="hivelab-${USERNAME}"
IMAGE_NAME="ubuntu:latest"

case $ACTION in
  start)
    if ! docker ps -a --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
      # Create user's workspace directory if it doesn't exist
      mkdir -p /home/${USERNAME}/workspace
      chown  ${USERNAME} /home/${USERNAME}/workspace

      # Create the container
      docker run -d --name ${CONTAINER_NAME} \
        -v /home/${USERNAME}/workspace:/home/workspace \
        -v /var/run/docker.sock:/var/run/docker.sock \
        --cap-add=SYS_PTRACE --security-opt seccomp=unconfined \
        ${IMAGE_NAME} sleep infinity

      # Set up the container
    docker exec ${CONTAINER_NAME} bash -c "
        apt-get update || true
        apt-get install -y sudo curl wget || true
        echo \"Creating user: ${USERNAME}\"
        useradd -ms /bin/bash ${USERNAME}
        echo \"${USERNAME} ALL=(ALL) NOPASSWD:ALL\" >> /etc/sudoers
        chown -R ${USERNAME}:${USERNAME} /home/workspace
    "
    elif ! docker ps --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
      docker start ${CONTAINER_NAME}
    fi
    ;;
  stop)
    docker stop ${CONTAINER_NAME}
    ;;
  remove)
    docker rm -f ${CONTAINER_NAME}
    ;;
esac
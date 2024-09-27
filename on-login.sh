#!/bin/bash

if [ "$SSH_ORIGINAL_COMMAND" == "bypass" ]; then
    exec $SHELL
    exit 0
fi

USERNAME=$(whoami)

# Start or ensure the user's container is running
/opt/hivelab/manage_container.sh $USERNAME start

# Get the container ID
CONTAINER_ID=$(docker ps --filter name=hivelab-$USERNAME --format '{{.ID}}')

if [ -z "$CONTAINER_ID" ]; then
    echo "Failed to start or find your HiveLab container. Please contact support."
    exit 1
fi

# Execute an interactive bash session in the user's container
exec docker exec -it -e TERM=$TERM -e LANG=$LANG -u  $USERNAME $CONTAINER_ID /bin/bash -l
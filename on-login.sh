#!/bin/bash

if [ "$SSH_ORIGINAL_COMMAND" == "bypass" ]; then
    exec $SHELL
    exit 0
fi

USERNAME=$(whoami)

echo "🐝 Welcome to Hive-Lab 🐝"
echo "📦 Version 1.2.0!"
echo "🤝 Contribute at: https://github.com/tristanpoland/Hive-Lab"
echo "🔒 Loggin in as: ${USERNAME}"


echo "🍯 Making sure your nest is running..."

# Start or ensure the user's container is running
/opt/hivelab/manage_container.sh $USERNAME start

# Get the container ID
CONTAINER_ID=$(docker ps --filter name=hivelab-$USERNAME --format '{{.ID}}')

if [ -z "$CONTAINER_ID" ]; then
    echo "Failed to start or find your HiveLab container. Please contact an adminstrator for support."
    exit 1
fi

# Execute an interactive bash session in the user's container
echo "🌐 connecting you to your nest..."
exec docker exec -it -e TERM=$TERM -e LANG=$LANG -u  $USERNAME $CONTAINER_ID /bin/bash -l

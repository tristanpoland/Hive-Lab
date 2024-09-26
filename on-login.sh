#!/bin/bash

# Check if bypass command is used
if [ "\$SSH_ORIGINAL_COMMAND" == "bypass" ]; then
    exec \$SHELL
    exit 0
fi

USERNAME=\$(whoami)

# Start or ensure the user's container is running
/opt/hivelab/manage_container.sh \$USERNAME start

# Get the container ID
CONTAINER_ID=\$(docker ps --filter name=hivelab-\$USERNAME --format '{{.ID}}')

# Check if the container ID is empty
if [ -z "\$CONTAINER_ID" ]; then
    echo "Failed to start or find your HiveLab container. Dropping to shell."
    exec /bin/bash  # Drop to a shell if the container cannot be started
fi

# Use exec to start an interactive Bash session in the user's container
exec docker exec -it -e TERM=\$TERM -e LANG=\$LANG -u vscode \$CONTAINER_ID /bin/bash

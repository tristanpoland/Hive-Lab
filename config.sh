#!/bin/bash

set -e

# Colors for output
GREEN='\033[0;32m'
NC='\033[0m' # No Color

# Function to print status messages
print_status() {
    echo -e "${GREEN}[*] $1${NC}"
}

# Install necessary packages
print_status "Installing necessary packages..."
sudo apt-get update
sudo apt-get install -y jq docker.io

# Set up Docker permissions
print_status "Setting up Docker permissions..."
sudo usermod -aG docker $USER

# Create directory for HiveLab scripts
print_status "Creating HiveLab directory..."
sudo mkdir -p /opt/hivelab
sudo chown $USER:$USER /opt/hivelab

# Copy on-login.sh to the HiveLab directory
print_status "Copying on-login.sh to HiveLab directory..."
cp on-login.sh /opt/hivelab/
chmod +x /opt/hivelab/on-login.sh

# Modify SSH configuration to use on-login.sh
print_status "Modifying SSH configuration..."
sudo tee -a /etc/ssh/sshd_config > /dev/null <<EOT

# HiveLab configuration
ForceCommand /opt/hivelab/on-login.sh
EOT

# Restart SSH service
print_status "Restarting SSH service..."
sudo systemctl restart sshd

# Create a script to manage containers
cat > /opt/hivelab/manage_container.sh <<EOT
#!/bin/bash

USERNAME=\$1
ACTION=\$2

CONTAINER_NAME="hivelab-\${USERNAME}"
DEVCONTAINER_JSON_PATH="/opt/hivelab/devcontainer.json"

case \$ACTION in
  start)
    if ! docker ps -a --format '{{.Names}}' | grep -q "^\${CONTAINER_NAME}\$"; then
      # Create user's workspace directory if it doesn't exist
      mkdir -p /home/\${USERNAME}/workspace
      
      # Create the container
      docker run -d --name \${CONTAINER_NAME} \
        -v /home/\${USERNAME}/workspace:/home/vscode/workspace \
        -v /var/run/docker.sock:/var/run/docker.sock \
        -v \${DEVCONTAINER_JSON_PATH}:/home/vscode/.devcontainer/devcontainer.json \
        --cap-add=SYS_PTRACE --security-opt seccomp=unconfined \
        mcr.microsoft.com/vscode/devcontainers/universal:latest \
        sleep infinity
      
      # Set up the container
      docker exec \${CONTAINER_NAME} bash -c "
        set -e
        sudo chown vscode:vscode /home/vscode/workspace
        wget -O- https://raw.githubusercontent.com/cloudfoundry/bosh-cli/master/ci/docker/install-bosh.sh | sudo bash
      "
    elif ! docker ps --format '{{.Names}}' | grep -q "^\${CONTAINER_NAME}\$"; then
      docker start \${CONTAINER_NAME}
    fi
    ;;
  stop)
    docker stop \${CONTAINER_NAME}
    ;;
  remove)
    docker rm -f \${CONTAINER_NAME}
    ;;
esac
EOT

chmod +x /opt/hivelab/manage_container.sh

# Create a global devcontainer.json file
cat > /opt/hivelab/devcontainer.json <<EOT
{
    "name": "HiveLab Development Environment",
    "features": {
        "ghcr.io/devcontainers/features/docker-in-docker:2": {},
        "ghcr.io/devcontainers/features/kubectl-helm-minikube:1": {},
        "ghcr.io/devcontainers/features/github-cli:1": {}
    },
    "extensions": [
        "ms-azuretools.vscode-docker",
        "ms-kubernetes-tools.vscode-kubernetes-tools",
        "redhat.vscode-yaml"
    ],
    "settings": {
        "terminal.integrated.shell.linux": "/bin/bash"
    },
    "remoteUser": "vscode"
}
EOT

print_status "HiveLab configuration complete!"
print_status "Each user will get their own isolated devcontainer when they log in."
print_status "You may need to log out and log back in for group changes to take effect."
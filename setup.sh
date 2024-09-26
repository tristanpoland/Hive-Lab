#!/bin/bash

set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print status messages
print_status() {
    echo -e "${GREEN}[*] $1${NC}"
}

# Function to print warnings
print_warning() {
    echo -e "${YELLOW}[!] $1${NC}"
}

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check and set correct architecture
check_and_set_arch() {
    ARCH=$(dpkg --print-architecture)
    case $ARCH in
        amd64|arm64)
            print_status "Architecture $ARCH is supported."
            ;;
        *)
            print_status "Unsupported architecture: $ARCH. This script is designed for amd64 or arm64."
            exit 1
            ;;
    esac
}

# Update package lists and upgrade existing packages
update_and_upgrade() {
    print_status "Updating package lists and upgrading existing packages..."
    sudo apt-get update || print_warning "Some repositories may be temporarily unavailable. Continuing anyway..."
    sudo apt-get upgrade -y || print_warning "Some packages couldn't be upgraded. Continuing anyway..."
}

# Install necessary packages
install_packages() {
    print_status "Installing necessary packages..."
    sudo apt-get install -y jq docker.io || print_warning "Some packages couldn't be installed. Continuing anyway..."
}

# Set up Docker permissions
setup_docker_permissions() {
    print_status "Setting up Docker permissions..."
    sudo usermod -aG docker $USER
}

# Create HiveLab directory
create_hivelab_directory() {
    print_status "Creating HiveLab directory..."
    sudo mkdir -p /opt/hivelab
    sudo chown $USER:$USER /opt/hivelab
}

# Create on-login script
create_on_login_script() {
    print_status "Creating on-login script..."
    cat > /opt/hivelab/on-login.sh <<EOT
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
    echo "Failed to start or find your HiveLab container."
    echo "Dropping to a regular shell. You can troubleshoot from here."
    exec /bin/bash  # Drop to a shell if the container cannot be started
fi

# Use exec to start an interactive Bash session in the user's container
echo "Accessing your HiveLab container..."
exec docker exec -it -e TERM=\$TERM -e LANG=\$LANG -u vscode \$CONTAINER_ID /bin/bash
EOT
    chmod +x /opt/hivelab/on-login.sh
}

# Modify SSH configuration
modify_ssh_config() {
    print_status "Modifying SSH configuration..."
    sudo tee -a /etc/ssh/sshd_config > /dev/null <<EOT

# HiveLab configuration
Match User *,!root
    ForceCommand /opt/hivelab/on-login.sh
EOT
}

# Restart SSH service
restart_ssh_service() {
    print_status "Restarting SSH service..."
    if systemctl is-active --quiet ssh.service; then
        sudo systemctl restart ssh.service
    elif systemctl is-active --quiet sshd.service; then
        sudo systemctl restart sshd.service
    else
        print_warning "SSH service not found. Please ensure SSH is installed and configured."
    fi
}

# Create container management script
create_container_management_script() {
    print_status "Creating container management script..."
    cat > /opt/hivelab/manage_container.sh <<EOT
#!/bin/bash

USERNAME=\$1
ACTION=\$2

CONTAINER_NAME="hivelab-\${USERNAME}"
IMAGE_NAME="ubuntu:latest"

case \$ACTION in
  start)
    if ! docker ps -a --format '{{.Names}}' | grep -q "^\${CONTAINER_NAME}\$"; then
      # Create user's workspace directory if it doesn't exist
      mkdir -p /home/\${USERNAME}/workspace
      
      # Create the container
      docker run -d --name \${CONTAINER_NAME} \
        -v /home/\${USERNAME}/workspace:/home/workspace \
        -v /var/run/docker.sock:/var/run/docker.sock \
        --cap-add=SYS_PTRACE --security-opt seccomp=unconfined \
        \${IMAGE_NAME} sleep infinity
      
      # Set up the container
      docker exec \${CONTAINER_NAME} bash -c "
        apt-get update || true
        apt-get install -y sudo curl wget || true
        useradd -ms /bin/bash vscode
        echo 'vscode ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers
        chown -R vscode:vscode /home/workspace
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
}

# Main execution
main() {
    check_and_set_arch
    update_and_upgrade
    install_packages
    setup_docker_permissions
    create_hivelab_directory
    create_on_login_script
    modify_ssh_config
    create_container_management_script
    restart_ssh_service

    print_status "HiveLab setup complete!"
    print_status "To access HiveLab, simply use: ssh user@host"
    print_status "To bypass HiveLab and get a regular shell, use: ssh user@host bypass"
    print_status "You may need to log out and log back in for group changes to take effect."
}

# Run main function
main

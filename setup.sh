#!/bin/bash

set -e

# Colors for output
GREEN='\033[0;32m'
NC='\033[0m' # No Color

# Function to print status messages
print_status() {
    echo -e "${GREEN}[*] $1${NC}"
}

# Update and install dependencies
print_status "Updating system and installing dependencies..."
sudo apt-get update
sudo apt-get install -y apt-transport-https ca-certificates curl software-properties-common

# Install Docker
print_status "Installing Docker..."
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER

# Install Kubernetes tools
print_status "Installing Kubernetes tools..."
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
echo "deb https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee -a /etc/apt/sources.list.d/kubernetes.list
sudo apt-get update
sudo apt-get install -y kubectl

# Install Minikube for local development
print_status "Installing Minikube..."
curl -Lo minikube https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
chmod +x minikube
sudo mv minikube /usr/local/bin/

# Install Helm
print_status "Installing Helm..."
curl https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 | bash

# Install BOSH CLI
print_status "Installing BOSH CLI..."
wget -O bosh https://github.com/cloudfoundry/bosh-cli/releases/download/v6.4.1/bosh-cli-6.4.1-linux-amd64
chmod +x bosh
sudo mv bosh /usr/local/bin/

# Set up Minikube cluster
print_status "Setting up Minikube cluster..."
minikube start --driver=docker

# Install Ingress controller
print_status "Installing Ingress controller..."
minikube addons enable ingress

# Install Redis for state management
print_status "Installing Redis..."
helm repo add bitnami https://charts.bitnami.com/bitnami
helm install redis bitnami/redis --set auth.enabled=false

# Set up monitoring tools
print_status "Setting up Netdata for monitoring..."
helm repo add netdata https://netdata.github.io/helmchart/
helm install netdata netdata/netdata --set image.tag=latest

# Build and push the devcontainer image
print_status "Building devcontainer image..."
docker build -t boshpod-devcontainer:latest .
docker push yourdockerrepo/boshpod-devcontainer:latest

# Deploy Hive Lab components
print_status "Deploying BOSHPod components..."
kubectl apply -f kubernetes/

# Print final instructions
print_status "Hive Lab setup complete!"
echo "Next steps:"
echo "1. Configure your DNS to point to the Minikube IP: $(minikube ip)"
echo "2. Set up your CI/CD pipeline"
echo "3. Customize the Hive Lab components in the kubernetes/ directory"
echo "4. Start developing and testing your Hive Lab system"

print_status "Remember to log out and log back in for Docker permissions to take effect."
# HiveLab: A Lightweight Easy to Deploy Lab Environment 🐝🔬

## Table of Contents
1. [📘 Introduction](#introduction)
2. [💻 System Requirements](#system-requirements)
3. [🚀 Installation](#installation)
4. [🧩 Components](#components)
5. [🔧 Usage](#usage)
6. [🛡️ Security Considerations](#security-considerations)
7. [🐞 Troubleshooting](#troubleshooting)
8. [🎨 Customization](#customization)

## 1. Introduction 📘

HiveLab is an easy-to-deploy lab system that provides isolated environments for users on a shared host. It uses Docker containers to create separate workspaces for each user, allowing them to work in their own environment without affecting others or the host system.

![image](https://github.com/user-attachments/assets/f121d68d-c7fd-4516-a93d-21880e50a930)

## 2. System Requirements 💻

- Ubuntu-based Linux distribution (tested on Ubuntu 20.04 LTS and newer)
- Supported architectures: amd64 or arm64
- Sudo privileges for installation
- SSH server installed and running
- Internet connection for package downloads

## 3. Installation 🚀

1. Download the installation script to your server.
2. Make the script executable: `chmod +x install_hivelab.sh`
3. Run the script with sudo privileges: `sudo ./install_hivelab.sh`
4. The script will automatically:
   - Update and upgrade system packages
   - Install necessary dependencies (jq, docker.io)
   - Set up Docker permissions
   - Create required directories and scripts
   - Modify SSH configuration
   - Restart the SSH service

After installation, you may need to log out and log back in for group changes to take effect.

## 4. Components 🧩

HiveLab consists of several components:

1. **on-login.sh**: This script runs when a user logs in via SSH. It starts or ensures the user's container is running and then executes an interactive bash session inside the container.

2. **manage_container.sh**: This script manages user containers (start, stop, remove).

3. **Docker containers**: Each user gets their own Docker container based on the Ubuntu image.

4. **Modified SSH configuration**: Forces the execution of the on-login script for non-root users.

## 5. Usage 🔧

### For Users 👤

- To access HiveLab: `ssh user@host`
- To bypass HiveLab and get a regular shell: `ssh user@host bypass`

![image](https://github.com/user-attachments/assets/efe583b1-1f1f-4576-a54a-7167cc7603be)

### For Administrators 👨‍💼

- To manage a user's container:
  ```
  /opt/hivelab/manage_container.sh username [start|stop|remove]
  ```

## 6. Security Considerations 🛡️

- Each user is isolated in their own container.
- Users have sudo access within their containers but not on the host system.
- The Docker socket is mounted in user containers, which could be a potential security risk if users are not trusted.

## 7. Troubleshooting 🐞

- If a user can't access their container, ensure the Docker service is running: `sudo systemctl status docker`
- Check container status: `docker ps -a`
- Review logs: `docker logs hivelab-username`

## 8. Customization 🎨

To customize the user environment:

1. Modify the `manage_container.sh` script to add additional setup steps or install more packages.
2. Change the base image in `manage_container.sh` from `ubuntu:latest` to a custom image with pre-installed tools.
3. Adjust resource limits by adding Docker run options in `manage_container.sh`.

Remember to test thoroughly after making any changes.

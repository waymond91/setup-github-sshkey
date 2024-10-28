#!/bin/bash

# Ensure the script is not run as root
if [ "$EUID" -eq 0 ]; then
    echo "Please run this script as a regular user, not as root."
    exit 1
fi

# Check if a repository URL is provided as an argument
if [ -z "$1" ]; then
    echo "Usage: $0 <GitHub repository URL (SSH format)>"
    exit 1
fi

REPO_URL="$1"

# Install git, Python, and UUID generation tool
sudo apt update
sudo apt install -y git python3 python3-pip uuid-runtime

# Generate a new UUID for the GitHub key
UUID_SUFFIX=$(uuidgen | cut -c1-4)

# Get the current hostname
DEVICE_NAME=$(hostname)

# Generate a new GitHub-specific SSH key
GITHUB_KEY_PATH="$HOME/.ssh/github_ed25519_${UUID_SUFFIX}"
echo "Generating a new SSH key for GitHub..."
ssh-keygen -t ed25519 -f "$GITHUB_KEY_PATH" -N "" -C "${DEVICE_NAME}-${UUID_SUFFIX}-github"
echo "GitHub-specific SSH key generated."

# Show the user the public key and format it for deploy keys
echo -e "\nAdd the following SSH key as a deploy key to your GitHub repository:"
echo "Title: ${DEVICE_NAME}-${UUID_SUFFIX}-github"
echo "Key:"
cat "$GITHUB_KEY_PATH.pub"
echo ""
read -p "Press Enter after adding the SSH key to continue..."

# Configure SSH to use this key for GitHub connections
SSH_CONFIG="$HOME/.ssh/config"
if ! grep -q "Host github.com-${UUID_SUFFIX}" "$SSH_CONFIG"; then
    echo "Configuring SSH to use the new GitHub-specific key..."
    echo -e "\nHost github.com-${UUID_SUFFIX}\n  HostName github.com\n  IdentityFile $GITHUB_KEY_PATH\n  User git" | tee -a "$SSH_CONFIG" > /dev/null
    echo "SSH configuration for GitHub set up."
else
    echo "SSH configuration for this GitHub key already exists."
fi

# Clone the repository using the new key
GIT_SSH_COMMAND="ssh -i $GITHUB_KEY_PATH" git clone "$REPO_URL"
echo "Repository cloned successfully."

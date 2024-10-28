#!/bin/bash

# Ensure the script is not run as root
if [ "$EUID" -eq 0 ]; then
    echo "Please run this script as a regular user, not as root."
    exit 1
fi

# Install git, Python, and UUID generation tool
sudo apt update
sudo apt install -y git python3 python3-pip uuid-runtime

# Generate a short UUID for device identification
UUID_SUFFIX=$(uuidgen | cut -c1-4)

# Get the current hostname
DEVICE_NAME=$(hostname)

# Generate a GitHub-specific SSH key if not already present
GITHUB_KEY_PATH="$HOME/.ssh/github_ed25519"
if [ ! -f "$GITHUB_KEY_PATH" ]; then
    echo "Generating a new SSH key for GitHub..."
    ssh-keygen -t ed25519 -f "$GITHUB_KEY_PATH" -N "" -C "${DEVICE_NAME}-${UUID_SUFFIX}-github"
    echo "GitHub-specific SSH key generated."

    # Show the user the public key and format it for deploy keys
    echo -e "\nAdd the following SSH key as a deploy key to your GitHub repository:"
    echo "Title: ${DEVICE_NAME}-${UUID_SUFFIX}-github"
    echo "Key:"
    cat "$GITHUB_KEY_PATH.pub"
    echo ""
    echo "Please add the SSH key to GitHub and press Enter to continue..."
    read -r
else
    echo "GitHub-specific SSH key already exists at $GITHUB_KEY_PATH."
    echo "If you need to add this key to GitHub, use the following command to display it:"
    echo "cat $GITHUB_KEY_PATH.pub"
fi

# Configure SSH to use this key for GitHub connections
SSH_CONFIG="$HOME/.ssh/config"
if ! grep -q "Host github.com" "$SSH_CONFIG"; then
    echo "Configuring SSH to use the GitHub-specific key..."
    echo -e "\nHost github.com\n  HostName github.com\n  IdentityFile $GITHUB_KEY_PATH\n  User git" | tee -a "$SSH_CONFIG" > /dev/null
    echo "SSH configuration for GitHub set up."
else
    echo "SSH configuration for GitHub already exists."
fi

# Ask user to enter GitHub repository URL
if [ -t 0 ]; then
    # If running in an interactive terminal
    read -p "Enter the GitHub repository URL (SSH format): " REPO_URL
else
    # If running non-interactively, use default or exit
    REPO_URL=""
    echo "Script is running non-interactively. Please provide the GitHub repository URL."
    exit 1
fi

# Clone the repository using the new key
if [ -n "$REPO_URL" ]; then
    GIT_SSH_COMMAND="ssh -i $GITHUB_KEY_PATH" git clone "$REPO_URL"
    echo "Repository cloned successfully."
else
    echo "No repository URL provided. Exiting..."
    exit 1
fi

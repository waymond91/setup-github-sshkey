#!/bin/bash

# Ensure the script is not run as root
if [ "$EUID" -eq 0 ]; then
    echo "Please run this script as a regular user, not as root."
    exit 1
fi

# Check if a repository URL is provided as an argument
if [ -z "$1" ]; then
    echo "Usage: $0 <Git repository URL (SSH format)>"
    exit 1
fi

REPO_URL="$1"

# Extract the repository name from the URL
REPO_NAME=$(basename -s .git "$REPO_URL")

# Install git, Python, and UUID generation tool
sudo apt update
sudo apt install -y git python3 python3-pip uuid-runtime

# Generate a new UUID for the SSH key
UUID_SUFFIX=$(uuidgen | cut -c1-4)

# Get the current hostname
DEVICE_NAME=$(hostname)

# Generate a new SSH key for Git, using the repo name
GIT_KEY_PATH="$HOME/.ssh/${REPO_NAME}_ed25519_${UUID_SUFFIX}"
echo "Generating a new SSH key for Git..."
ssh-keygen -t ed25519 -f "$GIT_KEY_PATH" -N "" -C "${DEVICE_NAME}-${REPO_NAME}-${UUID_SUFFIX}"
echo "Git-specific SSH key generated for repository: $REPO_NAME"

# Show the user the public key and format it for deploy keys
echo -e "\nAdd the following SSH key as a deploy key to your Git repository:"
echo "Title: ${DEVICE_NAME}-${REPO_NAME}-${UUID_SUFFIX}"
echo "Key:"
cat "$GIT_KEY_PATH.pub"
echo ""
read -p "Press Enter after adding the SSH key to continue..."

# Extract the domain from the repository URL
GIT_DOMAIN=$(echo "$REPO_URL" | awk -F'[/:]' '{print $4}')

# Configure SSH to use this key for the Git host
SSH_CONFIG="$HOME/.ssh/config"
if ! grep -q "Host $GIT_DOMAIN-${UUID_SUFFIX}" "$SSH_CONFIG"; then
    echo "Configuring SSH to use the new Git-specific key..."
    echo -e "\nHost $GIT_DOMAIN-${UUID_SUFFIX}\n  HostName $GIT_DOMAIN\n  IdentityFile $GIT_KEY_PATH\n  User git" | tee -a "$SSH_CONFIG" > /dev/null
    echo "SSH configuration for Git set up."
else
    echo "SSH configuration for this Git key already exists."
fi

# Check if the directory already exists
if [ -d "$REPO_NAME" ]; then
    echo "Directory '$REPO_NAME' already exists."
    read -p "Do you want to (D)elete the directory, (S)kip cloning, or (E)xit? [D/S/E]: " USER_CHOICE
    case "$USER_CHOICE" in
        [Dd]* )
            echo "Deleting the existing directory '$REPO_NAME'..."
            rm -rf "$REPO_NAME"
            ;;
        [Ss]* )
            echo "Skipping cloning. You can manually pull changes inside the existing directory."
            exit 0
            ;;
        [Ee]* )
            echo "Exiting without making changes."
            exit 0
            ;;
        * )
            echo "Invalid choice. Exiting."
            exit 1
            ;;
    esac
fi

# Attempt to clone the repository using the new key
echo "Cloning repository: $REPO_URL..."
GIT_SSH_COMMAND="ssh -i $GIT_KEY_PATH" git clone "$REPO_URL"

# Check if the clone was successful
if [ $? -eq 0 ]; then
    echo "Repository cloned successfully."
else
    echo "Failed to clone the repository. Please check the SSH key and repository URL."
    exit 1
fi

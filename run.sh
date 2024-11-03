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

# Detect the platform (GitHub or GitLab) based on the URL
if [[ "$REPO_URL" == *"github.com"* ]]; then
    HOSTNAME="github.com"
    PLATFORM="GitHub"
    INSTRUCTIONS="Go to your repository on GitHub, navigate to Settings > Deploy keys, click on 'Add deploy key,' and paste the SSH key below. Check 'Allow write access' if needed."
elif [[ "$REPO_URL" == *"gitlab.com"* ]]; then
    HOSTNAME="gitlab.com"
    PLATFORM="GitLab"
    INSTRUCTIONS="Go to your repository on GitLab, navigate to Settings > Repository > Deploy Keys, click on 'New deploy key,' and paste the SSH key below. Check 'Write access' if needed."
else
    echo "Unsupported Git platform. Please provide a GitHub or GitLab repository URL."
    exit 1
fi

# Extract the repository name from the URL
REPO_NAME=$(basename -s .git "$REPO_URL")

# Install required packages
sudo apt update
sudo apt install -y git python3 python3-pip uuid-runtime wget

# Generate a new UUID for the SSH key
UUID_SUFFIX=$(uuidgen | cut -c1-4)

# Get the current hostname
DEVICE_NAME=$(hostname)

# Generate a new SSH key for Git
GIT_KEY_PATH="$HOME/.ssh/${REPO_NAME}_ed25519_${UUID_SUFFIX}"
echo "Generating a new SSH key for $REPO_NAME..."
ssh-keygen -t ed25519 -f "$GIT_KEY_PATH" -N "" -C "${DEVICE_NAME}-${REPO_NAME}-${UUID_SUFFIX}"
echo "Git-specific SSH key generated for repository: $REPO_NAME"

# Apply terminal formatting
BOLD=$(tput bold)
NORMAL=$(tput sgr0)
BLUE=$(tput setaf 4)
GREEN=$(tput setaf 2)
YELLOW=$(tput setaf 3)

# Show the user the public key and format it for deploy keys
TITLE="${DEVICE_NAME}-${REPO_NAME}-${UUID_SUFFIX}"

echo -e "\n${BOLD}${GREEN}===================================================="
echo -e "    ADD THIS SSH KEY AS A DEPLOY KEY TO YOUR REPO"
echo -e "====================================================${NORMAL}"
echo -e "${BOLD}${YELLOW}Title:${NORMAL} ${BLUE}$TITLE${NORMAL}"
echo -e "${BOLD}${YELLOW}Key:${NORMAL}"
echo -e "${BLUE}"
cat "$GIT_KEY_PATH.pub"
echo -e "${NORMAL}"
echo -e "${BOLD}${GREEN}====================================================${NORMAL}"
echo -e "${BOLD}${YELLOW}Platform-specific Instructions for $PLATFORM:${NORMAL}"
echo -e "${INSTRUCTIONS}"
echo -e "${BOLD}${GREEN}====================================================${NORMAL}"

# Wait for user confirmation before proceeding
echo -e "\n${BOLD}${YELLOW}IMPORTANT:${NORMAL} Please add the SSH key above to your $PLATFORM repository as a deploy key."
read -p "Press Enter after you have added the key to proceed..."

# Configure SSH to use this key for Git
SSH_CONFIG="$HOME/.ssh/config"
if ! grep -q "Host $REPO_NAME" "$SSH_CONFIG"; then
    echo "Configuring SSH to use the new Git-specific key..."
    echo -e "\nHost $REPO_NAME\n  HostName $HOSTNAME\n  IdentityFile $GIT_KEY_PATH\n  User git" | tee -a "$SSH_CONFIG" > /dev/null
fi

# Clone the repository using the new key
echo "Cloning repository: $REPO_URL..."
GIT_SSH_COMMAND="ssh -i $GIT_KEY_PATH" git clone "$REPO_URL"

# Check if the clone was successful
if [ $? -eq 0 ]; then
    echo -e "${BOLD}${GREEN}Repository cloned successfully.${NORMAL}"
else
    echo -e "${BOLD}${RED}Failed to clone the repository. Please check the SSH key and repository URL.${NORMAL}"
    exit 1
fi

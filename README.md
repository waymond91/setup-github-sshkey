# Pi GitHub Setup Script

This repository contains a Bash script designed to set up a Raspberry Pi for GitHub access. It generates a GitHub-specific SSH key, configures SSH for GitHub connections, and allows easy cloning of GitHub repositories.

## Features

- Generates an SSH key dedicated for GitHub access.
- Configures SSH to use the new key for GitHub connections.
- Prompts the user to add the SSH key as a deploy key on GitHub.
- Supports cloning GitHub repositories using the generated key.

### Prerequisites

- A Raspberry Pi with an internet connection.
- Git, Python3, and UUID generation tools are required (automatically installed by the script).

### Run Remotely

1. Run on your local machine:
```bash
curl -sL bit.ly/4hlyaKu | bash -s git@github.com:<username>/<repository>.git
```

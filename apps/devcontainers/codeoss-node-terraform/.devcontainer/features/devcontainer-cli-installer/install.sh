#!/bin/bash
set -e

VERSION="${VERSION:-"latest"}"

echo "Installing @devcontainers/cli@${VERSION}..."

# Load NVM if available (should be in /etc/bash.bashrc from node feature)
if [ -f /etc/bash.bashrc ]; then
    echo "Sourcing /etc/bash.bashrc to load NVM..."
    . /etc/bash.bashrc
fi

# Ensure npm is available
if ! type npm > /dev/null 2>&1; then
    echo "ERROR: npm is required to install devcontainer CLI. Make sure node feature is installed and loaded."
    echo "PATH is: $PATH"
    exit 1
fi

echo "Using npm from: $(which npm)"
echo "Node version: $(node --version)"
echo "Npm version: $(npm --version)"

npm install -g @devcontainers/cli@${VERSION}

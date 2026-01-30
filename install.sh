#!/usr/bin/env bash

# install.sh - Installer for 'in' CLI

set -e

REPO_URL="https://raw.githubusercontent.com/inevolin/in-cli/main/in.sh"
# ideally this would point to the real repo, but for local usage:
SOURCE_FILE="./in.sh"
DEST_DIR="/usr/local/bin"
DEST_FILE="$DEST_DIR/in"

echo "Installing 'in' to $DEST_FILE..."

# Check if we are running in the repo or downloading
if [ -f "in.sh" ]; then
    cp in.sh "$DEST_FILE.tmp"
else
    echo "Downloading from $REPO_URL..."
    curl -sL "$REPO_URL" -o "$DEST_FILE.tmp"
fi

chmod +x "$DEST_FILE.tmp"

# Move with sudo if needed
if [ -w "$DEST_DIR" ]; then
    mv "$DEST_FILE.tmp" "$DEST_FILE"
else
    echo "Sudo permissions required to install to $DEST_DIR"
    sudo mv "$DEST_FILE.tmp" "$DEST_FILE"
fi

echo "Successfully installed 'in'!"
echo "Try it out: in --help"

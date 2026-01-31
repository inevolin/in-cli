#!/usr/bin/env bash

################################################################################
# install.sh - Installer for 'in' CLI tool
#
# Purpose:
#   Installs the 'in' command to a suitable directory in your PATH.
#   Can be run locally from the repository or via curl pipe to bash.
#
# Usage:
#   Local:  ./install.sh
#   Remote: curl -sL https://raw.githubusercontent.com/inevolin/in-cli/main/install.sh | bash
#
# What it does:
#   1. Finds a suitable installation directory (checks /usr/local/bin, ~/.local/bin, etc.)
#   2. Creates the directory if it doesn't exist
#   3. Downloads or copies in.sh from the repository
#   4. Makes it executable and installs to chosen directory (may require sudo)
#   5. Warns if the installation directory is not in PATH
################################################################################

set -e  # Exit on any error

REPO_URL="https://raw.githubusercontent.com/inevolin/in-cli/main/in.sh"
SOURCE_FILE="./in.sh"

# Candidate installation directories (in order of preference)
CANDIDATE_DIRS=(
    "/usr/local/bin"   # Common on macOS and Linux
    "$HOME/.local/bin" # User-specific, no sudo needed
    "$HOME/bin"        # Older user convention
    "/usr/bin"         # System directory (usually requires sudo)
)

# Find the best installation directory
DEST_DIR=""
for dir in "${CANDIDATE_DIRS[@]}"; do
    # Check if directory exists or can be created
    if [ -d "$dir" ]; then
        DEST_DIR="$dir"
        break
    elif [ "$dir" = "$HOME/.local/bin" ] || [ "$dir" = "$HOME/bin" ]; then
        # User directories - can create without sudo
        echo "Creating directory: $dir"
        mkdir -p "$dir"
        DEST_DIR="$dir"
        break
    fi
done

# If no suitable directory found, default to /usr/local/bin and create it
if [ -z "$DEST_DIR" ]; then
    DEST_DIR="/usr/local/bin"
    if [ ! -d "$DEST_DIR" ]; then
        echo "Creating directory: $DEST_DIR (may require sudo)"
        if sudo mkdir -p "$DEST_DIR" 2>/dev/null; then
            echo "Directory created successfully"
        else
            echo "Error: Could not create $DEST_DIR"
            exit 1
        fi
    fi
fi

DEST_FILE="$DEST_DIR/in"
TMP_FILE=$(mktemp 2>/dev/null || echo "/tmp/in.$$.tmp")

echo "Installing 'in' to $DEST_FILE..."

# Download or copy the script
if [ -f "in.sh" ]; then
    cp in.sh "$TMP_FILE"
else
    echo "Downloading from $REPO_URL..."
    curl -sL "$REPO_URL" -o "$TMP_FILE"
fi

chmod +x "$TMP_FILE"

# Install to destination (with sudo if needed)
if [ -w "$DEST_DIR" ]; then
    mv "$TMP_FILE" "$DEST_FILE"
else
    echo "Sudo permissions required to install to $DEST_DIR"
    sudo mv "$TMP_FILE" "$DEST_FILE"
fi

echo "Successfully installed 'in' to $DEST_FILE!"

# Check if the install directory is in PATH
if ! echo "$PATH" | grep -q "$DEST_DIR"; then
    echo ""
    echo "⚠️  Warning: $DEST_DIR is not in your PATH"
    echo "To make 'in' accessible, follow these steps:"
    echo "1. Add this line to your shell configuration (~/.bashrc, ~/.zshrc, etc.):"
    echo "   export PATH=\"$DEST_DIR:\$PATH\""
    echo "2. Restart your shell or run:"
    echo "   source ~/.bashrc  # or ~/.zshrc"
fi

echo ""
echo "Try it out: in --help"

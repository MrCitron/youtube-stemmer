#!/bin/bash

# Simple installation script for YouTube Stemmer Linux Desktop Entry

# Get absolute path of this directory
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
EXE_PATH="$DIR/youtube_stemmer"
ICON_PATH="$DIR/data/flutter_assets/assets/icon.png"

# Check if desktop file template exists
if [ ! -f "$DIR/youtube_stemmer.desktop.template" ]; then
    echo "Error: youtube_stemmer.desktop.template not found in $DIR"
    exit 1
fi

# Create user-specific applications directory if it doesn't exist
mkdir -p ~/.local/share/applications

# Generate the actual .desktop file from the template
sed -e "s|EXEC_PATH|$EXE_PATH|g" \
    -e "s|ICON_PATH|$ICON_PATH|g" \
    "$DIR/youtube_stemmer.desktop.template" > ~/.local/share/applications/youtube_stemmer.desktop

# Update the desktop database
if command -v update-desktop-database >/dev/null 2>&1; then
    update-desktop-database ~/.local/share/applications/
fi

echo "Installation complete!"
echo "YouTube Stemmer has been added to your application menu."
echo "You can now launch it using your system's launcher."

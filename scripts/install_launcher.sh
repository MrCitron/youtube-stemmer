#!/bin/bash

# Improved installation script for YouTube Stemmer Linux

# Get absolute path of this directory
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
EXE_PATH="$DIR/youtube_stemmer"
SOURCE_ICON="$DIR/data/flutter_assets/assets/icon.png"

# 1. Install Icon to local icons directory (Standard Linux approach)
ICON_DIR=~/.local/share/icons/hicolor
mkdir -p "$ICON_DIR/128x128/apps"
cp "$SOURCE_ICON" "$ICON_DIR/128x128/apps/youtube_stemmer.png"

# Ensure index.theme exists for valid cache generation
if [ ! -f "$ICON_DIR/index.theme" ]; then
    cat > "$ICON_DIR/index.theme" <<EOF
[Icon Theme]
Name=Hicolor
Comment=Fallback icon theme
Hidden=true
Directories=128x128/apps

[128x128/apps]
Size=128
Context=Applications
Type=Threshold
EOF
fi

# 2. Generate the .desktop file from the template
DESKTOP_FILE=~/.local/share/applications/youtube_stemmer.desktop
mkdir -p ~/.local/share/applications

if [ -f "$DIR/youtube_stemmer.desktop.template" ]; then
    sed -e "s|EXEC_PATH|$EXE_PATH|g" \
        "$DIR/youtube_stemmer.desktop.template" > "$DESKTOP_FILE"
else
    echo "Error: youtube_stemmer.desktop.template not found in $DIR"
    exit 1
fi

# 3. Update databases
if command -v update-desktop-database >/dev/null 2>&1; then
    update-desktop-database ~/.local/share/applications/
fi

if command -v gtk-update-icon-cache >/dev/null 2>&1; then
    gtk-update-icon-cache -f -t ~/.local/share/icons/hicolor >/dev/null 2>&1
fi

echo "Installation complete!"
echo "YouTube Stemmer has been added to your application menu with the new icon."

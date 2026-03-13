#!/bin/bash

# Uninstall script for YouTube Stemmer Linux Desktop Entry

DESKTOP_FILE=~/.local/share/applications/youtube_stemmer.desktop

if [ -f "$DESKTOP_FILE" ]; then
    rm "$DESKTOP_FILE"
    echo "Removed desktop entry: $DESKTOP_FILE"
fi

# Remove installed icon
INSTALLED_ICON=~/.local/share/icons/hicolor/128x128/apps/youtube_stemmer.png
if [ -f "$INSTALLED_ICON" ]; then
    rm "$INSTALLED_ICON"
    echo "Removed installed icon: $INSTALLED_ICON"
fi

# Update databases
if command -v update-desktop-database >/dev/null 2>&1; then
    update-desktop-database ~/.local/share/applications/
fi

if command -v gtk-update-icon-cache >/dev/null 2>&1; then
    gtk-update-icon-cache -f -t ~/.local/share/icons/hicolor >/dev/null 2>&1
fi

# Ask to remove local data
read -p "Do you also want to remove local settings, history database, and downloaded AI models? (y/N) " confirm
if [[ "$confirm" =~ ^[Yy]$ ]]; then
    # Standard Flutter/AppSupport paths for Linux
    DATA_DIR=~/.local/share/com.metinosman.youtubestemmer
    CONFIG_DIR=~/.config/com.metinosman.youtubestemmer
    
    if [ -d "$DATA_DIR" ]; then
        rm -rf "$DATA_DIR"
        echo "Removed local data directory: $DATA_DIR"
    fi
    
    if [ -d "$CONFIG_DIR" ]; then
        rm -rf "$CONFIG_DIR"
        echo "Removed configuration directory: $CONFIG_DIR"
    fi
    
    echo "Local data cleared."
else
    echo "Local data preserved."
fi

echo "Uninstallation complete!"

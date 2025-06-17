#!/bin/bash

set -e

echo "🧹 Cleaning up AD password change integration..."

# === 1. Remove the password change script ===
SCRIPT_PATH="/usr/local/bin/change-ad-password.sh"
if [ -f "$SCRIPT_PATH" ]; then
    sudo rm -f "$SCRIPT_PATH"
    echo "✔ Removed: $SCRIPT_PATH"
fi

# === 2. Remove the .desktop launcher ===
DESKTOP_ENTRY="/usr/share/applications/change-ad-password.desktop"
if [ -f "$DESKTOP_ENTRY" ]; then
    sudo rm -f "$DESKTOP_ENTRY"
    echo "✔ Removed: $DESKTOP_ENTRY"
fi

# === 3. Remove dconf system-wide shortcut config ===
DCONF_FILE="/etc/dconf/db/local.d/00-custom-shortcuts"
LOCK_FILE="/etc/dconf/db/local.d/locks/custom-shortcuts"

if [ -f "$DCONF_FILE" ]; then
    sudo rm -f "$DCONF_FILE"
    echo "✔ Removed: $DCONF_FILE"
fi

if [ -f "$LOCK_FILE" ]; then
    sudo rm -f "$LOCK_FILE"
    echo "✔ Removed: $LOCK_FILE"
fi

# === 4. Refresh dconf database ===
echo "🔄 Updating dconf database..."
sudo dconf update

echo "✅ Cleanup complete. Please reboot or log out and back in to apply changes."

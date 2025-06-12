#!/bin/bash

# Variables
GROUP_NAME="ubuntu-group"
SCRIPT_PATH="/usr/local/bin/amk/mount-dfs.sh"
SUDOERS_FILE="/etc/sudoers"
BACKUP_FILE="/etc/sudoers.backup.$(date +%F_%T)"

# Step 1: Backup sudoers file
echo "Backing up $SUDOERS_FILE to $BACKUP_FILE"
sudo cp "$SUDOERS_FILE" "$BACKUP_FILE"

# Step 2: Temp file for safe sudoers edit
TEMP_FILE=$(mktemp)
sudo cp "$SUDOERS_FILE" "$TEMP_FILE"

# Step 3: Add rule if it doesn't exist
LINE="%$GROUP_NAME ALL=(ALL) NOPASSWD: $SCRIPT_PATH"
if ! grep -Fxq "$LINE" "$TEMP_FILE"; then
    echo "$LINE" | sudo tee -a "$TEMP_FILE" > /dev/null
    echo "Added sudoers rule for group $GROUP_NAME."
else
    echo "Rule already exists in sudoers."
fi

# Step 4: Validate and apply changes
if sudo visudo -c -f "$TEMP_FILE"; then
    echo "New sudoers file is valid. Applying changes."
    sudo cp "$TEMP_FILE" "$SUDOERS_FILE"
else
    echo "Error: New sudoers file is invalid. Changes not applied."
    exit 1
fi

# Cleanup
rm -f "$TEMP_FILE"

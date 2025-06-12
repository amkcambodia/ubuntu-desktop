#!/bin/bash

# Exit on error
set -e

## Install required packages
#echo "📦 Installing dependencies..."
#sudo apt update
#sudo apt install -y smbclient zenity

# ----------------------------------------------------------------------------------

# Run and install smbcred.sh
sudo mkdir -p /bin/amk
#sudo cp ./credentials/tasks/smbcred.sh /bin/amk/smbcred.sh
sudo cp ./credentials/beta/beta_credential3.sh /bin/amk/smbcred.sh
sudo chmod 755 /bin/amk/smbcred.sh
sudo chmod +x /bin/amk/smbcred.sh

# ----------------------------------------------------------------------------------

# Configure autostart for smbcred
AUTOSTART_FILE="/etc/xdg/autostart/smbcred.desktop"
echo "🚀 Setting up autostart for smbcred..."

# Backup existing autostart file if it exists
if [ -f "$AUTOSTART_FILE" ]; then
  echo "🗂️  Backing up existing $AUTOSTART_FILE..."
  sudo cp "$AUTOSTART_FILE" "$AUTOSTART_FILE.bk"
fi

# ----------------------------------------------------------------------------------

# Copy new autostart file
sudo cp ./credentials/tasks/autostart.sh "$AUTOSTART_FILE"
sudo chmod 755 "$AUTOSTART_FILE"
sudo chmod +x "$AUTOSTART_FILE"

# ----------------------------------------------------------------------------------

echo "✅ smbcred setup complete."

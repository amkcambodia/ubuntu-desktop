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

# Create change password script and shortcut key
echo "🔑 Setting up change password script and shortcut key..."

## Create the script to change the password
sudo cp ./credentials/template/ad-password-ctrl-alt-del-dark.sh /usr/lcoal/bin/amk/change_password.sh
sudo chmod 755 /usr/local/bin/amk/change_password.sh
sudo chmod +x /usr/local/bin/amk/change_password.sh


## Create the auto setup shortcut key
#sudo cp ./credentials/template/custom-shortcuts-ctrl-alt-del.sh /usr/lcoal/bin/amk/custom-shortcuts.sh
#sudo chmod 755 /usr/lcoal/bin/amk/custom-shortcuts.sh
#sudo chmod +x /usr/lcoal/bin/amk/custom-shortcuts.sh
#
## Create the auto run shortcut key script
#sudo cp ./credentials/template/custom-shortcut.desktop /etc/xdg/autostart/custom-shortcut.desktop
#sudo chmod 755 /etc/xdg/autostart/custom-shortcut.desktop
#sudo chmod +x /etc/xdg/autostart/custom-shortcut.desktop

sudo mkdir -p /etc/dconf/db/local.d
sudo vi  /etc/dconf/db/local.d/00-custom-shortcuts

[org/gnome/settings-daemon/plugins/media-keys]
custom-keybindings=['/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/']

[org/gnome/settings-daemon/plugins/media-keys/custom-keybinding:/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/]
name='AD Change Password'
command='/usr/local/bin/amk/change_password.sh'
binding='<Control><Alt>Delete'


sudo dconf update




# ----------------------------------------------------------------------------------

# Copy new autostart file
sudo cp ./credentials/tasks/autostart.sh "$AUTOSTART_FILE"
sudo chmod 755 "$AUTOSTART_FILE"
sudo chmod +x "$AUTOSTART_FILE"

# ----------------------------------------------------------------------------------

echo "✅ smbcred setup complete."

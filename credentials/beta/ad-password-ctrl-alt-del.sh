#!/bin/bash

set -e

# === 1. Create AD Password Change Script ===
SCRIPT_PATH="/usr/local/bin/change-ad-password.sh"

echo "Creating password change script at $SCRIPT_PATH..."
sudo tee "$SCRIPT_PATH" > /dev/null << 'EOF'
#!/bin/bash

USERNAME=$(logname)

CURRENT_PASS=$(zenity --password --title="AD Password Change" --text="Enter your current password:")
[ -z "$CURRENT_PASS" ] && exit 1

NEW_PASS=$(zenity --password --title="AD Password Change" --text="Enter your new password:")
[ -z "$NEW_PASS" ] && exit 1

CONFIRM_PASS=$(zenity --password --title="AD Password Change" --text="Confirm your new password:")
[ "$NEW_PASS" != "$CONFIRM_PASS" ] && { zenity --error --text="Passwords do not match."; exit 1; }

echo -e "$CURRENT_PASS\n$NEW_PASS\n$NEW_PASS" | kpasswd "$USERNAME"

if [ $? -eq 0 ]; then
    zenity --info --text="Password changed successfully."
else
    zenity --error --text="Password change failed."
fi
EOF

sudo chmod +x "$SCRIPT_PATH"

# === 2. Create Desktop Launcher ===
DESKTOP_ENTRY="/usr/share/applications/change-ad-password.desktop"
echo "Creating desktop entry at $DESKTOP_ENTRY..."

sudo tee "$DESKTOP_ENTRY" > /dev/null <<EOF
[Desktop Entry]
Name=Change AD Password
Exec=$SCRIPT_PATH
Icon=dialog-password
Terminal=false
Type=Application
Categories=Utility;
EOF

# === 3. Configure dconf System-wide Shortcut ===
DCONF_PATH="/etc/dconf/db/local.d"
LOCKS_PATH="/etc/dconf/db/local.d/locks"

echo "Setting up system-wide dconf keybinding..."

sudo mkdir -p "$DCONF_PATH" "$LOCKS_PATH"

sudo tee "$DCONF_PATH/00-custom-shortcuts" > /dev/null <<EOF
[org/gnome/settings-daemon/plugins/media-keys]
logout=''

custom-keybindings=['/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/change-ad-password/']

[org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/change-ad-password]
name='Change AD Password'
command='$SCRIPT_PATH'
binding='<Control><Alt>Delete'
EOF

# Optional: Lock the binding to prevent user override
sudo tee "$LOCKS_PATH/custom-shortcuts" > /dev/null <<EOF
/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/change-ad-password/binding
EOF

# Apply changes
echo "Updating dconf database..."
sudo dconf update

echo "✅ Setup complete. Please reboot or re-login for changes to take effect."

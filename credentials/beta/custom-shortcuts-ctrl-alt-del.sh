#!/bin/bash

# Only run if inside a graphical session and gsettings is available
if [ -n "$DISPLAY" ] && command -v gsettings >/dev/null 2>&1; then
    CUSTOM_KEYBIND_PATH="/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/"

    # Check if the shortcut already exists
    existing=$(gsettings get org.gnome.settings-daemon.plugins.media-keys custom-keybindings)
    if [[ $existing != *"$CUSTOM_KEYBIND_PATH"* ]]; then
        # Add the path to the list
        gsettings set org.gnome.settings-daemon.plugins.media-keys custom-keybindings "['$CUSTOM_KEYBIND_PATH']"

        # Set name, command, binding
        gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$CUSTOM_KEYBIND_PATH name 'AD Password Ctrl+Alt+Del'
        gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$CUSTOM_KEYBIND_PATH command '/usr/local/bin/ad-password-ctrl-alt-del-dark.sh'
        gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$CUSTOM_KEYBIND_PATH binding '<Control><Alt>Delete'
    fi
fi

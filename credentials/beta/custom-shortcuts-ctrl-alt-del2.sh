#!/bin/bash

export DISPLAY=:0
export DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$(id -u)/bus"

if command -v gsettings >/dev/null 2>&1 && command -v dconf >/dev/null 2>&1; then
    echo "🔧 Setting custom keybinding..."

    # 🧹 Disable the default Ctrl+Alt+Delete logout dialog
    gsettings set org.gnome.settings-daemon.plugins.media-keys logout ''

    CUSTOM_KEYBIND_PATH="/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/"

    existing=$(gsettings get org.gnome.settings-daemon.plugins.media-keys custom-keybindings 2>/dev/null)
    if [[ -z "$existing" || "$existing" = "@as []" ]]; then
        updated="['$CUSTOM_KEYBIND_PATH']"
    elif [[ "$existing" != *"$CUSTOM_KEYBIND_PATH"* ]]; then
        updated=$(echo "$existing" | sed "s/]$/, '$CUSTOM_KEYBIND_PATH']/;s/\[u/\[/")
    else
        updated="$existing"
    fi

    gsettings set org.gnome.settings-daemon.plugins.media-keys custom-keybindings "$updated"

    dconf write "${CUSTOM_KEYBIND_PATH}name" "'AD Change Password'"
    dconf write "${CUSTOM_KEYBIND_PATH}command" "'/usr/local/bin/amk/change_password.sh'"
    dconf write "${CUSTOM_KEYBIND_PATH}binding" "'<Control><Alt>Delete'"
fi

# Disable the default Ctrl+Alt+Delete logout dialog
#!/bin/bash

# === Detect GUI user and session ===

# Get the first non-root user from loginctl (should be the GUI user)
USERNAME=$(loginctl list-users | awk '$1 ~ /^[0-9]+$/ && $2 != "root" { print $2; exit }')
if [ -z "$USERNAME" ]; then
    echo "❌ No non-root user logged in."
    exit 1
fi

# Get the user's UID
USER_ID=$(id -u "$USERNAME")

# Get DISPLAY from the user's running processes (e.g., gnome-session)
USER_DISPLAY=$(ps -u "$USER_ID" -o args= | grep -oP 'DISPLAY=\K[^ ]+' | head -n1)
# Get DBUS session from gnome-session environment
USER_DBUS=$(grep -z DBUS_SESSION_BUS_ADDRESS /proc/$(pgrep -u "$USERNAME" gnome-session | head -n1)/environ | sed -E 's/.*DBUS_SESSION_BUS_ADDRESS=([^ ]+).*/\1/')

if [ -z "$USER_DISPLAY" ] || [ -z "$USER_DBUS" ]; then
    echo "❌ Failed to detect GUI session environment for $USERNAME."
    exit 1
fi

# === Configuration ===
CRED_DIR="/etc/smbcred"
cred_file="$CRED_DIR/$USERNAME"
cred_age_days=90
test_share="//amkcambodia.com/netlogon"

# === Exclude specific users ===
excluded_users=("sam")
for u in "${excluded_users[@]}"; do
    if [ "$USERNAME" == "$u" ]; then
        echo "User $USERNAME is excluded from this script."
        exit 0
    fi
done

# === Functions ===

# Check if credentials file is expired
is_cred_expired() {
    if [ ! -e "$cred_file" ]; then
        return 0
    fi
    last_modified=$(stat -c %Y "$cred_file")
    now=$(date +%s)
    age=$(( (now - last_modified) / 86400 ))
    [ "$age" -ge "$cred_age_days" ]
}

# Validate credentials using smbclient
are_credentials_valid() {
    smbclient "$test_share" -A "$cred_file" -c "exit" &>/dev/null
    return $?
}

# === Ensure credential directory exists ===
if [ ! -d "$CRED_DIR" ]; then
    mkdir -p "$CRED_DIR"
    chmod 700 "$CRED_DIR"
fi

# === Load existing credentials if available ===
if [ -f "$cred_file" ]; then
    # shellcheck disable=SC1090
    . "$cred_file"
fi

# === Determine if we need to prompt the user ===
if [ ! -s "$cred_file" ] || ! grep -q "password=" "$cred_file" || is_cred_expired || ! are_credentials_valid; then
    domain=$(sudo -u "$USERNAME" DISPLAY="$USER_DISPLAY" DBUS_SESSION_BUS_ADDRESS="$USER_DBUS" zenity --entry --title="Login" --text="Enter domain:" --entry-text="${domain:-}")
    username=$(sudo -u "$USERNAME" DISPLAY="$USER_DISPLAY" DBUS_SESSION_BUS_ADDRESS="$USER_DBUS" zenity --entry --title="Login" --text="Enter username:" --entry-text="${username:-}")
    password=$(sudo -u "$USERNAME" DISPLAY="$USER_DISPLAY" DBUS_SESSION_BUS_ADDRESS="$USER_DBUS" zenity --password --title="Login")

    if [ -n "$username" ] && [ -n "$password" ]; then
        cat <<CRED > "$cred_file"
username=$username
password=$password
domain=$domain
CRED
        chmod 600 "$cred_file"
        chown "$USERNAME:$USERNAME" "$cred_file"
        sudo -u "$USERNAME" DISPLAY="$USER_DISPLAY" DBUS_SESSION_BUS_ADDRESS="$USER_DBUS" zenity --info --text="✅ Credentials updated successfully."
        echo "✅ Credentials updated successfully."
    else
        sudo -u "$USERNAME" DISPLAY="$USER_DISPLAY" DBUS_SESSION_BUS_ADDRESS="$USER_DBUS" zenity --error --text="❌ Missing credentials. Login failed."
        echo "❌ Missing username or password. Aborted."
        exit 1
    fi
else
    echo "✅ Credentials are valid and not expired."
fi

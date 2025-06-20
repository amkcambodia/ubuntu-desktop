#!/bin/bash

USERNAME=$(logname)  # Get the real logged-in user
CRED_DIR="/etc/smbcred"
cred_file="$CRED_DIR/$USERNAME"
cred_age_days=90
test_share="//amkcambodia.com/netlogon"

# Exclude specific users
excluded_users=("sam")
for u in "${excluded_users[@]}"; do
    if [ "$USERNAME" == "$u" ]; then
        echo "User $USERNAME is excluded from this script."
        exit 0
    fi
done

# Get the DISPLAY and DBUS_SESSION_BUS_ADDRESS of the user's session
USER_DISPLAY=$(sudo -u "$USERNAME" bash -c 'echo $DISPLAY')
USER_DBUS=$(sudo -u "$USERNAME" bash -c 'echo $DBUS_SESSION_BUS_ADDRESS')

if [ -z "$USER_DISPLAY" ] || [ -z "$USER_DBUS" ]; then
    echo "❌ No GUI session detected for user $USERNAME."
    exit 1
fi

# Functions
is_cred_expired() {
    if [ ! -e "$cred_file" ]; then
        return 0
    fi
    last_modified=$(stat -c %Y "$cred_file")
    now=$(date +%s)
    age=$(( (now - last_modified) / 86400 ))
    [ "$age" -ge "$cred_age_days" ]
}

are_credentials_valid() {
    smbclient "$test_share" -A "$cred_file" -c "exit" &>/dev/null
    return $?
}

# Create directory if needed
if [ ! -d "$CRED_DIR" ]; then
    mkdir -p "$CRED_DIR"
    chmod 700 "$CRED_DIR"
fi

# Load values from existing credential file (if it exists)
if [ -f "$cred_file" ]; then
    # shellcheck disable=SC1090
    . "$cred_file"
fi

# Prompt if file is missing, empty, expired, or fails validation
if [ ! -s "$cred_file" ] || ! grep -q "password=" "$cred_file" || is_cred_expired || ! are_credentials_valid; then
    domain=$(sudo -u "$USERNAME" DISPLAY="$USER_DISPLAY" DBUS_SESSION_BUS_ADDRESS="$USER_DBUS" zenity --entry --title="Login" --text="Enter domain:" --entry-text="${domain:-}")
    username=$(sudo -u "$USERNAME" DISPLAY="$USER_DISPLAY" DBUS_SESSION_BUS_ADDRESS="$USER_DBUS" zenity --entry --title="Login" --text="Enter username:" --entry-text "${username:-}")
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

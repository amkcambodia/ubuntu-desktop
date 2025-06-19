#!/bin/bash

USERNAME=$(logname)  # Get the real logged-in user
CRED_DIR="/etc/smbcred"
cred_file="$CRED_DIR/$USERNAME"
cred_age_days=90
test_share="//amkcambodia.com/netlogon"

# Exclude user "sam"
excluded_users=("sam")
for u in "${excluded_users[@]}"; do
    if [ "$USERNAME" == "$u" ]; then
        echo "User $USERNAME is excluded from this script."
        exit 0
    fi
done

# Function to check if credentials file is older than X days
is_cred_expired() {
    if [ ! -e "$cred_file" ]; then
        return 0
    fi
    last_modified=$(stat -c %Y "$cred_file")
    now=$(date +%s)
    age=$(( (now - last_modified) / 86400 ))
    [ "$age" -ge "$cred_age_days" ]
}

# Function to test current credentials using smbclient
are_credentials_valid() {
    smbclient "$test_share" -A "$cred_file" -c "exit" &>/dev/null
    return $?
}

# Create credential directory if missing
if [ ! -d "$CRED_DIR" ]; then
    mkdir -p "$CRED_DIR"
    chmod 700 "$CRED_DIR"
fi

# Load username and domain from credential file if exists
if [ -f "$cred_file" ]; then
    # shellcheck disable=SC1090
    . "$cred_file"
fi

# Prompt if no file, invalid file, expired, or test fails
if [ ! -s "$cred_file" ] || ! grep -q "password=" "$cred_file" || is_cred_expired || ! are_credentials_valid; then
    domain=$(zenity --entry --title="Login" --text="Enter domain:" --entry-text="${domain:-}")
    username=$(zenity --entry --title="Login" --text="Enter username:" --entry-text "${username:-}")
    password=$(zenity --password --title="Login")

    if [ -n "$username" ] && [ -n "$password" ]; then
        cat <<CRED > "$cred_file"
username=$username
password=$password
domain=$domain
CRED
        chmod 600 "$cred_file"
        chown "$USERNAME:$USERNAME" "$cred_file"
        zenity --info --text="✅ Credentials updated successfully."
        echo "✅ Credentials updated successfully."
    else
        zenity --error --text="❌ Missing credentials. Login failed."
        echo "❌ Missing username or password. Aborted."
        exit 1
    fi
else
    echo "✅ Credentials are valid and not expired."
fi

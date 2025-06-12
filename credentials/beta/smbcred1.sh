cat <<'EOF' > /bin/smbcred.sh
#!/bin/bash

cred_file="$HOME/.smbcred"
cred_age_days=90
test_share="//amkcambodia.com/netlogon"

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

# Load username from file if exists
[ -f "$cred_file" ] && . "$cred_file"

# Prompt if no file, invalid file, expired, or test fails
if [ ! -s "$cred_file" ] || ! grep -q "password=" "$cred_file" || is_cred_expired || ! are_credentials_valid; then
    domain=$(zenity --entry --title="SMB Login" --text="Enter domain:" --entry-text="${domain:-}")
    username=$(zenity --entry --title="SMB Login" --text="Enter username:" --entry-text="${username:-}")
    password=$(zenity --password --title="SMB Login")

    if [ -n "$username" ] && [ -n "$password" ]; then
        cat <<CRED > "$cred_file"
username=$username
password=$password
domain=$domain
CRED
        chmod 600 "$cred_file"
        zenity --info --text="✅ SMB credentials saved/updated successfully."
        echo "✅ SMB credentials saved/updated"
    else
        zenity --error --text="❌ Missing credentials. Login failed."
        echo "❌ Missing username or password. Aborted."
    fi
else
    echo "✅ Credentials are valid and not expired."
fi
EOF
chmod +x /bin/smbcred.sh
sudo apt install smbclient -y
cat <<'EOF' > /bin/smbcred.sh
#!/bin/bash

cred_file="$HOME/.smbcred"
cred_age_days=90

# Function to check if credentials are older than X days
is_cred_expired() {
    if [ ! -e "$cred_file" ]; then
        return 0  # File doesn't exist → expired
    fi
    last_modified=$(stat -c %Y "$cred_file")
    now=$(date +%s)
    age=$(( (now - last_modified) / 86400 ))
    [ "$age" -ge "$cred_age_days" ]
}

# If file doesn't exist or password is expired, prompt
if [ ! -s "$cred_file" ] || ! grep -q "password=" "$cred_file" || is_cred_expired; then
    domain=$(zenity --entry --title="SMB Login" --text="Enter domain:")
    username=$(zenity --entry --title="SMB Login" --text="Enter username:")
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
    echo "✅ Credentials file is valid and not expired."
fi


# ------------------------------------------------------------------

##!/bin/bash
#
#cred_file="$HOME/.smbcred"
#
## Only prompt if file doesn't exist or password is empty
#if [ ! -s "$cred_file" ] || ! grep -q "password=" "$cred_file"; then
#    domain=$(zenity --entry --title="SMB Login" --text="Enter domain:")
#    username=$(zenity --entry --title="SMB Login" --text="Enter username:")
#    password=$(zenity --password --title="SMB Login")
#
#    if [ -n "$username" ] && [ -n "$password" ]; then
#        cat <<CRED > "$cred_file"
#username=$username
#password=$password
#domain=$domain
#CRED
#        chmod 600 "$cred_file"
#        zenity --info --text="✅ SMB credentials saved successfully."
#        echo "✅ SMB credentials saved"
#    else
#        zenity --error --text="❌ Missing credentials. Login failed."
#        echo "❌ Missing username or password. Aborted."
#    fi
#else
#    echo "✅ Credentials already exist"
#fi
EOF
chmod +x /bin/smbcred.sh
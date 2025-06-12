#!/bin/bash

USERNAME=$(logname)
CON_NAME="Wired connection 1"
CA_CERT="/etc/ssl/certs/amkcambodia-AMKDC02-CA.pem"
# CRED_FILE="$HOME/.smbcred"
CRED_FILE="/etc/smbcred/$USERNAME"

# Function to run a command and check for errors
run_command() {
    if ! output=$("$@" 2>&1); then
        echo "❌ Command failed: $*"
        echo "Error: $output"
        exit 1
    fi
    echo "$output"
}

# Find the first ethernet interface
get_ethernet_iface() {
    nmcli -t device status | awk -F: '$3 == "ethernet" {print $1; exit}'
}

# Read credentials from file
read_credentials() {
    if [ ! -f "$CRED_FILE" ]; then
        echo "❌ Credential file not found at $CRED_FILE"
        exit 1
    fi

    while IFS='=' read -r key val; do
        key=$(echo "$key" | tr -d ' ')
        val=$(echo "$val" | tr -d ' ')
        case "$key" in
            username) username="$val" ;;
            password) password="$val" ;;
            domain) domain="$val" ;;
        esac
    done < "$CRED_FILE"
}

# Main script logic
main() {
    iface=$(get_ethernet_iface)
    if [ -z "$iface" ]; then
        echo "❌ No Ethernet interface found."
        exit 1
    fi

    read_credentials

    if [ -z "$username" ] || [ -z "$password" ]; then
        echo "❌ Username or password not defined in credentials file."
        exit 1
    fi

    if [ -n "$domain" ]; then
        identity="${domain}\\${username}"
    else
        identity="$username"
    fi

    echo "🔧 Configuring LAN: $CON_NAME on interface $iface"

    run_command nmcli connection add \
        type ethernet \
        ifname "$iface" \
        con-name "$CON_NAME" \
        802-1x.eap peap \
        802-1x.identity "$identity" \
        802-1x.password "$password" \
        802-1x.phase2-auth mschapv2 \
        802-1x.ca-cert "$CA_CERT" \
        802-1x.system-ca-certs yes \
        connection.autoconnect yes

    echo "✅ LAN profile '$CON_NAME' created."
}

main

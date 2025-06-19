#!/bin/bash

TARGET_SSID="AMKBr"
IFACE=$(nmcli -t device status | grep ':wifi:' | cut -d: -f1)

if [[ -z "$IFACE" ]]; then
  echo "❌ No Wi-Fi interface found."
  exit 1
fi

USERNAME=$(logname)
CRED_FILE="/etc/smbcred/$USERNAME"
CA_CERT="/etc/ssl/certs/amkcambodia-AMKDC02-CA.pem"

if [[ ! -f "$CRED_FILE" ]]; then
  echo "❌ Credential file not found: $CRED_FILE"
  exit 1
fi

source "$CRED_FILE"

if [[ -z "$username" || -z "$password" ]]; then
  echo "❌ Username or password not defined."
  exit 1
fi

if [[ -n "$domain" ]]; then
  IDENTITY="$domain\\$username"
else
  IDENTITY="$username"
fi

# Use unique connection name per user
USER_CON_NAME="${TARGET_SSID}-${USERNAME}"

# Check if the connection exists for this user
nmcli --terse --fields NAME connection show | grep -Fxq "$USER_CON_NAME"
if [[ $? -ne 0 ]]; then
  echo "🔧 Creating user-specific Wi-Fi profile: $USER_CON_NAME"
  nmcli connection add type wifi ifname "$IFACE" con-name "$USER_CON_NAME" ssid "$TARGET_SSID" \
    wifi-sec.key-mgmt wpa-eap \
    802-1x.eap peap \
    802-1x.identity "$IDENTITY" \
    802-1x.password "$password" \
    802-1x.phase2-auth mschapv2 \
    802-1x.ca-cert "$CA_CERT" \
    802-1x.system-ca-certs yes \
    wifi-sec.group ccmp \
    connection.autoconnect yes \
    connection.permissions "$USERNAME"
else
  echo "🔄 Updating existing user-specific Wi-Fi profile: $USER_CON_NAME"
  nmcli connection modify "$USER_CON_NAME" \
    802-1x.identity "$IDENTITY" \
    802-1x.password "$password"
fi

# Activate the connection
nmcli connection up "$USER_CON_NAME"

echo "✅ Wi-Fi profile '$USER_CON_NAME' configured for user '$USERNAME'."

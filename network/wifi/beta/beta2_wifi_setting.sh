#!/bin/bash

TARGET_SSID="AMKBr"
USERNAME=$(whoami)
IFACE=$(nmcli -t device status | grep ':wifi:' | cut -d: -f1)

if [[ -z "$IFACE" ]]; then
  echo "❌ No Wi-Fi interface found."
  exit 1
fi

CRED_FILE="/etc/smbcred/$USERNAME"

if [[ ! -f "$CRED_FILE" ]]; then
  echo "❌ Credential file not found at $CRED_FILE"
  exit 1
fi

source "$CRED_FILE"

if [[ -z "$username" || -z "$password" ]]; then
  echo "❌ Username or password not defined in $CRED_FILE"
  exit 1
fi

if [[ -n "$domain" ]]; then
  IDENTITY="$domain\\$username"
else
  IDENTITY="$username"
fi

PROFILE_NAME="${TARGET_SSID}-${USERNAME}"

echo "🔍 Checking if user Wi-Fi profile exists: $PROFILE_NAME"

if nmcli --mode tabular --fields NAME connection show | grep -q "^$PROFILE_NAME"; then
  echo "🔄 Modifying existing Wi-Fi profile: $PROFILE_NAME"
  nmcli connection modify "$PROFILE_NAME" \
    wifi-sec.key-mgmt wpa-eap \
    802-1x.eap peap \
    802-1x.identity "$IDENTITY" \
    802-1x.password "$password" \
    802-1x.phase2-auth mschapv2 \
    802-1x.system-ca-certs yes \
    connection.autoconnect yes
else
  echo "➕ Creating Wi-Fi profile: $PROFILE_NAME"
  nmcli connection add type wifi ifname "$IFACE" con-name "$PROFILE_NAME" ssid "$TARGET_SSID" \
    wifi-sec.key-mgmt wpa-eap \
    802-1x.eap peap \
    802-1x.identity "$IDENTITY" \
    802-1x.password "$password" \
    802-1x.phase2-auth mschapv2 \
    802-1x.system-ca-certs yes \
    connection.autoconnect yes
fi

echo "🔌 Disconnecting and reconnecting with profile $PROFILE_NAME..."
nmcli device disconnect "$IFACE"
sleep 2
nmcli connection up "$PROFILE_NAME"

echo "✅ Connected as $IDENTITY using Wi-Fi profile $PROFILE_NAME"

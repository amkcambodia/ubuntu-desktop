#!/bin/bash

TARGET_SSID="AMKBr"
IFACE=$(nmcli -t device status | grep ':wifi:' | cut -d: -f1)

if [[ -z "$IFACE" ]]; then
  echo "❌ No Wi-Fi interface found."
  exit 1
fi

CA_CERT="/etc/ssl/certs/amkcambodia-AMKDC02-CA.pem"
CRED_FILE="/etc/smbcred/$USERNAME"

if [[ ! -f "$CRED_FILE" ]]; then
  echo "❌ Credential file not found."
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

echo "🔧 Configuring auto-connect to SSID: $TARGET_SSID"
#nmcli connection add type wifi ifname "$IFACE" con-name "$TARGET_SSID" ssid "$TARGET_SSID" \
nmcli connection modify "$TARGET_SSID" \
  wifi-sec.key-mgmt wpa-eap \
  802-1x.eap peap \
  802-1x.identity "$IDENTITY" \
  802-1x.password "$password" \
  802-1x.phase2-auth mschapv2 \
  802-1x.ca-cert "$CA_CERT" \
  802-1x.system-ca-certs yes \
  wifi-sec.group ccmp \
  connection.autoconnect yes

echo "✅ Wi-Fi profile created and will auto-connect to $TARGET_SSID."


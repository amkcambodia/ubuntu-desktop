#!/bin/bash

CON_NAME="Wired connection 1"
IFACE=$(nmcli -t device status | grep ':ethernet:' | cut -d: -f1)

if [[ -z "$IFACE" ]]; then
  echo "❌ No Ethernet interface found."
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

echo "🔧 Configuring LAN: $CON_NAME"
#nmcli connection add type ethernet ifname "$IFACE" con-name "$CON_NAME" \
nmcli connection "$CON_NAME" \
  802-1x.eap peap \
  802-1x.identity "$IDENTITY" \
  802-1x.password "$password" \
  802-1x.phase2-auth mschapv2 \
  802-1x.ca-cert "$CA_CERT" \
  802-1x.system-ca-certs yes \
  connection.autoconnect yes

echo "✅ LAN profile '$CON_NAME' created."

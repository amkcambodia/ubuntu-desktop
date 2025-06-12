cat <<EOF > /usr/local/bin/wifi-setting.sh
#!/bin/bash

TARGET_SSID="AMKBr"
IFACE=$(nmcli -t device status | grep ':wifi:' | cut -d: -f1)

if [[ -z "$IFACE" ]]; then
  echo "❌ No Wi-Fi interface found."
  exit 1
fi

CA_CERT="/etc/ssl/certs/amkcambodia-AMKDC02-CA.pem"
CRED_FILE="~/.smbcred"

# Check credentials file
if [[ ! -f "$CRED_FILE" ]]; then
  echo "❌ Credential file not found."
  exit 1
fi

# Read credentials securely
source "$CRED_FILE"

if [[ -z "$username" || -z "$password" ]]; then
  echo "❌ Username or password not defined."
  exit 1
fi

# Construct identity with domain if needed
if [[ -n "$domain" ]]; then
  IDENTITY="$domain\\$username"  # Use "\\" to escape backslash
else
  IDENTITY="$username"
fi

echo "🔧 Configuring auto-connect to SSID: $TARGET_SSID"
nmcli connection add type wifi ifname "$IFACE" con-name "$TARGET_SSID" ssid "$TARGET_SSID" \
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
EOF
sudo chmod +x /usr/local/bin/wifi-setting.sh
sudo chmod 644 /usr/local/bin/wifi-setting.sh

cat <<'EOF' | sudo tee /etc/NetworkManager/dispatcher.d/99-wifi-password-recovery > /dev/null
#!/bin/bash

IFACE="$1"
STATUS="$2"
SSID="AMKBr"

# Only trigger on Wi-Fi disconnect
if [[ "$STATUS" == "down" ]]; then
  # Get the active user (with GUI session)
  USERNAME=$(logname)
  USERHOME=$(getent passwd "$USERNAME" | cut -d: -f6)

  # Check if DISPLAY and DBUS are available for GUI tools
  export DISPLAY=:0
  export XAUTHORITY="$USERHOME/.Xauthority"
  export DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$(id -u "$USERNAME")/bus"

  # Run as logged-in user (not root)
  sudo -u "$USERNAME" /usr/local/bin/wifi-password-recovery.sh
fi
EOF

# Set proper permission
sudo chmod +x /etc/NetworkManager/dispatcher.d/99-wifi-password-recovery
sudo chmod +x /etc/NetworkManager/dispatcher.d/99-wifi-password-recovery

cat <<EOF > /usr/local/bin/wifi-password-recovery.sh
#!/bin/bash
# ---- Configuration ----
SSID="AMKBr"   # Change this to your Wi-Fi name
IFACE=$(nmcli -t device status | grep ':wifi:' | cut -d: -f1)

# ---- Detect Wi-Fi Status ----
CON_STATE=$(nmcli -t -f GENERAL.STATE device show "$IFACE" | cut -d: -f2)
if [[ "$CON_STATE" -eq 30 ]]; then
  echo "✅ Already connected to Wi-Fi."
  exit 0
fi

# ---- Show Password Prompt ----
NEW_PASSWORD=$(zenity --entry --hide-text --title="Wi-Fi Authentication Failed" \
  --text="Authentication to '$SSID' failed.\nPlease enter your new AD password:")

if [[ -z "$NEW_PASSWORD" ]]; then
  zenity --error --text="❌ Password entry cancelled."
  exit 1
fi

# ---- Update Wi-Fi Connection Password ----
nmcli connection modify "$SSID" 802-1x.password "$NEW_PASSWORD"

# ---- Try to reconnect ----
nmcli connection down "$SSID"
sleep 2
nmcli connection up "$SSID"

# ---- Verify ----
sleep 5
CON_STATE=$(nmcli -t -f GENERAL.STATE device show "$IFACE" | cut -d: -f2)
if [[ "$CON_STATE" -eq 100 ]]; then
  zenity --info --text="✅ Successfully reconnected to '$SSID'."
else
  zenity --error --text="❌ Failed to connect. Please check your password again."
fi
EOF
sudo chmod +x /usr/local/bin/wifi-password-recovery.sh
sudo chmod 755 /usr/local/bin/wifi-password-recovery.sh


#!/bin/bash

CURRENT_USER=$(logname)

# Skip unwanted users
if [[ "$CURRENT_USER" == "root" || "$CURRENT_USER" == "sam" ]]; then
  exit 0
fi

(
  sleep 10

  LOG_FILE="/tmp/amk_wifi_${CURRENT_USER}.log"
  echo "[$(date)] Starting Wi-Fi setup for $CURRENT_USER" > "$LOG_FILE"

  TARGET_SSID="Staff"
  REALM="AMKCAMBODIA.COM"
  DOMAIN="amkcambodia.com"
  IFACE=$(nmcli -t device status | grep ':wifi:' | cut -d: -f1)

  if [[ -z "$IFACE" ]]; then
    echo "❌ No Wi-Fi interface found." >> "$LOG_FILE"
    exit 1
  fi

  # Rescan for available Wi-Fi networks
  echo "🔍 Scanning for Wi-Fi networks..." >> "$LOG_FILE"
  nmcli dev wifi rescan
  sleep 2

  if ! nmcli dev wifi list | grep -q "$TARGET_SSID"; then
    echo "📡 SSID '$TARGET_SSID' not found. Skipping authentication." >> "$LOG_FILE"
    exit 0
  fi

  echo "✅ SSID '$TARGET_SSID' found. Proceeding with authentication test..." >> "$LOG_FILE"

  CRED_FILE="/etc/smbcred/$CURRENT_USER"
  CA_CERT="/etc/ssl/certs/amkcambodia-AMKDC02-CA.pem"

  # Prepare GUI environment
  export DISPLAY=:0
  export XAUTHORITY="/home/$CURRENT_USER/.Xauthority"

  # Prompt for missing credentials
  if [[ ! -f "$CRED_FILE" ]]; then
    echo "⚠️ No credential file. Prompting..." >> "$LOG_FILE"

    AD_USER=$(zenity --entry --title="Wi-Fi Login" --text="Enter your AD Username:")
    AD_PASS=$(zenity --password --title="Wi-Fi Login" --text="Enter your AD Password:")

    if [[ -z "$AD_USER" || -z "$AD_PASS" ]]; then
      zenity --error --text="Missing credentials. Cannot continue."
      exit 1
    fi

    echo "username=\"$AD_USER\"" > "$CRED_FILE"
    echo "password=\"$AD_PASS\"" >> "$CRED_FILE"
    echo "domain=\"$DOMAIN\"" >> "$CRED_FILE"

    chmod 600 "$CRED_FILE"
    chown root:root "$CRED_FILE"
  fi

  source "$CRED_FILE"

  if [[ -z "$username" || -z "$password" ]]; then
    echo "❌ Missing values in credential file." >> "$LOG_FILE"
    exit 1
  fi

  # Build identity
  IDENTITY="${domain}\\${username}"
  TEST_CON_NAME="test-${TARGET_SSID}-${CURRENT_USER}"

  # Clean up any old temp profile
  if nmcli connection show "$TEST_CON_NAME" &>/dev/null; then
    nmcli connection delete "$TEST_CON_NAME"
  fi

  # Try temporary connection to test auth
  echo "🔌 Attempting test connection to $TARGET_SSID" >> "$LOG_FILE"
  nmcli connection add type wifi ifname "$IFACE" con-name "$TEST_CON_NAME" ssid "$TARGET_SSID" \
    wifi-sec.key-mgmt wpa-eap \
    802-1x.eap peap \
    802-1x.identity "$username@$REALM" \
    802-1x.password "$password" \
    802-1x.phase2-auth mschapv2 \
    802-1x.ca-cert "$CA_CERT" \
    802-1x.system-ca-certs yes \
    connection.autoconnect no

  nmcli connection up "$TEST_CON_NAME" >> "$LOG_FILE" 2>&1
  sleep 5
  nmcli connection down "$TEST_CON_NAME"
  nmcli connection delete "$TEST_CON_NAME"

  # kinit to verify password or expiration
  echo "$password" | kinit "$username@$REALM" 2> /tmp/kinit_error.log
  if [ $? -ne 0 ]; then
    ERROR_MSG=$(cat /tmp/kinit_error.log)
    echo "⚠️ Authentication failed: $ERROR_MSG" >> "$LOG_FILE"

    if echo "$ERROR_MSG" | grep -qi "Password has expired"; then
      zenity --info --title="Password Expired" --text="Your AD password has expired.\nPlease reset it now."
      sudo -u "$CURRENT_USER" kpasswd "$username@$REALM"
      NEW_PASS=$(zenity --password --title="New Password" --text="Enter your new password:")

      if [[ -z "$NEW_PASS" ]]; then
        zenity --error --text="Password reset cancelled."
        exit 1
      fi

      echo "$NEW_PASS" | kinit "$username@$REALM"
      if [ $? -ne 0 ]; then
        zenity --error --text="New password is incorrect."
        exit 1
      fi

      sed -i "s/^password=.*/password=\"$NEW_PASS\"/" "$CRED_FILE"
      password="$NEW_PASS"
      echo "✅ Password updated." >> "$LOG_FILE"
    else
      zenity --error --text="Authentication failed:\n$ERROR_MSG"
      exit 1
    fi
  else
    echo "✅ Authentication success with kinit." >> "$LOG_FILE"
  fi

  # Create or update full Wi-Fi profile
  USER_CON_NAME="${TARGET_SSID}-${CURRENT_USER}"

  if ! nmcli --terse --fields NAME connection show | grep -Fxq "$USER_CON_NAME"; then
    echo "🔧 Creating Wi-Fi profile: $USER_CON_NAME" >> "$LOG_FILE"
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
      connection.permissions "$CURRENT_USER"
  else
    echo "🔄 Updating Wi-Fi profile: $USER_CON_NAME" >> "$LOG_FILE"
    nmcli connection modify "$USER_CON_NAME" \
      802-1x.identity "$IDENTITY" \
      802-1x.password "$password"
  fi

  echo "✅ Wi-Fi setup completed for $CURRENT_USER." >> "$LOG_FILE"

) &

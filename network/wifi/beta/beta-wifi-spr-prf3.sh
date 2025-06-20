#!/bin/bash

CURRENT_USER=$(logname)

# Exclude root and specific users
if [[ "$CURRENT_USER" == "root" || "$CURRENT_USER" == "sam" ]]; then
  exit 0
fi

(
  sleep 10  # Wait for user session and NetworkManager

  LOG_FILE="/tmp/amk_wifi_${CURRENT_USER}.log"
  echo "[$(date)] Starting Wi-Fi setup" > "$LOG_FILE"

  TARGET_SSID="AMKBr"
  REALM="CAMBODIA.COM"  # UPPERCASE DOMAIN
  IFACE=$(nmcli -t device status | grep ':wifi:' | cut -d: -f1)

  if [[ -z "$IFACE" ]]; then
    echo "❌ No Wi-Fi interface found." >> "$LOG_FILE"
    exit 1
  fi

  CRED_FILE="/etc/smbcred/$CURRENT_USER"
  CA_CERT="/etc/ssl/certs/amkcambodia-AMKDC02-CA.pem"

  # GUI environment
  export DISPLAY=:0
  export XAUTHORITY="/home/$CURRENT_USER/.Xauthority"

  # Prompt for credentials if missing
  if [[ ! -f "$CRED_FILE" ]]; then
    echo "⚠️ Credential file not found. Prompting..." >> "$LOG_FILE"

    AD_USER=$(zenity --entry --title="Wi-Fi Login" --text="Enter your AD Username:")
    AD_PASS=$(zenity --password --title="Wi-Fi Login" --text="Enter your AD Password:")

    if [[ -z "$AD_USER" || -z "$AD_PASS" ]]; then
      zenity --error --text="Missing credentials. Cannot continue."
      exit 1
    fi

    DOMAIN="yourdomain"  # lowercase NetBIOS or leave empty
    echo "username=\"$AD_USER\"" > "$CRED_FILE"
    echo "password=\"$AD_PASS\"" >> "$CRED_FILE"
    echo "domain=\"$DOMAIN\"" >> "$CRED_FILE"

    chmod 600 "$CRED_FILE"
    chown root:root "$CRED_FILE"
  fi

  source "$CRED_FILE"

  if [[ -z "$username" || -z "$password" ]]; then
    echo "❌ Incomplete credentials in $CRED_FILE" >> "$LOG_FILE"
    exit 1
  fi

  # Check if password expired using kinit
  echo "$password" | kinit "$username@$REALM" 2> /tmp/kinit_error.log
  if [ $? -ne 0 ]; then
    ERROR_MSG=$(cat /tmp/kinit_error.log)
    echo "⚠️ kinit failed: $ERROR_MSG" >> "$LOG_FILE"

    if echo "$ERROR_MSG" | grep -qi "Password has expired"; then
      zenity --info --title="Password Expired" --text="Your AD password has expired.\nPlease reset it now."

      # Run kpasswd interactively
      sudo -u "$CURRENT_USER" kpasswd "$username@$REALM"

      # Prompt for new password
      NEW_PASS=$(zenity --password --title="New Password" --text="Enter your new password:")
      if [[ -z "$NEW_PASS" ]]; then
        zenity --error --text="Password reset canceled."
        exit 1
      fi

      # Confirm new password works
      echo "$NEW_PASS" | kinit "$username@$REALM"
      if [ $? -ne 0 ]; then
        zenity --error --text="New password failed. Cannot proceed."
        exit 1
      fi

      # Update password in cred file
      sed -i "s/^password=.*/password=\"$NEW_PASS\"/" "$CRED_FILE"
      password="$NEW_PASS"
      echo "✅ Password reset and updated" >> "$LOG_FILE"
    else
      zenity --error --text="Authentication failed:\n$ERROR_MSG"
      exit 1
    fi
  else
    echo "✅ Pre-authentication succeeded" >> "$LOG_FILE"
  fi

  # Build full identity
  if [[ -n "$domain" ]]; then
    IDENTITY="$domain\\$username"
  else
    IDENTITY="$username"
  fi

  USER_CON_NAME="${TARGET_SSID}-${CURRENT_USER}"

  # Create or update connection
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

  # Connect if not active
  if nmcli -t -f NAME connection show --active | grep -q "$USER_CON_NAME"; then
    echo "🔌 Connection already active." >> "$LOG_FILE"
  else
    echo "▶️ Activating connection: $USER_CON_NAME" >> "$LOG_FILE"
    nmcli connection up "$USER_CON_NAME" >> "$LOG_FILE" 2>&1
  fi

  echo "✅ Wi-Fi connection complete." >> "$LOG_FILE"

) &

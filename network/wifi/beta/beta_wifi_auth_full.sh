#!/bin/bash

CURRENT_USER=$(logname)

# 1. Skip root and excluded users
if [[ "$CURRENT_USER" == "root" || "$CURRENT_USER" == "sam" ]]; then
  exit 0
fi

(
  sleep 10

  LOG_FILE="/tmp/amk_wifi_${CURRENT_USER}.log"
  echo "[$(date)] Starting AMKBr Wi-Fi setup for $CURRENT_USER" > "$LOG_FILE"

  TARGET_SSID="AMKBr"
  REALM="AMKCAMBODIA.COM"
  DOMAIN="amkcambodia.com"
  IFACE=$(nmcli -t device status | grep ':wifi:' | cut -d: -f1)
  CRED_FILE="/etc/smbcred/$CURRENT_USER"
  CA_CERT="/etc/ssl/certs/amkcambodia-AMKDC02-CA.pem"

  export DISPLAY=:0
  export XAUTHORITY="/home/$CURRENT_USER/.Xauthority"

  # 2. Rescan and check SSID
  nmcli dev wifi rescan
  sleep 2
  if ! nmcli dev wifi list | grep -q "$TARGET_SSID"; then
    echo "❌ SSID $TARGET_SSID not found. Exiting." >> "$LOG_FILE"
    exit 0
  fi

  # 3. Prompt for credentials if missing
  if [[ ! -f "$CRED_FILE" ]]; then
    AD_USER=$(zenity --entry --title="Wi-Fi Login" --text="Enter your AD Username:")
    AD_PASS=$(zenity --password --title="Wi-Fi Login" --text="Enter your AD Password:")

    if [[ -z "$AD_USER" || -z "$AD_PASS" ]]; then
      zenity --error --text="Missing credentials."
      exit 1
    fi

    echo "username=\"$AD_USER\"" > "$CRED_FILE"
    echo "password=\"$AD_PASS\"" >> "$CRED_FILE"
    echo "domain=\"$DOMAIN\"" >> "$CRED_FILE"
    chmod 600 "$CRED_FILE"; chown root:root "$CRED_FILE"
  fi

  source "$CRED_FILE"

  if [[ -z "$username" || -z "$password" ]]; then
    zenity --error --text="Invalid credential file."
    exit 1
  fi

  IDENTITY="${domain}\\${username}"
  PROFILE_NAME="${TARGET_SSID}-${CURRENT_USER}"

  # 4. Create or update real connection
  if ! nmcli connection show | grep -q "$PROFILE_NAME"; then
    echo "🔧 Creating Wi-Fi profile: $PROFILE_NAME" >> "$LOG_FILE"
    nmcli connection add type wifi ifname "$IFACE" con-name "$PROFILE_NAME" ssid "$TARGET_SSID" \
      wifi-sec.key-mgmt wpa-eap \
      802-1x.eap peap \
      802-1x.identity "$IDENTITY" \
      802-1x.password "$password" \
      802-1x.phase2-auth mschapv2 \
      802-1x.ca-cert "$CA_CERT" \
      802-1x.system-ca-certs yes \
      connection.autoconnect yes \
      connection.permissions "$CURRENT_USER"
  else
    echo "🔄 Updating existing profile: $PROFILE_NAME" >> "$LOG_FILE"
    nmcli connection modify "$PROFILE_NAME" \
      802-1x.identity "$IDENTITY" \
      802-1x.password "$password"
  fi

  # 5. Attempt to connect
  echo "▶️ Connecting to $PROFILE_NAME..." >> "$LOG_FILE"
  nmcli connection up "$PROFILE_NAME" >> "$LOG_FILE" 2>&1

  # 6. Run kinit to check password
  echo "$password" | kinit "$username@$REALM" 2> /tmp/kinit_error.log
  if [ $? -ne 0 ]; then
    ERROR_MSG=$(cat /tmp/kinit_error.log)
    echo "⚠️ kinit failed: $ERROR_MSG" >> "$LOG_FILE"

    if echo "$ERROR_MSG" | grep -qi "Password has expired"; then
      zenity --info --text="Your AD password has expired.\nYou must reset it now."
      sudo -u "$CURRENT_USER" kpasswd "$username@$REALM"

      NEW_PASS=$(zenity --password --title="New Password" --text="Enter your new password:")
      if [[ -z "$NEW_PASS" ]]; then
        zenity --error --text="Password reset canceled."
        exit 1
      fi

      # Validate new password
      echo "$NEW_PASS" | kinit "$username@$REALM"
      if [ $? -ne 0 ]; then
        zenity --error --text="New password failed."
        exit 1
      fi

      # Save new password and reconnect
      sed -i "s/^password=.*/password=\"$NEW_PASS\"/" "$CRED_FILE"
      password="$NEW_PASS"
      echo "✅ Password updated." >> "$LOG_FILE"

      echo "🔁 Reconnecting with new password..." >> "$LOG_FILE"
      nmcli connection modify "$PROFILE_NAME" \
        802-1x.password "$password"
      nmcli connection up "$PROFILE_NAME" >> "$LOG_FILE" 2>&1
    else
      zenity --error --text="Authentication failed:\n$ERROR_MSG"
      exit 1
    fi
  else
    echo "✅ kinit succeeded. Wi-Fi should be active." >> "$LOG_FILE"
  fi

) &

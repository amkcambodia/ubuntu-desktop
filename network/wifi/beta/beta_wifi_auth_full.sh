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

  TARGET_SSID="AMKBr"
  REALM="AMKCAMBODIA.COM"
  DOMAIN="amkcambodia.com"
  IFACE=$(nmcli -t device status | grep ':wifi:' | cut -d: -f1)
  CRED_FILE="/etc/smbcred/$CURRENT_USER"
  CA_CERT="/etc/ssl/certs/amkcambodia-AMKDC02-CA.pem"

  # Prepare GUI
  export DISPLAY=:0
  export XAUTHORITY="/home/$CURRENT_USER/.Xauthority"

  nmcli dev wifi rescan
  sleep 2

  if ! nmcli dev wifi list | grep -q "$TARGET_SSID"; then
    echo "📡 SSID '$TARGET_SSID' not found. Skipping." >> "$LOG_FILE"
    exit 0
  fi

  if [[ ! -f "$CRED_FILE" ]]; then
    AD_USER=$(zenity --entry --title="Wi-Fi Login" --text="Enter AD Username:")
    AD_PASS=$(zenity --password --title="Wi-Fi Login" --text="Enter AD Password:")

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
  IDENTITY="${domain}\\${username}"
  TEST_CON_NAME="test-${TARGET_SSID}-${CURRENT_USER}"

  nmcli connection delete "$TEST_CON_NAME" &>/dev/null
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

  echo "$password" | kinit "$username@$REALM" 2> /tmp/kinit_error.log
  if [ $? -ne 0 ]; then
    ERROR_MSG=$(cat /tmp/kinit_error.log)
    if echo "$ERROR_MSG" | grep -qi "Password has expired"; then
      zenity --info --text="Password expired. Please reset."
      sudo -u "$CURRENT_USER" kpasswd "$username@$REALM"
      NEW_PASS=$(zenity --password --text="Enter new password:")
      echo "$NEW_PASS" | kinit "$username@$REALM" || { zenity --error --text="New password invalid."; exit 1; }
      sed -i "s/^password=.*/password=\"$NEW_PASS\"/" "$CRED_FILE"
      password="$NEW_PASS"
    else
      zenity --error --text="Auth failed:\n$ERROR_MSG"
      exit 1
    fi
  fi

  USER_CON_NAME="${TARGET_SSID}-${CURRENT_USER}"
  if ! nmcli connection show | grep -q "$USER_CON_NAME"; then
    nmcli connection add type wifi ifname "$IFACE" con-name "$USER_CON_NAME" ssid "$TARGET_SSID" \
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
    nmcli connection modify "$USER_CON_NAME" \
      802-1x.identity "$IDENTITY" \
      802-1x.password "$password"
  fi

  echo "✅ Completed Wi-Fi setup." >> "$LOG_FILE"
) &

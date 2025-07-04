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

  TARGET_SSID="Staff"
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

  # 4. Create or update Wi-Fi profile
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
  if ! nmcli connection up "$PROFILE_NAME" >> "$LOG_FILE" 2>&1; then
    echo "❌ Wi-Fi connection failed." >> "$LOG_FILE"
    zenity --error --title="Wi-Fi Error" --text="Connection to Wi-Fi '$TARGET_SSID' failed.\nPlease check your password."
    exit 1
  fi

  echo "✅ Wi-Fi connection successful." >> "$LOG_FILE"

) &

#!/bin/bash

# Run this script in background manually or via login profile as: /usr/local/bin/amk/wifi-setting.sh &

(
  sleep 10  # Delay to ensure NetworkManager and user session are ready

  LOG_FILE="/tmp/amk_wifi_$(logname).log"
  echo "[$(date)] Starting Wi-Fi setup" > "$LOG_FILE"

  TARGET_SSID="Staff"
  IFACE=$(nmcli -t device status | grep ':wifi:' | cut -d: -f1)

  if [[ -z "$IFACE" ]]; then
    echo "❌ No Wi-Fi interface found." >> "$LOG_FILE"
    exit 1
  fi

  USERNAME=$(logname)
  CRED_FILE="/etc/smbcred/$USERNAME"
  CA_CERT="/etc/ssl/certs/amkcambodia-AMKDC02-CA.pem"

  if [[ ! -f "$CRED_FILE" ]]; then
    echo "❌ Credential file not found: $CRED_FILE" >> "$LOG_FILE"
    exit 1
  fi

  source "$CRED_FILE"

  if [[ -z "$username" || -z "$password" ]]; then
    echo "❌ Username or password not defined." >> "$LOG_FILE"
    exit 1
  fi

  if [[ -n "$domain" ]]; then
    IDENTITY="$domain\\$username"
  else
    IDENTITY="$username"
  fi

  USER_CON_NAME="${TARGET_SSID}-${USERNAME}"

  # Check if the connection exists
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
      connection.permissions "$USERNAME"
  else
    echo "🔄 Updating Wi-Fi profile: $USER_CON_NAME" >> "$LOG_FILE"
    nmcli connection modify "$USER_CON_NAME" \
      802-1x.identity "$IDENTITY" \
      802-1x.password "$password"
  fi

  # Check if already active
  if nmcli -t -f NAME connection show --active | grep -q "$USER_CON_NAME"; then
    echo "🔌 Connection $USER_CON_NAME already active." >> "$LOG_FILE"
  else
    echo "▶️ Activating connection: $USER_CON_NAME" >> "$LOG_FILE"
    nmcli connection up "$USER_CON_NAME" >> "$LOG_FILE" 2>&1
  fi

  echo "✅ Wi-Fi profile '$USER_CON_NAME' configured for user '$USERNAME'." >> "$LOG_FILE"

) &  # End of background subshell

#!/bin/bash

CURRENT_USER=$(logname)
if [[ "$CURRENT_USER" == "root" || "$CURRENT_USER" == "sam" ]]; then exit 0; fi

(
  sleep 10

  LOG_FILE="/tmp/amk_wifi_${CURRENT_USER}.log"
  echo "[$(date)] Wi-Fi auth script started" > "$LOG_FILE"

  TARGET_SSID="AMKBr"
  REALM="AMKCAMBODIA.COM"
  DOMAIN="amkcambodia.com"
  IFACE=$(nmcli -t device status | grep ':wifi:' | cut -d: -f1)
  CRED_FILE="/etc/smbcred/$CURRENT_USER"
  CA_CERT="/etc/ssl/certs/amkcambodia-AMKDC02-CA.pem"

  export DISPLAY=:0
  export XAUTHORITY="/home/$CURRENT_USER/.Xauthority"

  nmcli dev wifi rescan; sleep 2
  if ! nmcli dev wifi list | grep -q "$TARGET_SSID"; then
    echo "❌ SSID $TARGET_SSID not found" >> "$LOG_FILE"; exit 0
  fi

  if [[ ! -f "$CRED_FILE" ]]; then
    AD_USER=$(zenity --entry --title="Wi-Fi Login" --text="Enter AD Username:")
    AD_PASS=$(zenity --password --title="Wi-Fi Login" --text="Enter AD Password:")
    echo -e "username=\"$AD_USER\"\npassword=\"$AD_PASS\"\ndomain=\"$DOMAIN\"" > "$CRED_FILE"
    chmod 600 "$CRED_FILE"; chown root:root "$CRED_FILE"
  fi

  source "$CRED_FILE"
  IDENTITY="${domain}\\${username}"
  OPEN_CON="open-${TARGET_SSID}-${CURRENT_USER}"

  # Build temporary open profile
  nmcli connection delete "$OPEN_CON" &>/dev/null
  nmcli connection add type wifi ifname "$IFACE" con-name "$OPEN_CON" ssid "$TARGET_SSID" \
    connection.autoconnect no >> "$LOG_FILE"

  nmcli connection up "$OPEN_CON" >> "$LOG_FILE" 2>&1
  sleep 4

  # DNS SRV check
  if ! dig +short SRV "_kerberos._tcp.${DOMAIN}" | grep -q '\.'; then
    echo "❌ DNS SRV lookup failed" >> "$LOG_FILE"
    zenity --error --text="DNS error: cannot resolve domain controller."
    nmcli connection down "$OPEN_CON"; nmcli connection delete "$OPEN_CON"; exit 1
  fi

  echo "$password" | kinit "$username@$REALM" 2> /tmp/kinit_error.log
  if [ $? -ne 0 ]; then
    ERROR_MSG=$(cat /tmp/kinit_error.log)
    if echo "$ERROR_MSG" | grep -qi "expired"; then
      zenity --info --text="Password expired. Please change it."
      sudo -u "$CURRENT_USER" kpasswd "$username@$REALM"
      NEW_PASS=$(zenity --password --text="Enter new password:")
      echo "$NEW_PASS" | kinit "$username@$REALM" || { zenity --error --text="New password failed."; exit 1; }
      sed -i "s/^password=.*/password=\"$NEW_PASS\"/" "$CRED_FILE"
      password="$NEW_PASS"
    else
      zenity --error --text="Auth failed:\n$ERROR_MSG"; exit 1
    fi
  fi

  nmcli connection down "$OPEN_CON"; nmcli connection delete "$OPEN_CON"

  FINAL_CON="${TARGET_SSID}-${CURRENT_USER}"
  if ! nmcli connection show | grep -q "$FINAL_CON"; then
    nmcli connection add type wifi ifname "$IFACE" con-name "$FINAL_CON" ssid "$TARGET_SSID" \
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
    nmcli connection modify "$FINAL_CON" \
      802-1x.identity "$IDENTITY" \
      802-1x.password "$password"
  fi

  echo "✅ Finished AMKBr setup for $CURRENT_USER" >> "$LOG_FILE"
) &

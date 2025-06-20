#!/bin/bash

(
  sleep 10  # Wait for network and session ready

  LOG_FILE="/tmp/amk_wifi_$(logname).log"
  echo "[$(date)] Starting Wi-Fi setup" > "$LOG_FILE"

  TARGET_SSID="AMKBr"
  IFACE=$(nmcli -t device status | grep ':wifi:' | cut -d: -f1)
  USERNAME=$(logname)
  REALM="amkcambodia.com"   # <-- Change this to your AD realm (uppercase)

  CRED_FILE="/etc/smbcred/$USERNAME"
  CA_CERT="/etc/ssl/certs/amkcambodia-AMKDC02-CA.pem"
  # Get the current user
  CURRENT_USER=$(logname)

  # Exclude users sam and root
  if [[ "$CURRENT_USER" == "sam" || "$CURRENT_USER" == "root" ]]; then
    exit 0
  fi

  if [[ -z "$IFACE" ]]; then
    echo "❌ No Wi-Fi interface found." >> "$LOG_FILE"
    exit 1
  fi

  if [[ ! -f "$CRED_FILE" ]]; then
    echo "❌ Credential file not found: $CRED_FILE" >> "$LOG_FILE"
    exit 1
  fi

  source "$CRED_FILE"

  if [[ -z "$username" || -z "$password" ]]; then
    echo "❌ Username or password not defined." >> "$LOG_FILE"
    exit 1
  fi

  # Pre-authentication check using kinit
  echo "$password" | kinit "$username@$REALM" 2> /tmp/kinit_error.log
  if [ $? -ne 0 ]; then
    ERROR_MSG=$(cat /tmp/kinit_error.log)
    echo "⚠️ Kerberos kinit failed: $ERROR_MSG" >> "$LOG_FILE"

    # Check if password expired
    if echo "$ERROR_MSG" | grep -iq "Password has expired"; then
      # Prompt GUI to reset password
      export DISPLAY=:0
      export XAUTHORITY="/home/$USERNAME/.Xauthority"

      zenity --info --title="Password Expired" --text="Your AD password has expired. Please reset it now."

      # Run kpasswd to reset password (interactive GUI)
      sudo -u "$USERNAME" kpasswd "$username@$REALM"

      # After reset, ask for new password
      NEW_PASS=$(sudo -u "$USERNAME" zenity --password --title="New Password" --text="Enter your new AD password:")

      if [[ -z "$NEW_PASS" ]]; then
        zenity --error --text="Password reset cancelled. Cannot continue Wi-Fi connection."
        exit 1
      fi

      password="$NEW_PASS"

      # Try kinit again with new password
      echo "$password" | kinit "$username@$REALM"
      if [ $? -ne 0 ]; then
        zenity --error --text="Password reset failed or invalid password."
        exit 1
      fi

      # Update password in credential file securely
      sed -i "s/^password=.*/password=\"$password\"/" "$CRED_FILE"
      echo "✅ Password updated in credential file" >> "$LOG_FILE"
    else
      zenity --error --text="Authentication failed: $ERROR_MSG"
      exit 1
    fi
  else
    echo "✅ Pre-authentication succeeded" >> "$LOG_FILE"
  fi

  # Compose identity for Wi-Fi profile
  if [[ -n "$domain" ]]; then
    IDENTITY="$domain\\$username"
  else
    IDENTITY="$username"
  fi

  USER_CON_NAME="${TARGET_SSID}-${USERNAME}"

  # Create or update connection profile
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

  # Activate connection if not active
  if nmcli -t -f NAME connection show --active | grep -q "$USER_CON_NAME"; then
    echo "🔌 Connection $USER_CON_NAME already active." >> "$LOG_FILE"
  else
    echo "▶️ Activating connection: $USER_CON_NAME" >> "$LOG_FILE"
    nmcli connection up "$USER_CON_NAME" >> "$LOG_FILE" 2>&1
  fi

  echo "✅ Wi-Fi profile '$USER_CON_NAME' configured for user '$USERNAME'." >> "$LOG_FILE"

) &

# ----
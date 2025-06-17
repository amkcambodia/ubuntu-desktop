#!/bin/bash

USERNAME=$(logname)
USER_REALM=$(realm list | awk '/realm-name/ { print $2 }')
USER_PRINCIPAL="$USERNAME@$USER_REALM"

# Launch a fullscreen dark overlay (simulated blur) in the background
OVERLAY_ID=$(yad --width=100 --height=100 --posx=-1000 --fullscreen --skip-taskbar --undecorated \
  --no-buttons --on-top --borders=0 --window-icon=dialog-password \
  --text="" --timeout=3600 --timeout-indicator=bottom \
  --image="dialog-password" --title="" --background="#000000" & echo $!)

# Wait for overlay to render
sleep 1

# Function to kill the overlay if needed
cleanup_overlay() {
  kill "$OVERLAY_ID" 2>/dev/null
}

# Trap any exit or ctrl+c to clean the overlay
trap cleanup_overlay EXIT

show_error() {
  yad --center --width=400 --window-icon=dialog-error --image=dialog-error \
    --title="Change Password" --text="$1" --button="OK:0"
}

show_success() {
  yad --center --width=400 --window-icon=dialog-information --image=dialog-information \
    --title="Change Password" --text="$1" --button="OK:0"
}

form_password_input() {
  RESULT=$(yad --form --center --width=400 \
    --title="Change Password" --image=dialog-password --window-icon=dialog-password \
    --text="<b>Change your password</b>" \
    --field="Current password:H" \
    --field="New password:H" \
    --field="Confirm new password:H" \
    --button="Change Password:0" --button="Cancel:1")

  if [ $? -ne 0 ]; then exit 1; fi

  CURRENT_PASS=$(echo "$RESULT" | cut -d'|' -f1)
  NEW_PASS=$(echo "$RESULT" | cut -d'|' -f2)
  CONFIRM_PASS=$(echo "$RESULT" | cut -d'|' -f3)
}

validate_and_change_password() {
  # Validate current password
  printf "%s\n" "$CURRENT_PASS" | kinit "$USER_PRINCIPAL" 2>/dev/null
  if [ $? -ne 0 ]; then
    show_error "Current password is incorrect. Please try again."
    return 1
  fi

  if [ "$NEW_PASS" != "$CONFIRM_PASS" ]; then
    show_error "New password and confirmation do not match."
    return 1
  fi

  if [[ ${#NEW_PASS} -lt 8 ]] || ! [[ "$NEW_PASS" =~ [A-Z] ]] || ! [[ "$NEW_PASS" =~ [a-z] ]] || ! [[ "$NEW_PASS" =~ [0-9] ]]; then
    show_error "Your password does not meet the policy:\nMinimum 8 characters, must include uppercase, lowercase, and digits."
    return 1
  fi

  TMP_ERR=$(mktemp)
  printf "%s\n%s\n%s\n" "$CURRENT_PASS" "$NEW_PASS" "$NEW_PASS" | kpasswd "$USER_PRINCIPAL" 2>"$TMP_ERR"
  if [ $? -eq 0 ]; then
    show_success "The password has changed successfully.\nPlease logout and login again to take effect."
  else
    show_error "Failed to change password:\n$(cat "$TMP_ERR")"
  fi
  rm -f "$TMP_ERR"
  kdestroy
}

# Loop until password changed or user cancels
while true; do
  form_password_input
  validate_and_change_password && break
done

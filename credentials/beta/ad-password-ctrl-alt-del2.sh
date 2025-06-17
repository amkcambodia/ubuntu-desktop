#!/bin/bash

USERNAME=$(logname)
USER_REALM=$(realm list | awk '/realm-name/ { print $2 }')
USER_PRINCIPAL="$USERNAME@$USER_REALM"

# Custom function to show error messages
show_error() {
  yad --center --width=400 --image=dialog-error --window-icon=dialog-error \
    --title="Change Password" \
    --text="<span color='red'><b>$1</b></span>" \
    --button="OK:0"
}

# Custom function to show success messages
show_success() {
  yad --center --width=400 --image=dialog-information --window-icon=dialog-information \
    --title="Change Password" \
    --text="<span color='green'><b>$1</b></span>" \
    --button="OK:0"
}

# Function to display the main password change form
form_password_input() {
  RESULT=$(yad --form --center --width=420 --height=260 \
    --title="Change Your Password" \
    --image=dialog-password \
    --text="<span font='12' foreground='white'>Please enter your password information below:</span>" \
    --field="Enter current password:H" \
    --field="Enter new password:H" \
    --field="Confirm new password:H" \
    --borders=20 \
    --button="Change Password:0" --button="Cancel:1" \
    --on-top \
    --window-icon=dialog-password \
    --color="#a53c6f")

  if [ $? -ne 0 ]; then exit 1; fi

  CURRENT_PASS=$(echo "$RESULT" | cut -d'|' -f1)
  NEW_PASS=$(echo "$RESULT" | cut -d'|' -f2)
  CONFIRM_PASS=$(echo "$RESULT" | cut -d'|' -f3)
}

# Validate and attempt to change password
validate_and_change_password() {
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
    show_error "Your password does not meet policy: at least 8 characters, including upper, lower, and digits."
    return 1
  fi

  TMP_ERR=$(mktemp)
  printf "%s\n%s\n%s\n" "$CURRENT_PASS" "$NEW_PASS" "$NEW_PASS" | kpasswd "$USER_PRINCIPAL" 2>"$TMP_ERR"
  if [ $? -eq 0 ]; then
    show_success "The password has changed successfully.\nPlease logout and login again to take effect."
  else
    show_error "Password change failed:\n$(cat "$TMP_ERR")"
  fi
  rm -f "$TMP_ERR"
  kdestroy
}

# Main loop
while true; do
  form_password_input
  validate_and_change_password && break
done

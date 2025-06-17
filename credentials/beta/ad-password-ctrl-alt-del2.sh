#!/bin/bash

USERNAME=$(logname)
USER_REALM=$(realm list | awk '/realm-name/ { print $2 }')
USER_PRINCIPAL="$USERNAME@$USER_REALM"

show_error() {
  yad --width=400 --center --window-icon=dialog-error --image=dialog-error \
    --title="Change Password" --text="$1" --button="OK:0"
}

show_success() {
  yad --width=400 --center --window-icon=dialog-information --image=dialog-information \
    --title="Change Password" --text="$1" --button="OK:0"
}

# Step 1: Prompt all fields in a single form
form_password_input() {
  RESULT=$(yad --form --width=400 --center \
    --title="Change Password" \
    --image=dialog-password --window-icon=dialog-password \
    --text="Please enter your password details:" \
    --field="Current password:H" --field="New password:H" --field="Confirm new password:H" \
    --button="OK:0" --button="Cancel:1")

  if [ $? -ne 0 ]; then
    exit 1
  fi

  CURRENT_PASS=$(echo "$RESULT" | cut -d'|' -f1)
  NEW_PASS=$(echo "$RESULT" | cut -d'|' -f2)
  CONFIRM_PASS=$(echo "$RESULT" | cut -d'|' -f3)
}

validate_and_change_password() {
  # Step 2: Validate current password
  printf "%s\n" "$CURRENT_PASS" | kinit "$USER_PRINCIPAL" 2>/dev/null
  if [ $? -ne 0 ]; then
    show_error "Current password is incorrect. Please try again."
    return 1
  fi

  # Step 3: Validate new password confirmation
  if [ "$NEW_PASS" != "$CONFIRM_PASS" ]; then
    show_error "New password and confirmation do not match."
    return 1
  fi

  # Step 4: Enforce complexity
  if [[ ${#NEW_PASS} -lt 8 ]] ||
     ! [[ "$NEW_PASS" =~ [A-Z] ]] ||
     ! [[ "$NEW_PASS" =~ [a-z] ]] ||
     ! [[ "$NEW_PASS" =~ [0-9] ]]; then
    show_error "Your password does not meet password policy:\nMinimum 8 characters, must include uppercase, lowercase, and digits."
    return 1
  fi

  # Step 5: Change password using kpasswd
  TMP_ERR=$(mktemp)
  printf "%s\n%s\n%s\n" "$CURRENT_PASS" "$NEW_PASS" "$NEW_PASS" | kpasswd "$USER_PRINCIPAL" 2>"$TMP_ERR"
  if [ $? -eq 0 ]; then
    show_success "The password has changed successfully.\nPlease logout and login again to take effect."
  else
    ERROR_MSG=$(cat "$TMP_ERR")
    show_error "Failed to change password:\n$ERROR_MSG"
  fi
  rm -f "$TMP_ERR"
  kdestroy
}

# Main loop: keep prompting until success or cancel
while true; do
  form_password_input
  validate_and_change_password && break
done

#!/bin/bash

USERNAME=$(logname)
USER_REALM=$(realm list | awk '/realm-name/ { print $2 }')
USER_PRINCIPAL="$USERNAME@$USER_REALM"


sudo apt install yad

# Show a nice error box
show_error() {
  yad --width=400 --center --window-icon=dialog-error --image=dialog-error \
    --title="Change Password" --text="$1" --button="OK:0"
}

# Show a nice info box
show_success() {
  yad --width=400 --center --window-icon=dialog-information --image=dialog-information \
    --title="Change Password" --text="$1" --button="OK:0"
}

# Step 1: Prompt for current password and validate it using kinit
prompt_current_password() {
  while true; do
    CURRENT_PASS=$(yad --entry --center --width=400 \
      --title="Change Password" \
      --image=dialog-password --window-icon=dialog-password \
      --text="Please enter your current password:" \
      --entry-placeholder="Enter current password" --hide-text)

    # Cancel button pressed
    if [ $? -ne 0 ]; then exit 1; fi

    if [ -z "$CURRENT_PASS" ]; then
      show_error "Current password is required."
      continue
    fi

    printf "%s\n" "$CURRENT_PASS" | kinit "$USER_PRINCIPAL" 2>/dev/null
    if [ $? -eq 0 ]; then
      break
    else
      show_error "Current password incorrect. Please try again."
    fi
  done
}

# Step 2: Prompt for new password and validate policy
prompt_new_password() {
  while true; do
    NEW_PASS=$(yad --entry --center --width=400 \
      --title="Change Password" \
      --image=dialog-password --window-icon=dialog-password \
      --text="Enter your new password:\n(Minimum 8 characters, with upper/lower case and digits)" \
      --entry-placeholder="Enter new password" --hide-text)

    if [ $? -ne 0 ]; then exit 1; fi
    if [ -z "$NEW_PASS" ]; then
      show_error "New password is required."
      continue
    fi

    CONFIRM_PASS=$(yad --entry --center --width=400 \
      --title="Change Password" \
      --image=dialog-password --window-icon=dialog-password \
      --text="Confirm your new password:" \
      --entry-placeholder="Confirm new password" --hide-text)

    if [ $? -ne 0 ]; then exit 1; fi

    if [ "$NEW_PASS" != "$CONFIRM_PASS" ]; then
      show_error "Passwords do not match. Please try again."
      continue
    fi

    # Password policy check
    if [[ ${#NEW_PASS} -lt 8 ]] ||
       ! [[ "$NEW_PASS" =~ [A-Z] ]] ||
       ! [[ "$NEW_PASS" =~ [a-z] ]] ||
       ! [[ "$NEW_PASS" =~ [0-9] ]]; then
      show_error "Your password does not meet the policy:\nMinimum 8 characters and complexity (upper/lower/digit)."
      continue
    fi

    break
  done
}

# Step 3: Attempt password change
change_password() {
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

# Run
prompt_current_password
prompt_new_password
change_password

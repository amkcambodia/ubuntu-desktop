#!/bin/bash

USERNAME=$(logname)
USER_REALM=$(realm list | awk '/realm-name/ { print $2 }')
USER_PRINCIPAL="$USERNAME@$USER_REALM"

# Function to prompt current password and validate
prompt_current_password() {
  while true; do
    CURRENT_PASS=$(zenity --password \
      --title="Change Password" \
      --text="Enter your current password:")

    if [ -z "$CURRENT_PASS" ]; then
      zenity --error --text="Current password is required."
      continue
    fi

    printf "%s\n" "$CURRENT_PASS" | kinit "$USER_PRINCIPAL" 2>/dev/null
    if [ $? -eq 0 ]; then
      return 0
    else
      zenity --error --title="Authentication Failed" --text="Current password incorrect. Please try again."
    fi
  done
}

# Prompt new password with confirmation and policy check
prompt_new_password() {
  while true; do
    NEW_PASS=$(zenity --password \
      --title="Change Password" \
      --text="Enter your new password (minimum 8 characters with complexity):")

    if [ -z "$NEW_PASS" ]; then
      zenity --error --text="New password is required."
      continue
    fi

    CONFIRM_PASS=$(zenity --password \
      --title="Change Password" \
      --text="Confirm your new password:")

    if [ "$NEW_PASS" != "$CONFIRM_PASS" ]; then
      zenity --error --text="Passwords do not match. Please try again."
      continue
    fi

    # Basic password policy check (8 chars + complexity)
    if ! [[ ${#NEW_PASS} -ge 8 && "$NEW_PASS" =~ [A-Z] && "$NEW_PASS" =~ [a-z] && "$NEW_PASS" =~ [0-9] ]]; then
      zenity --error --text="Your password does not meet the policy: minimum 8 characters, including uppercase, lowercase, and digits."
      continue
    fi

    break
  done
}

# Main flow
prompt_current_password
prompt_new_password

# Change password using kpasswd
printf "%s\n%s\n%s\n" "$CURRENT_PASS" "$NEW_PASS" "$NEW_PASS" | kpasswd "$USER_PRINCIPAL" 2>/tmp/kpasswd_error.log

if [ $? -eq 0 ]; then
  zenity --info --text="The password has changed successfully.\nPlease logout and login again to take effect."
else
  ERROR_MSG=$(cat /tmp/kpasswd_error.log)
  zenity --error --title="Password Change Failed" --text="Failed to change password:\n$ERROR_MSG"
fi

rm -f /tmp/kpasswd_error.log
kdestroy

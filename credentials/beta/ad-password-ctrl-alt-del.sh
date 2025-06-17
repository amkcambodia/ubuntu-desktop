#!/bin/bash

USERNAME=$(logname)
USER_REALM=$(realm list | awk '/realm-name/ { print $2 }')
USER_PRINCIPAL="$USERNAME@$USER_REALM"
sudo apt-get install yad


# Prompt current password and validate
prompt_current_password() {
  while true; do
    CURRENT_PASS=$(yad --entry --title="Change Password" \
      --text="Enter your current password:" \
      --entry-placeholder="Enter current password" --hide-text)

    # User pressed Cancel
    if [ $? -ne 0 ]; then
      exit 1
    fi

    if [ -z "$CURRENT_PASS" ]; then
      yad --error --text="Current password is required."
      continue
    fi

    printf "%s\n" "$CURRENT_PASS" | kinit "$USER_PRINCIPAL" 2>/dev/null
    if [ $? -eq 0 ]; then
      return 0
    else
      yad --error --title="Authentication Failed" --text="Current password incorrect. Please try again."
    fi
  done
}

# Prompt new password with confirmation and policy check
prompt_new_password() {
  while true; do
    NEW_PASS=$(yad --entry --title="Change Password" \
      --text="Enter your new password (minimum 8 chars, uppercase, lowercase, digit):" \
      --entry-placeholder="Enter new password" --hide-text)

    if [ $? -ne 0 ]; then
      exit 1
    fi

    if [ -z "$NEW_PASS" ]; then
      yad --error --text="New password is required."
      continue
    fi

    CONFIRM_PASS=$(yad --entry --title="Change Password" \
      --text="Confirm your new password:" \
      --entry-placeholder="Confirm new password" --hide-text)

    if [ $? -ne 0 ]; then
      exit 1
    fi

    if [ "$NEW_PASS" != "$CONFIRM_PASS" ]; then
      yad --error --text="Passwords do not match. Please try again."
      continue
    fi

    # Password policy check
    if [[ ${#NEW_PASS} -lt 8 ]] ||
       ! [[ "$NEW_PASS" =~ [A-Z] ]] ||
       ! [[ "$NEW_PASS" =~ [a-z] ]] ||
       ! [[ "$NEW_PASS" =~ [0-9] ]]; then
      yad --error --text="Password policy not met:\nMinimum 8 characters, including uppercase, lowercase, and digits."
      continue
    fi

    break
  done
}

# Main flow
prompt_current_password
prompt_new_password

TMP_ERR=$(mktemp)
printf "%s\n%s\n%s\n" "$CURRENT_PASS" "$NEW_PASS" "$NEW_PASS" | kpasswd "$USER_PRINCIPAL" 2>"$TMP_ERR"
if [ $? -eq 0 ]; then
  yad --info --text="Password changed successfully.\nPlease logout and login again to apply changes."
else
  ERROR_MSG=$(cat "$TMP_ERR")
  yad --error --title="Password Change Failed" --text="Failed to change password:\n$ERROR_MSG"
fi
rm -f "$TMP_ERR"
kdestroy

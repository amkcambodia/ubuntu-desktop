#!/bin/bash

# Get the actual logged-in user (not root)
USERNAME=$(logname)
USER_REALM=$(realm list | grep -i realm-name | awk '{print $2}')
USER_PRINCIPAL="$USERNAME@$USER_REALM"

sudo apt install krb5-user
# Ensure script runs as the logged-in user
# Prompt for current password
CURRENT_PASS=$(zenity --password \
    --title="AD Password Change" \
    --text="Enter your current password:")

if [ -z "$CURRENT_PASS" ]; then
    zenity --error --text="Current password is required."
    exit 1
fi

# Validate password with kinit
echo "$CURRENT_PASS" | kinit "$USER_PRINCIPAL" 2>/dev/null
if [ $? -ne 0 ]; then
    zenity --error --title="Authentication Failed" \
        --text="Current password is incorrect or domain not reachable."
    exit 1
fi

# Prompt for new password
NEW_PASS=$(zenity --password \
    --title="New AD Password" \
    --text="Enter your new password:")

if [ -z "$NEW_PASS" ]; then
    zenity --error --text="New password is required."
    exit 1
fi

# Confirm new password
CONFIRM_PASS=$(zenity --password \
    --title="Confirm New Password" \
    --text="Re-enter your new password:")

if [ "$NEW_PASS" != "$CONFIRM_PASS" ]; then
    zenity --error --text="New passwords do not match."
    exit 1
fi

# Run kpasswd using the current Kerberos ticket
echo -e "$CURRENT_PASS\n$NEW_PASS\n$NEW_PASS" | kpasswd "$USER_PRINCIPAL"
if [ $? -eq 0 ]; then
    zenity --info --text="Password changed successfully."
else
    zenity --error --text="Password change failed."
fi

# Optional: destroy Kerberos ticket
kdestroy

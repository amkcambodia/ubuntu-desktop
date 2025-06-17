#!/bin/bash

# === Get the currently logged-in (non-root) username ===
USERNAME=$(logname)

# === Get AD domain from realm ===
USER_REALM=$(realm list | awk '/realm-name/ { print $2 }')

# === Build user principal (e.g., user@DOMAIN.COM) ===
USER_PRINCIPAL="$USERNAME@$USER_REALM"

# === Prompt for current password ===
CURRENT_PASS=$(zenity --password \
    --title="AD Password Change" \
    --text="Enter your current password:")

if [ -z "$CURRENT_PASS" ]; then
    zenity --error --text="Current password is required."
    exit 1
fi

# === Authenticate user using Kerberos (kinit) ===
printf "%s\n" "$CURRENT_PASS" | kinit "$USER_PRINCIPAL" 2>/dev/null

if [ $? -ne 0 ]; then
    zenity --error --title="Authentication Failed" \
        --text="Current password is incorrect or domain is unreachable."
    exit 1
fi

# === Prompt for new password ===
NEW_PASS=$(zenity --password \
    --title="New AD Password" \
    --text="Enter your new password:")

if [ -z "$NEW_PASS" ]; then
    zenity --error --text="New password is required."
    exit 1
fi

# === Confirm new password ===
CONFIRM_PASS=$(zenity --password \
    --title="Confirm New Password" \
    --text="Re-enter your new password:")

if [ "$NEW_PASS" != "$CONFIRM_PASS" ]; then
    zenity --error --text="New passwords do not match."
    exit 1
fi

# === Run kpasswd to change password using Kerberos ticket ===
printf "%s\n%s\n%s\n" "$CURRENT_PASS" "$NEW_PASS" "$NEW_PASS" | kpasswd "$USER_PRINCIPAL" 2>/tmp/kpasswd_error.log

if [ $? -eq 0 ]; then
    zenity --info --text="✅ Password changed successfully."
else
    zenity --error --title="Password Change Failed" \
        --text="An error occurred while changing the password.\n\n$(cat /tmp/kpasswd_error.log)"
    rm -f /tmp/kpasswd_error.log
    exit 1
fi

# === Clean up Kerberos ticket for security ===
kdestroy

# === Remove temporary error log ===
rm -f /tmp/kpasswd_error.log

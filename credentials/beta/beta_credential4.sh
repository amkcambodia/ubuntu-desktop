#!/bin/bash

USERNAME=$(logname)

# Exclude local accounts
excluded_users=("sam")
for u in "${excluded_users[@]}"; do
    if [ "$USERNAME" == "$u" ]; then
        echo "User $USERNAME is excluded from password change."
        exit 0
    fi
done

# Prompt for old password
old_pass=$(zenity --password --title="Change Password" --text="Enter your current AD password:")
[ -z "$old_pass" ] && zenity --error --text="❌ No password entered." && exit 1

# Prompt for new password
new_pass=$(zenity --password --title="Change Password" --text="Enter new password:")
[ -z "$new_pass" ] && zenity --error --text="❌ No new password entered." && exit 1

# Confirm new password
confirm_pass=$(zenity --password --title="Change Password" --text="Confirm new password:")
[ "$new_pass" != "$confirm_pass" ] && zenity --error --text="❌ Passwords do not match." && exit 1

# Change password using expect
expect <<EOF
spawn passwd "$USERNAME"
expect "Current password:"
send "$old_pass\r"
expect "New password:"
send "$new_pass\r"
expect "Retype new password:"
send "$new_pass\r"
expect eof
EOF

# Check success
# shellcheck disable=SC2181
if [ $? -eq 0 ]; then
    zenity --info --text="✅ Password changed successfully."
else
    zenity --error --text="❌ Failed to change password."
fi

#!/bin/bash

# 🔐 Backup PAM files before modifying
sudo cp /etc/pam.d/common-auth /etc/pam.d/common-auth.bak
sudo cp /etc/pam.d/common-password /etc/pam.d/common-password.bak
sudo cp /etc/pam.d/common-session /etc/pam.d/common-session.bak

echo "✅ Backed up PAM config files to *.bak"

# ✅ Enable pam_sss for authentication
if ! grep -q '^auth[[:space:]]\+sufficient[[:space:]]\+pam_sss.so' /etc/pam.d/common-auth; then
    echo 'auth    sufficient    pam_sss.so' | sudo tee -a /etc/pam.d/common-auth > /dev/null
    echo "✅ Added pam_sss to common-auth"
else
    echo "ℹ️ pam_sss already present in common-auth"
fi

# ✅ Enable password change for expired AD accounts
if ! grep -q '^password[[:space:]]\+\[success=1 default=ignore\][[:space:]]\+pam_sss.so' /etc/pam.d/common-password; then
    echo 'password   [success=1 default=ignore]   pam_sss.so use_authtok' | sudo tee -a /etc/pam.d/common-password > /dev/null
    echo "✅ Added pam_sss to common-password"
else
    echo "ℹ️ pam_sss already present in common-password"
fi

# ✅ Enable home directory creation
if ! grep -q '^session[[:space:]]\+required[[:space:]]\+pam_mkhomedir.so' /etc/pam.d/common-session; then
    echo 'session required pam_mkhomedir.so skel=/etc/skel umask=0022' | sudo tee -a /etc/pam.d/common-session > /dev/null
    echo "✅ Added pam_mkhomedir to common-session"
else
    echo "ℹ️ pam_mkhomedir already present in common-session"
fi

# ✅ Add pam_exec to common-session for GUI expired password notification
if ! grep -q 'pam_exec.so.*/usr/local/lib/pam-notify/expired-password-gui.sh' /etc/pam.d/common-session; then
    echo 'session optional pam_exec.so quiet expose_authtok /usr/local/lib/pam-notify/expired-password-gui.sh' | sudo tee -a /etc/pam.d/common-session > /dev/null
    echo "✅ Added pam_exec to common-session for expired password GUI prompt"
else
    echo "ℹ️ pam_exec already present in common-session"
fi

# 📁 Create expired-password-gui script
sudo mkdir -p /usr/local/lib/pam-notify
cat << 'EOF' | sudo tee /usr/local/lib/pam-notify/expired-password-gui.sh > /dev/null
#!/bin/bash

MARKER_EXPIRED="/tmp/.password_expired_$PAM_USER"
MARKER_SAVED_PROMPT="/tmp/.password_save_prompt_$PAM_USER"
SMBCRED_FILE="/home/$PAM_USER/.smbcred"
DOMAIN="amkcambodia.com"

# Only run in GUI session
if [ "$XDG_SESSION_TYPE" != "x11" ] && [ "$XDG_SESSION_TYPE" != "wayland" ]; then
    exit 0
fi

# 🔁 Check for expired password (non-interactive check)
if echo "" | kinit "$PAM_USER@$DOMAIN" 2>&1 | grep -q "Password has expired"; then
    if [ ! -f "$MARKER_EXPIRED" ]; then
        export DISPLAY=:0
        sudo -u "$PAM_USER" zenity --error --text="🔐 Your AD password has expired. A terminal will open for you to change it."

        # Launch terminal for password change using kpasswd
        sudo -u "$PAM_USER" gnome-terminal -- bash -c "echo 'Change your password below:'; kpasswd $PAM_USER@$DOMAIN; echo 'Press Enter to close...'; read"

        touch "$MARKER_EXPIRED"
    fi
else
    # ✅ Password was changed
    if [ -f "$MARKER_EXPIRED" ]; then
        export DISPLAY=:0
        sudo -u "$PAM_USER" zenity --info --text="✅ Your AD password has been changed successfully."

        if [ ! -f "$MARKER_SAVED_PROMPT" ]; then
            NEW_PASS=$(sudo -u "$PAM_USER" DISPLAY=:0 zenity --password --title="Save New Password" --text="🔐 Enter your new AD password:")

            if [ -n "$NEW_PASS" ]; then
                echo -e "domain = $DOMAIN\nusername = $PAM_USER\npassword = $NEW_PASS" | sudo -u "$PAM_USER" tee "$SMBCRED_FILE" > /dev/null
                sudo chmod 600 "$SMBCRED_FILE"
                sudo chown "$PAM_USER:$PAM_USER" "$SMBCRED_FILE"
                sudo -u "$PAM_USER" zenity --info --text="🔐 Password saved."
            else
                sudo -u "$PAM_USER" zenity --warning --text="⚠️ No password entered. Password not saved."
            fi

            touch "$MARKER_SAVED_PROMPT"
        fi

        # Final instruction message
        sudo -u "$PAM_USER" zenity --info --text="🔁 Please press Ctrl+Alt+F1 to return to the login screen and log in with your new password."

        rm -f "$MARKER_EXPIRED"
    fi
fi
EOF
sudo chmod +x /usr/local/lib/pam-notify/expired-password-gui.sh
sudo chmod 644 /usr/local/lib/pam-notify/expired-password-gui.sh

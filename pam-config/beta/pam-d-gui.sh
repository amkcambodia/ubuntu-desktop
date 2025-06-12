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

# 📁 Create expired-password-gui script
sudo mkdir -p /usr/local/lib/pam-notify

cat << 'EOF' | sudo tee /usr/local/lib/pam-notify/expired-password-gui.sh > /dev/null
#!/bin/bash

MARKER="/tmp/.password_expired_$PAM_USER"

# Only run in GUI session
if [ "$XDG_SESSION_TYPE" != "x11" ] && [ "$XDG_SESSION_TYPE" != "wayland" ]; then
    exit 0
fi

# Try kinit silently
if kinit "$PAM_USER@AMKCAMBODIA.COM" -k -t /tmp/dummy.keytab 2>&1 | grep -q "Client not found"; then
    # fall back to standard test if keytab not set up
    true
fi

# Check if password expired
if kinit "$PAM_USER@AMKCAMBODIA.COM" 2>&1 | grep -q "Password has expired"; then
    if [ ! -f "$MARKER" ]; then
        export DISPLAY=:0
        sudo -u "$PAM_USER" zenity --error --text="🔐 Your AD password has expired. Press Ctrl+Alt+F3 to change it."
        touch "$MARKER"
    fi
else
    # Password not expired, clear marker if it exists
    [ -f "$MARKER" ] && rm -f "$MARKER"
fi
EOF

sudo chmod +x /usr/local/lib/pam-notify/expired-password-gui.sh
echo "✅ Installed expired-password-gui.sh"

# ✅ Add pam_exec to common-session for GUI expired password notification
if ! grep -q 'pam_exec.so.*/usr/local/lib/pam-notify/expired-password-gui.sh' /etc/pam.d/common-session; then
    echo 'session optional pam_exec.so quiet expose_authtok /usr/local/lib/pam-notify/expired-password-gui.sh' | sudo tee -a /etc/pam.d/common-session > /dev/null
    echo "✅ Added pam_exec to common-session for expired password GUI prompt"
else
    echo "ℹ️ pam_exec already present in common-session"
fi

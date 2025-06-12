# Enable pam_sss for authentication
if ! grep -q '^auth[[:space:]]\+sufficient[[:space:]]\+pam_sss.so' /etc/pam.d/common-auth; then
    echo 'auth    sufficient    pam_sss.so' | sudo tee -a /etc/pam.d/common-auth > /dev/null
    echo "✅ Added pam_sss to common-auth"
else
    echo "ℹ️ pam_sss already present in common-auth"
fi

# Enable password change for expired AD accounts
if ! grep -q '^password[[:space:]]\+\[success=1 default=ignore\][[:space:]]\+pam_sss.so' /etc/pam.d/common-password; then
    echo 'password   [success=1 default=ignore]   pam_sss.so use_authtok' | sudo tee -a /etc/pam.d/common-password > /dev/null
    echo "✅ Added pam_sss to common-password"
else
    echo "ℹ️ pam_sss already present in common-password"
fi

# Enable home directory creation
if ! grep -q '^session[[:space:]]\+required[[:space:]]\+pam_mkhomedir.so' /etc/pam.d/common-session; then
    echo 'session required pam_mkhomedir.so skel=/etc/skel umask=0022' | sudo tee -a /etc/pam.d/common-session > /dev/null
    echo "✅ Added pam_mkhomedir to common-session"
else
    echo "ℹ️ pam_mkhomedir already present in common-session"
fi

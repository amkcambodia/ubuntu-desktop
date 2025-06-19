#!/bin/bash

# ----------------------------------------------------------------

PAM_FILE="/etc/pam.d/common-session"
PAM_EXEC_PROFILE='session optional pam_exec.so /usr/local/bin/fix_dconf_profile.sh'

# Check if line already exists
if ! grep -Fxq "$PAM_EXEC_PROFILE" "$PAM_FILE"; then
    echo "$PAM_EXEC_PROFILE" | sudo tee -a "$PAM_FILE" > /dev/null
    echo "✅ Added to $PAM_FILE: $PAM_EXEC_PROFILE"
else
    echo "ℹ️ Already present in $PAM_FILE"
fi


# ----------------------------------------------------------------

# ✅ Enable home directory creation
if ! grep -q '^session[[:space:]]\+required[[:space:]]\+pam_mkhomedir.so' /etc/pam.d/common-session; then
    echo 'session required pam_mkhomedir.so skel=/etc/skel umask=0022' | sudo tee -a /etc/pam.d/common-session > /dev/null
    echo "✅ Added pam_mkhomedir to common-session"
else
    echo "ℹ️ pam_mkhomedir already present in common-session"
fi

# ----------------------------------------------------------------

# ✅ Add pam_exec to common-session for GUI expired password notification

if ! grep -q 'session optional pam_exec.so quiet expose_authtok' /etc/pam.d/common-session; then
    echo 'session optional pam_exec.so quiet expose_authtok' | sudo tee -a /etc/pam.d/common-session > /dev/null
    echo "✅ Added pam_exec to common-session for expired password GUI prompt"
else
    echo "ℹ️ pam_exec already present in common-session"
fi

# ----------------------------------------------------------------

PAM_EXEC_LINE="session optional pam_exec.so /usr/local/bin/amk/autostart-prompt.sh"
PAM_D_FILE="/etc/pam.d/common-session"

# Check if any pam_exec.so line exists
if grep -q "^session optional pam_exec.so" "$PAM_D_FILE"; then
  echo "✅ A pam_exec.so line already exists in $PAM_D_FILE — skipping."
else
  echo "$PAM_EXEC_LINE" >> "$PAM_D_FILE"
  echo "✅ Added pam_exec.so line to $PAM_D_FILE"
fi

# ----------------------------------------------------------------
# Check if running as root
if [[ $EUID -ne 0 ]]; then
  echo "❌ Please run this script as root (e.g., sudo)."
  exit 1
fi

# ----------------------------------------------------------------

#!/bin/bash


# ----------------------------------------------------------------

# ✅ Enable password change for expired AD accounts
if ! grep -q '^password[[:space:]]\+\[success=1 default=ignore\][[:space:]]\+pam_sss.so' /etc/pam.d/common-password; then
    echo 'password   [success=1 default=ignore]   pam_sss.so use_authtok' | sudo tee -a /etc/pam.d/common-password > /dev/null
    echo "✅ Added pam_sss to common-password"
else
    echo "ℹ️ pam_sss already present in common-password"
fi

# ----------------------------------------------------------------


# ----------------------------------------------------------------
# Check if running as root
if [[ $EUID -ne 0 ]]; then
  echo "❌ Please run this script as root (e.g., sudo)."
  exit 1
fi

# ----------------------------------------------------------------

#!/bin/bash

# ----------------------------------------------------------------

echo "✅ Backed up PAM config files to *.bak"

# ✅ Enable pam_sss for authentication
if ! grep -q '^auth[[:space:]]\+sufficient[[:space:]]\+pam_sss.so' /etc/pam.d/common-auth; then
    echo 'auth    sufficient    pam_sss.so' | sudo tee -a /etc/pam.d/common-auth > /dev/null
    echo "✅ Added pam_sss to common-auth"
else
    echo "ℹ️ pam_sss already present in common-auth"
fi

# ----------------------------------------------------------------
# Check if running as root
if [[ $EUID -ne 0 ]]; then
  echo "❌ Please run this script as root (e.g., sudo)."
  exit 1
fi

# ----------------------------------------------------------------




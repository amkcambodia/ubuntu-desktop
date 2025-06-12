# #!/bin/bash

# COMMON_AUTH="/etc/pam.d/common-auth"
# PAM_LINE='auth    [success=1 default=ignore] pam_localuser.so'

# echo "[*] Checking $COMMON_AUTH..."

# # Add the pam_localuser.so line at the top if it's not already present
# if ! grep -Fxq "$PAM_LINE" "$COMMON_AUTH"; then
#     echo "[+] Adding pam_localuser.so to allow local user login"
#     sudo sed -i "1i $PAM_LINE" "$COMMON_AUTH"
# else
#     echo "[-] pam_localuser.so already exists in $COMMON_AUTH"
# fi

# echo "[✔] PAM patch complete."

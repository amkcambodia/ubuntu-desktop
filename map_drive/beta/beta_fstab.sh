#!/bin/bash

# Define all three fstab lines
fstab_entries=(
"//amkcambodia.com/amkdfs /media/%u/Collaboration-Q cifs credentials=/etc/smbcred/%u,uid=%U,gid=%G,prefixpath=Collaboration,sec=ntlmssp,vers=3.0,user,noauto 0 0"
"//amkcambodia.com/amkdfs /media/%u/Department-N cifs credentials=/etc/smbcred/%u,uid=%U,gid=%G,prefixpath=Dept_Doc/CIO/ITI,sec=ntlmssp,vers=3.0,user,noauto 0 0"
"//amkcambodia.com/amkdfs /media/%u/Home-H cifs credentials=/etc/smbcred/%u,uid=%U,gid=%G,prefixpath=StaffDoc/ITD/%u,sec=ntlmssp,vers=3.0,user,noauto 0 0"
)

for FSTAB_LINE in "${fstab_entries[@]}"; do
    if ! grep -Fxq "$FSTAB_LINE" /etc/fstab; then
        echo "$FSTAB_LINE" | sudo tee -a /etc/fstab > /dev/null
        echo "✅ Added fstab entry: $FSTAB_LINE"
    else
        echo "ℹ️ Entry already exists: $FSTAB_LINE"
    fi
done

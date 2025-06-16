#!/bin/bash
#
## Define all three fstab lines
#fstab_entries=(
#"//amkcambodia.com/amkdfs /media/$logname/Collaboration-Q cifs credentials=/etc/smbcred/$logname,uid=%U,gid=%G,prefixpath=Collaboration,sec=ntlmssp,vers=3.0,user,noauto 0 0"
#"//amkcambodia.com/amkdfs /media/$logname/Department-N cifs credentials=/etc/smbcred/$logname,uid=%U,gid=%G,prefixpath=Dept_Doc/CIO/ITI,sec=ntlmssp,vers=3.0,user,noauto 0 0"
#"//amkcambodia.com/amkdfs /media/$logname/Home-H cifs credentials=/etc/smbcred/$logname,uid=%U,gid=%G,prefixpath=StaffDoc/ITD/%u,sec=ntlmssp,vers=3.0,user,noauto 0 0"
#)
#
#for FSTAB_LINE in "${fstab_entries[@]}"; do
#    if ! grep -Fxq "$FSTAB_LINE" /etc/fstab; then
#        echo "$FSTAB_LINE" | sudo tee -a /etc/fstab > /dev/null
#        echo "✅ Added fstab entry: $FSTAB_LINE"
#    else
#        echo "ℹ️ Entry already exists: $FSTAB_LINE"
#    fi
#done
#


# Ensure script runs as root
if [[ $EUID -ne 0 ]]; then
  echo "❌ This script must be run as root."
  exit 1
fi

USERNAME=$(logname)
USER_ID=$(id -u "$USERNAME")
GROUP_ID=$(id -g "$USERNAME")
CREDENTIALS_FILE="/etc/smbcred/$USERNAME"

SERVER="amkcambodia.com"
DFS_ROOT="amkdfs"

COLLAB_PREFIXPATH="Collaboration"
DEPT_PREFIXPATH="Dept_Doc/CIO/ITI"
HOME_PREFIXPATH="StaffDoc/ITD/$USERNAME"

MEDIA="/media/$USERNAME"
COLLAB_MOUNTPOINT="$MEDIA/Collaboration-Q"
DEPT_MOUNTPOINT="$MEDIA/Department-N"
HOME_MOUNTPOINT="$MEDIA/Home-H"

fstab_entries=(
"//$SERVER/$DFS_ROOT/$COLLAB_PREFIXPATH /media/%u/Collaboration-Q cifs credentials=/etc/smbcred/%u,uid=%U,gid=%g,sec=ntlmssp,vers=3.0,user,noauto 0 0"
"//$SERVER/$DFS_ROOT/$DEPT_PREFIXPATH /media/%u/Department-N cifs credentials=/etc/smbcred/%u,uid=%U,gid=%g,sec=ntlmssp,vers=3.0,user,noauto 0 0"
"//$SERVER/$DFS_ROOT/$HOME_PREFIXPATH /media/%u/Home-H cifs credentials=/etc/smbcred/%u,uid=%U,gid=%g,sec=ntlmssp,vers=3.0,user,noauto 0 0"
)

for FSTAB_LINE in "${fstab_entries[@]}"; do
    if ! grep -Fq "$FSTAB_LINE" /etc/fstab; then
        echo "$FSTAB_LINE" | tee -a /etc/fstab > /dev/null
        echo "✅ Added fstab entry: $FSTAB_LINE"
    else
        echo "ℹ️ Entry already exists: $FSTAB_LINE"
    fi
done


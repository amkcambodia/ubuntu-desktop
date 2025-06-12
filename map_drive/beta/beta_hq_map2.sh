#!/bin/bash


# # /etc/fstab
# //amkcambodia.com/amkdfs /media/Collaboration-Q cifs credentials=/etc/smbcred/$USERNAME,uid=1000,gid=1000,prefixpath=Collaboration,sec=ntlmssp,vers=3.0,user 0 0
# //amkcambodia.com/amkdfs /media/Department-N    cifs credentials=/etc/smbcred/$USERNAME,uid=1000,gid=1000,prefixpath=Dept_Doc/CIO/ITI,sec=ntlmssp,vers=3.0,user 0 0
# //amkcambodia.com/amkdfs /media/Home-H          cifs credentials=/etc/smbcred/$USERNAME,uid=1000,gid=1000,prefixpath=StaffDoc/ITD/$USERNAME,sec=ntlmssp,vers=3.0,user 0 0

# mount.cifs "//amkcambodia.com/amkdfs" "/media/savi.toy/Collaboration-Q" \
#   -o credentials="/etc/smbcred/savi.toy",prefixpath="Collaboration/AHO/ITI",sec=ntlmssp,uid="savi.toy",gid="domain users",vers=3.0



#-------------------------------------------------------

USERNAME=$(logname)
USER_ID=$(id -u "$USERNAME")
# GROUP_ID=$(id -g "$USERNAME")
GROUP_ID="root"
CREDENTIALS_FILE="/etc/smbcred/$USERNAME"

# # Only run if credentials file exists
# if [ ! -f "$CREDENTIALS_FILE" ]; then
#     echo "Credentials file not found for $USERNAME"
#     exit 1
# fi

# If credentials file does not exist, run the creation script
if [ ! -f "$CREDENTIALS_FILE" ]; then
    echo "Credentials file not found for $USERNAME"
    echo "Running smbcred.sh to create it..."
    
    /bin/amk/smbcred.sh "$USERNAME"

    # Recheck if it was successfully created
    if [ ! -f "$CREDENTIALS_FILE" ]; then
        echo "❌ Failed to create credentials file."
        exit 1
    else
        echo "✅ Credentials file created."
    fi
fi

#-------------------------------------------------------

SERVER="amkcambodia.com"
DFS_ROOT="amkdfs"

# DFS sub-paths
COLLAB_PREFIXPATH="Collaboration"
DEPT_PREFIXPATH="Dept_Doc/CIO/ITI"
HOME_PREFIXPATH="StaffDoc/ITD/$USERNAME"

# Mount points
COLLAB_MOUNTPOINT="/media/$USERNAME/Collaboration-Q"
DEPT_MOUNTPOINT="/media/$USERNAME/Department-N"
HOME_MOUNTPOINT="/media/$USERNAME/Home-H"
MEDIA="/media/$USERNAME"

#-------------------------------------------------------

mkdir -p  "$MEDIA" "$COLLAB_MOUNTPOINT" "$DEPT_MOUNTPOINT" "$HOME_MOUNTPOINT"
chown "$USERNAME:$GROUP_ID" "$MEDIA" "$COLLAB_MOUNTPOINT" "$DEPT_MOUNTPOINT" "$HOME_MOUNTPOINT"

chmod 700 "$MEDIA" "$COLLAB_MOUNTPOINT" "$DEPT_MOUNTPOINT" "$HOME_MOUNTPOINT"

#-------------------------------------------------------

# # Mount using user context (no sudo)

# mount.cifs "//$SERVER/$DFS_ROOT/$COLLAB_PREFIXPATH" "$COLLAB_MOUNTPOINT" \
#   -o credentials="$CREDENTIALS_FILE",sec=ntlmssp,uid="$USER_ID",gid="$GROUP_ID",vers=3.0,user

# mount.cifs "//$SERVER/$DFS_ROOT/$DEPT_PREFIXPATH" "$DEPT_MOUNTPOINT" \
#   -o credentials="$CREDENTIALS_FILE",sec=ntlmssp,uid="$USER_ID",gid="$GROUP_ID",vers=3.0,user

# mount.cifs "//$SERVER/$DFS_ROOT/$HOME_PREFIXPATH" "$HOME_MOUNTPOINT" \
#   -o credentials="$CREDENTIALS_FILE",sec=ntlmssp,uid="$USER_ID",gid="$GROUP_ID",vers=3.0,user

#-------------------------------------------------------

#echo "🔗 Attempting to mount Collaboration-Q..."
if mount.cifs "//$SERVER/$DFS_ROOT/$COLLAB_PREFIXPATH" "$COLLAB_MOUNTPOINT" \
  -o credentials="$CREDENTIALS_FILE",sec=ntlmssp,uid="$USER_ID",gid="$GROUP_ID",vers=3.0,user; then
    echo "✅ Collaboration-Q mounted at $COLLAB_MOUNTPOINT"
else
    echo "❌ Failed to mount $COLLAB_MOUNTPOINT"
fi

#echo "🔗 Attempting to mount Department-N..."
if mount.cifs "//$SERVER/$DFS_ROOT/$DEPT_PREFIXPATH" "$DEPT_MOUNTPOINT" \
  -o credentials="$CREDENTIALS_FILE",sec=ntlmssp,uid="$USER_ID",gid="$GROUP_ID",vers=3.0,user; then
    echo "✅ Department-N mounted at $COLLAB_MOUNTPOINT"
else
    echo "❌ Failed to mount $COLLAB_MOUNTPOINT"
fi

#echo "🔗 Attempting to mount Home-H..."
if mount.cifs "//$SERVER/$DFS_ROOT/$HOME_PREFIXPATH" "$HOME_MOUNTPOINT" \
  -o credentials="$CREDENTIALS_FILE",sec=ntlmssp,uid="$USER_ID",gid="$GROUP_ID",vers=3.0,user; then
    echo "✅ Home-H mounted at $HOME_MOUNTPOINT"
else
    echo "❌ Failed to $HOME_MOUNTPOINT"
fi

#!/bin/bash

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
## SMB Shared Server

SERVER="amkcambodia.com"
SERVER1="amkcrm1"
SERVER2="ho-databackup"
DFS_ROOT="amkdfs"

# DFS sub-paths
COLLAB_PREFIXPATH="Collaboration-Q"
CUD_PREFIXPATH="CUD-U"
BPR_PREFIXPATH="Branch"

COLLAB_MOUNTPOINT="/media/$USERNAME/Collaboration-Q"
CUD_MOUNTPOINT="/media/$USERNAME/CUD-U"
BPR_MOUNTPOINT="/media/$USERNAME/Branch_Post_Report-P"
MEDIA="/media/$USERNAME"

#-------------------------------------------------------

## Directory and permission requirements

mkdir -p  "$MEDIA" "$COLLAB_MOUNTPOINT" "$CUD_MOUNTPOINT" "$BPR_MOUNTPOINT"

chown "$USERNAME:$GROUP_ID" "$MEDIA" "$COLLAB_MOUNTPOINT" "$CUD_MOUNTPOINT" "$BPR_MOUNTPOINT"

chmod 700 "$MEDIA" "$MEDIA" "$COLLAB_MOUNTPOINT" "$CUD_MOUNTPOINT" "$BPR_MOUNTPOINT"

#-------------------------------------------------------
### -------------------

# mount -t cifs "//$SERVER/\$BRANCHS_COLLAB_SHARE_PATH" "\$COLLAB_MOUNTPOINT" \\
#   -o credentials=$CREDENTIALS_FILE,sec=ntlmssp,uid=\$(id -u),gid=\$(id -g),vers=3.0

# mount -t cifs "//$SERVER1/\$BRANCHS_CUD_SHARE_PATH" "\$CUD_MOUNTPOINT" \\
#   -o credentials=$CREDENTIALS_FILE,sec=ntlmssp,uid=\$(id -u),gid=\$(id -g),vers=3.0

# mount -t cifs "//$SERVER2/\$BRANCHS_BPR_SHARE_PATH" "\$BPR_MOUNTPOINT" \\
#   -o credentials=$CREDENTIALS_FILE,sec=ntlmssp,uid=\$(id -u),gid=\$(id -g),vers=3.0

# mountpoint -q "\$COLLAB_MOUNTPOINT" && echo "✅ Collaboration mounted at \$COLLAB_MOUNTPOINT" || echo "❌ Collaboration mount failed"
# mountpoint -q "\$CUD_MOUNTPOINT" && echo "✅ CUD mounted at \$CUD_MOUNTPOINT" || echo "❌ CUD mount failed"
# mountpoint -q "\$BPR_MOUNTPOINT" && echo "✅ Branch Post Report mounted at \$BPR_MOUNTPOINT" || echo "❌ Branch Post Report mount failed"

#-------------------------------------------------------

# Mount using user context (no sudo)

### Mount Collaboration-Q
if mount.cifs "//$SERVER/$DFS_ROOT/$COLLAB_PREFIXPATH" "$COLLAB_MOUNTPOINT" \
  -o credentials="$CREDENTIALS_FILE",sec=ntlmssp,uid="$USER_ID",gid="$GROUP_ID",vers=3.0,user; then
    echo "✅ Collaboration-Q mounted at $COLLAB_MOUNTPOINT"
else
    echo "❌ Failed to mount $COLLAB_MOUNTPOINT"
fi

### Mount CUD-U
if mount.cifs "//$SERVER1/$CUD_MOUNTPOINT" "$CUD_MOUNTPOINT" \
  -o credentials="$CREDENTIALS_FILE",sec=ntlmssp,uid="$USER_ID",gid="$GROUP_ID",vers=3.0,user; then
    echo "✅ Department-N mounted at $CUD_MOUNTPOINT"
else
    echo "❌ Failed to mount $CUD_MOUNTPOINT"
fi

### Mount Branch_Post_Report-P
echo "🔗 Attempting to mount Home-H..."
if mount.cifs "//$SERVER2/$BPR_PREFIXPATH" "$BPR_MOUNTPOINT" \
  -o credentials="$CREDENTIALS_FILE",sec=ntlmssp,uid="$USER_ID",gid="$GROUP_ID",vers=3.0,user; then
    echo "✅ Home-H mounted at $BPR_MOUNTPOINT"
else
    echo "❌ Failed to $BPR_MOUNTPOINT"
fi

#-------------------------------------------------------


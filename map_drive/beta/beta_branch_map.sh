#!/bin/bash

#-------------------------------------------------------

USERNAME=$(logname)
USER_ID=$(id -u "$USERNAME")
# GROUP_ID=$(id -g "$USERNAME")
GROUP_ID="root"
CREDENTIALS_FILE="/etc/smbcred/$USERNAME"

# -------------------------------------------------------
# Retry mount
DOMAIN="amkcambodia.com"
MAX_TRIES=10
RETRY_INTERVAL=5  # seconds

echo "⏳ Waiting for domain $DOMAIN to be resolvable..."

for i in $(seq 1 $MAX_TRIES); do
    if host "$DOMAIN" > /dev/null 2>&1; then
        echo "✅ Domain $DOMAIN is resolvable."
        break
    else
        echo "🔁 Retry $i/$MAX_TRIES: Domain not yet resolvable. Waiting $RETRY_INTERVAL seconds..."
        sleep $RETRY_INTERVAL
    fi
done

# Final check after retries
if ! host "$DOMAIN" > /dev/null 2>&1; then
    echo "❌ Domain $DOMAIN not resolvable after $((MAX_TRIES * RETRY_INTERVAL)) seconds."
    exit 1
fi

#-------------------------------------------------------
## SMB Shared Server

SERVER="amkcambodia.com"
SERVER1="amkcrm1.amkcambodia.com"
SERVER2="ho-databackup.amkcambodia.com"
DFS_ROOT="amkdfs"

# DFS sub-paths
COLLAB_PREFIXPATH="Collaboration-Q"
CUD_PREFIXPATH="CUD-U"
BPR_PREFIXPATH="Branch"

MEDIA="/media/$USERNAME"
COLLAB_MOUNTPOINT="/media/$USERNAME/Collaboration-Q"
CUD_MOUNTPOINT="/media/$USERNAME/CUD-U"
BPR_MOUNTPOINT="/media/$USERNAME/Branch_Post_Report-P"


#-------------------------------------------------------

## Directory and permission requirements

mkdir -p  "$MEDIA" "$COLLAB_MOUNTPOINT" "$CUD_MOUNTPOINT" "$BPR_MOUNTPOINT"

chown "$USERNAME:$GROUP_ID" "$MEDIA" "$COLLAB_MOUNTPOINT" "$CUD_MOUNTPOINT" "$BPR_MOUNTPOINT"

chmod 700 "$MEDIA" "$COLLAB_MOUNTPOINT" "$CUD_MOUNTPOINT" "$BPR_MOUNTPOINT"

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

if mount.cifs "//$SERVER2/$BPR_PREFIXPATH" "$BPR_MOUNTPOINT" \
  -o credentials="$CREDENTIALS_FILE",sec=ntlmssp,uid="$USER_ID",gid="$GROUP_ID",vers=3.0,user; then
    echo "✅ Branch_Post_Report-P mounted at $BPR_MOUNTPOINT"
else
    echo "❌ Failed to $BPR_MOUNTPOINT"
fi

#-------------------------------------------------------
#

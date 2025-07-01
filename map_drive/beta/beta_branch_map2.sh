#!/bin/bash

set -euo pipefail

#-------------------------------------------------------
# Constants

INTERNAL_DNS="192.168.103.219"
DOMAIN="amkcambodia.com"
MAX_TRIES=10
RETRY_INTERVAL=5

USERNAME=$(logname)
USER_ID=$(id -u "$USERNAME")
GROUP_ID=$(id -g "$USERNAME")
CREDENTIALS_FILE="/etc/smbcred/$USERNAME"

#-------------------------------------------------------
# Wait for internal DNS resolution (domain up)

echo "⏳ Waiting for internal DNS resolution of $DOMAIN..."

for i in $(seq 1 $MAX_TRIES); do
    if host "$DOMAIN" "$INTERNAL_DNS" > /dev/null 2>&1; then
        echo "✅ Domain $DOMAIN is resolvable via $INTERNAL_DNS."
        break
    else
        echo "🔁 Retry $i/$MAX_TRIES: Still waiting for DNS response from $INTERNAL_DNS..."
        sleep $RETRY_INTERVAL
    fi
done

if ! host "$DOMAIN" "$INTERNAL_DNS" > /dev/null 2>&1; then
    echo "❌ Domain $DOMAIN not resolvable via $INTERNAL_DNS after retries."
    exit 1
fi

#-------------------------------------------------------
# Check if credentials file exists

if [ ! -f "$CREDENTIALS_FILE" ]; then
    echo "❌ Credentials file not found: $CREDENTIALS_FILE"
    exit 1
fi

#-------------------------------------------------------
# Server and share configuration

SERVER="amkcambodia.com"
SERVER1="amkcrm1.amkcambodia.com"
SERVER2="ho-databackup.amkcambodia.com"
DFS_ROOT="amkdfs"

COLLAB_PREFIXPATH="Collaboration-Q"
CUD_PREFIXPATH="CUD-U"
BPR_PREFIXPATH="Branch"

MEDIA="/media/$USERNAME"
COLLAB_MOUNTPOINT="$MEDIA/$COLLAB_PREFIXPATH"
CUD_MOUNTPOINT="$MEDIA/$CUD_PREFIXPATH"
BPR_MOUNTPOINT="$MEDIA/Branch_Post_Report-P"

#-------------------------------------------------------
# Create mount directories with proper permissions

mkdir -p "$MEDIA"  "$CUD_MOUNTPOINT" "$BPR_MOUNTPOINT"

chown "$USERNAME:$GROUP_ID" "$MEDIA" "$COLLAB_MOUNTPOINT" "$CUD_MOUNTPOINT" "$BPR_MOUNTPOINT"
chmod 700 "$MEDIA" "$COLLAB_MOUNTPOINT" "$CUD_MOUNTPOINT" "$BPR_MOUNTPOINT"

#-------------------------------------------------------
# Mount shares (only if not already mounted)

# Collaboration-Q
if mountpoint -q "$COLLAB_MOUNTPOINT"; then
    echo "ℹ️ Already mounted: $COLLAB_MOUNTPOINT"
else
    if mount.cifs "//$SERVER/$DFS_ROOT/$COLLAB_PREFIXPATH" "$COLLAB_MOUNTPOINT" \
      -o credentials="$CREDENTIALS_FILE",sec=ntlmssp,uid="$USER_ID",gid="$GROUP_ID",vers=3.0; then
        echo "✅ Collaboration-Q mounted at $COLLAB_MOUNTPOINT"
    else
        echo "❌ Failed to mount $COLLAB_MOUNTPOINT"
    fi
fi

# CUD-U
if mountpoint -q "$CUD_MOUNTPOINT"; then
    echo "ℹ️ Already mounted: $CUD_MOUNTPOINT"
else
    if mount.cifs "//$SERVER1/$CUD_PREFIXPATH" "$CUD_MOUNTPOINT" \
      -o credentials="$CREDENTIALS_FILE",sec=ntlmssp,uid="$USER_ID",gid="$GROUP_ID",vers=3.0; then
        echo "✅ CUD-U mounted at $CUD_MOUNTPOINT"
    else
        echo "❌ Failed to mount $CUD_MOUNTPOINT"
    fi
fi

# Branch_Post_Report-P
if mountpoint -q "$BPR_MOUNTPOINT"; then
    echo "ℹ️ Already mounted: $BPR_MOUNTPOINT"
else
    if mount.cifs "//$SERVER2/$BPR_PREFIXPATH" "$BPR_MOUNTPOINT" \
      -o credentials="$CREDENTIALS_FILE",sec=ntlmssp,uid="$USER_ID",gid="$GROUP_ID",vers=3.0; then
        echo "✅ Branch_Post_Report-P mounted at $BPR_MOUNTPOINT"
    else
        echo "❌ Failed to mount $BPR_MOUNTPOINT"
    fi
fi

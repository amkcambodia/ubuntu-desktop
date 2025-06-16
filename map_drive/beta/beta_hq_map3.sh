#!/bin/bash

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

# Ensure mount directories exist and belong to the user
mkdir -p "$COLLAB_MOUNTPOINT" "$DEPT_MOUNTPOINT" "$HOME_MOUNTPOINT"

# Optional: fix ownership if necessary (safe without sudo only if inside user-owned dir)
# Only do this if the parent dir /media/$USERNAME is user-owned
if [ -w "$MEDIA" ]; then
  chown "$USER_ID:$GROUP_ID" "$COLLAB_MOUNTPOINT" "$DEPT_MOUNTPOINT" "$HOME_MOUNTPOINT"
  chmod 700 "$COLLAB_MOUNTPOINT" "$DEPT_MOUNTPOINT" "$HOME_MOUNTPOINT"
fi

# Mount each share if not already mounted
mountpoint -q "$COLLAB_MOUNTPOINT" || mount.cifs "//$SERVER/$DFS_ROOT/$COLLAB_PREFIXPATH" "$COLLAB_MOUNTPOINT" \
  -o credentials="$CREDENTIALS_FILE",sec=ntlmssp,uid="$USER_ID",gid="$GROUP_ID",vers=3.0,user

mountpoint -q "$DEPT_MOUNTPOINT" || mount.cifs "//$SERVER/$DFS_ROOT/$DEPT_PREFIXPATH" "$DEPT_MOUNTPOINT" \
  -o credentials="$CREDENTIALS_FILE",sec=ntlmssp,uid="$USER_ID",gid="$GROUP_ID",vers=3.0,user

mountpoint -q "$HOME_MOUNTPOINT" || mount.cifs "//$SERVER/$DFS_ROOT/$HOME_PREFIXPATH" "$HOME_MOUNTPOINT" \
  -o credentials="$CREDENTIALS_FILE",sec=ntlmssp,uid="$USER_ID",gid="$GROUP_ID",vers=3.0,user

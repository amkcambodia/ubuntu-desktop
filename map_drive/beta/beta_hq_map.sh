#!/bin/bash

# # DFS CIFS Mount Script for AMK

# # Get the real logged-in user (even if run with sudo or via systemd)
# USERNAME=$(logname)
# USER_ID=$(id -u "$USERNAME")
# GROUP_ID=$(id -g "$USERNAME")

# SERVER="amkcambodia.com"
# CREDENTIALS_FILE="/etc/smbcred/$USERNAME"

# # DFS base share
# DFS_ROOT="amkdfs"

# # DFS sub-paths
# COLLAB_PREFIXPATH="Collaboration/"
# DEPT_PREFIXPATH="Dept_Doc/CIO/ITI"
# HOME_PREFIXPATH="StaffDoc/ITD/$USERNAME"

# # Local mount points
# COLLAB_MOUNTPOINT="/media/Collaboration-Q"
# DEPT_MOUNTPOINT="/media/Department-N"
# HOME_MOUNTPOINT="/media/Home-H"

# # Create mount directories and set ownership
# mkdir -p "$COLLAB_MOUNTPOINT" "$DEPT_MOUNTPOINT" "$HOME_MOUNTPOINT"
# chown "$USERNAME:$USERNAME" "$COLLAB_MOUNTPOINT" "$DEPT_MOUNTPOINT" "$HOME_MOUNTPOINT"

# # Mount the Collaboration drive
# if mount -t cifs "//$SERVER/$DFS_ROOT" "$COLLAB_MOUNTPOINT" \
#   -o credentials="$CREDENTIALS_FILE",prefixpath="$COLLAB_PREFIXPATH",sec=ntlmssp,uid="$USER_ID",gid="$GROUP_ID",vers=3.0; then
#     echo "✅ Collaboration mounted at $COLLAB_MOUNTPOINT"
# else
#     echo "❌ Collaboration mount failed"
# fi

# # Mount the Department drive
# if mount -t cifs "//$SERVER/$DFS_ROOT" "$DEPT_MOUNTPOINT" \
#   -o credentials="$CREDENTIALS_FILE",prefixpath="$DEPT_PREFIXPATH",sec=ntlmssp,uid="$USER_ID",gid="$GROUP_ID",vers=3.0; then
#     echo "✅ Department mounted at $DEPT_MOUNTPOINT"
# else
#     echo "❌ Department mount failed"
# fi

# # Mount the Home drive
# if mount -t cifs "//$SERVER/$DFS_ROOT" "$HOME_MOUNTPOINT" \
#   -o credentials="$CREDENTIALS_FILE",prefixpath="$HOME_PREFIXPATH",sec=ntlmssp,uid="$USER_ID",gid="$GROUP_ID",vers=3.0; then
#     echo "✅ Home Drive mounted at $HOME_MOUNTPOINT"
# else
#     echo "❌ Home Drive mount failed"
# fi

#----------------------------------------------------------------------------------

# DFS CIFS Mount Script for AMK


# Get the real logged-in user (even if run with sudo or via systemd)
USERNAME=$(logname)
USER_ID=$(id -u "$USERNAME")
GROUP_ID=$(id -g "$USERNAME")

SERVER="amkcambodia.com"
CREDENTIALS_FILE="/etc/smbcred/$USERNAME"

# DFS base share
DFS_ROOT="amkdfs"

# DFS sub-paths
COLLAB_PREFIXPATH="Collaboration/AHO/ITI"
DEPT_PREFIXPATH="Dept_Doc/CIO/ITI"
HOME_PREFIXPATH="StaffDoc/ITD/$USERNAME"

# Local mount points
COLLAB_MOUNTPOINT="/media/Collaboration-Q"
DEPT_MOUNTPOINT="/media/Department-N"
HOME_MOUNTPOINT="/media/Home-H"

# Create mount directories if they do not exist
mkdir -p "$COLLAB_MOUNTPOINT" "$DEPT_MOUNTPOINT" "$HOME_MOUNTPOINT"
chown "$USER_ID:$GROUP_ID" "$COLLAB_MOUNTPOINT" "$DEPT_MOUNTPOINT" "$HOME_MOUNTPOINT"

# Mount the Collaboration drive
if mount -t cifs "//$SERVER/$DFS_ROOT" "$COLLAB_MOUNTPOINT" \
  -o credentials="$CREDENTIALS_FILE",prefixpath="$COLLAB_PREFIXPATH",sec=ntlmssp,uid=$(id -u),gid=$(id -g),vers=3.0; then
    echo "✅ Collaboration mounted at $COLLAB_MOUNTPOINT"
else
    echo "❌ Collaboration mount failed"
fi

# Mount the Department drive
if mount -t cifs "//$SERVER/$DFS_ROOT" "$DEPT_MOUNTPOINT" \
  -o credentials="$CREDENTIALS_FILE",prefixpath="$DEPT_PREFIXPATH",sec=ntlmssp,uid=$(id -u),gid=$(id -g),vers=3.0; then
    echo "✅ Department mounted at $DEPT_MOUNTPOINT"
else
    echo "❌ Department mount failed"
fi

# Mount the Home drive
if mount -t cifs "//$SERVER/$DFS_ROOT" "$HOME_MOUNTPOINT" \
  -o credentials="$CREDENTIALS_FILE",prefixpath="$HOME_PREFIXPATH",sec=ntlmssp,uid=$(id -u),gid=$(id -g),vers=3.0; then
    echo "✅ Home Drive mounted at $HOME_MOUNTPOINT"
else
    echo "❌ Home Drive mount failed"
fi

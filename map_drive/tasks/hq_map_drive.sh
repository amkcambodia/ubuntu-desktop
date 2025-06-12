#!/bin/bash

# # Configurable variables

# USERNAME="$(whoami)"
# SERVER="amkcambodia.com"
# CREDENTIALS_FILE="$HOME/.smbcred"

# # DFS share paths
# HQ_COLLAB_SHARE_PATH="amkdfs/Collaboration/AHO/ITI"
# HQ_DEPT_SHARE_PATH="amkdfs/Dept_Doc/CIO/ITI"
# HQ_HOME_BASE_PATH="amkdfs/StaffDoc/ITD"

# # User-specific share paths
# COLLAB_SHARE_PATH="$HQ_COLLAB_SHARE_PATH"
# DEPT_SHARE_PATH="$HQ_DEPT_SHARE_PATH"
# HOME_SHARE_PATH="$HQ_HOME_BASE_PATH/$USERNAME"

# # Local mount points
# COLLAB_MOUNTPOINT="/media/Collaboration-Q"
# DEPT_MOUNTPOINT="/media/Department-N"
# HOME_MOUNTPOINT="/media/Home-H"

# # Create mount directories if they do not exist
# mkdir -p "$COLLAB_MOUNTPOINT" "$DEPT_MOUNTPOINT" "$HOME_MOUNTPOINT"

# # Mount the Collaboration drive
# if mount -t cifs "//$SERVER/$COLLAB_SHARE_PATH" "$COLLAB_MOUNTPOINT" \
#   -o credentials="$CREDENTIALS_FILE",sec=ntlmssp,uid=$(id -u),gid=$(id -g),vers=3.0; then
#     echo "✅ Collaboration mounted at $COLLAB_MOUNTPOINT"
# else
#     echo "❌ Collaboration mount failed"
# fi

# # Mount the Department drive
# if mount -t cifs "//$SERVER/$DEPT_SHARE_PATH" "$DEPT_MOUNTPOINT" \
#   -o credentials="$CREDENTIALS_FILE",sec=ntlmssp,uid=$(id -u),gid=$(id -g),vers=3.0; then
#     echo "✅ Department mounted at $DEPT_MOUNTPOINT"
# else
#     echo "❌ Department mount failed"
# fi

# # Mount the Home drive
# if mount -t cifs "//$SERVER/$HOME_SHARE_PATH" "$HOME_MOUNTPOINT" \
#   -o credentials="$CREDENTIALS_FILE",sec=ntlmssp,uid=$(id -u),gid=$(id -g),vers=3.0; then
#     echo "✅ Home Drive mounted at $HOME_MOUNTPOINT"
# else
#     echo "❌ Home Drive mount failed"
# fi

#-------------------------------------------------------

# DFS CIFS Mount Script for AMK

USERNAME="$(logname)"
SERVER="amkcambodia.com"
CREDENTIALS_FILE="$HOME/.smbcred"

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

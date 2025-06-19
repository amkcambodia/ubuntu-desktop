#!/bin/bash
# /usr/local/bin/amk/umount-dfs-wrapper.sh

USER_NAME="$PAM_USER"
if [ -z "$USER_NAME" ]; then
  echo "No PAM_USER, exiting"
  exit 1
fi

sudo -u "$USER_NAME" sudo /usr/local/bin/amk/umount-dfs.sh

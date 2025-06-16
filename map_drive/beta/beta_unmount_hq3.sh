#!/bin/bash

USERNAME=$(logname)
MEDIA="/media/$USERNAME"

# Use lazy unmount so it's not stuck if still accessed
for share in Collaboration-Q Department-N Home-H; do
    mountpoint="$MEDIA/$share"
    if mountpoint -q "$mountpoint"; then
        umount -l "$mountpoint"
        echo "$(date) 🔌 Unmounted $mountpoint" >> /tmp/unmount-user-drives.log
    fi
done

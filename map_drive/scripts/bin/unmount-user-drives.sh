#!/bin/bash

# create in /usr/local/bin/amk/unmount-user-drives.sh
#USERNAME=$(logname)
#MEDIA="/media/$USERNAME"
#umount -l "$MEDIA/Collaboration-Q"
#umount -l "$MEDIA/Department-N"
#umount -l "$MEDIA/Home-H"

# --------------------------------------------------------------------------------
# Script to unmount user DFS drives safely on logout
USERNAME=$(logname)
MEDIA="/media/$USERNAME"

COLLAB="$MEDIA/Collaboration-Q"
DEPT="$MEDIA/Department-N"
HOME="$MEDIA/Home-H"

echo "🔌 Unmounting DFS shares for user: $USERNAME"

for MOUNTPOINT in "$COLLAB" "$DEPT" "$HOME"; do
    if mountpoint -q "$MOUNTPOINT"; then
        echo "📍 Unmounting $MOUNTPOINT ..."
        umount -l "$MOUNTPOINT" && echo "✅ Unmounted: $MOUNTPOINT"
    else
        echo "ℹ️ Not mounted: $MOUNTPOINT (skipped)"
    fi
done

echo "🧹 Cleaning up mount folders..."
#rm -rf "$COLLAB" "$DEPT" "$HOME"

for DIR in "$COLLAB" "$DEPT" "$HOME"; do
    if ! mountpoint -q "$DIR"; then
        echo "🧹 Removing $DIR ..."
        rm -rf "$DIR"
    else
        echo "⚠️ Skipped deleting $DIR — still mounted!"
    fi
done


exit 0

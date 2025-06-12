#!/bin/bash

COLLAB_MOUNTPOINT="/media/Collaboration-Q"
DEPT_MOUNTPOINT="/media/Department-N"
HOME_MOUNTPOINT="/media/Home-H"

echo "Unmounting AMK DFS Shares..."
sudo umount /media/Collaboration-Q 2>/dev/null
sudo umount /media/Department-N 2>/dev/null
sudo umount /media/Home-H 2>/dev/null

rm -rf "$COLLAB_MOUNTPOINT" "$DEPT_MOUNTPOINT" "$HOME_MOUNTPOINT"
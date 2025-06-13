#!/bin/bash

# create in /usr/local/bin/amk/unmount-user-drives.sh
USERNAME=$(logname)
MEDIA="/media/$USERNAME"
umount -l "$MEDIA/Collaboration-Q"
umount -l "$MEDIA/Department-N"
umount -l "$MEDIA/Home-H"
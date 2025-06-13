#!/bin/bash

USERNAME=$(logname)
MEDIA="/media/$USERNAME"
umount -l "$MEDIA/Collaboration-Q"
umount -l "$MEDIA/Department-N"
umount -l "$MEDIA/Home-H"